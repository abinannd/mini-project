"""
Lane-Aware Emergency Vehicle Alert System - Backend

Responsibilities:
  1. Accept a start/destination from the operator and fetch a route
     polyline from OSRM.
  2. Accept a persistent WebSocket connection from the ambulance ESP32
     streaming live location.
  3. Accept persistent WebSocket connections from participant phones
     streaming their live location.
  4. On each ambulance update, evaluate every connected participant
     against: ahead of ambulance, same direction of travel, within the
     route corridor, and within the configurable warning distance.
     Send a targeted alert only to matching vehicles.

Run:
  uvicorn main:app --host 0.0.0.0 --port 8000 --reload
"""

import math
import time
from typing import Dict, List, Optional, Tuple

import httpx
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ValidationError

app = FastAPI(title="Lane-Aware EVA System")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # restrict to your frontend's origin in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------- Configuration ----------------
WARNING_DISTANCE_M = 500      # alert vehicles within this distance ahead
CORRIDOR_WIDTH_M = 30         # max perpendicular distance from route line
BEARING_TOLERANCE_DEG = 45    # how aligned vehicle heading must be with ambulance heading
OSRM_BASE_URL = "https://router.project-osrm.org/route/v1/driving"


# ---------------- Data models ----------------
class RouteRequest(BaseModel):
    start_lat: float
    start_lng: float
    end_lat: float
    end_lng: float


class VehiclePing(BaseModel):
    lat: float
    lng: float


class AmbulancePing(BaseModel):
    lat: float
    lng: float
    speed_kmh: float = 0.0
    heading_deg: float = 0.0
    emergency: bool = False


class AmbulanceState:
    lat: Optional[float] = None
    lng: Optional[float] = None
    speed_kmh: float = 0.0
    heading_deg: float = 0.0
    emergency: bool = False
    last_update: float = 0.0


ambulance_state = AmbulanceState()
route_points: List[Tuple[float, float]] = []  # [(lat, lng), ...]

# vehicle_id -> {"lat":.., "lng":.., "heading":.., "ws": WebSocket}
connected_vehicles: Dict[str, dict] = {}
ambulance_ws: Optional[WebSocket] = None


# ---------------- Geo helpers ----------------
def haversine_m(lat1, lng1, lat2, lng2) -> float:
    R = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return 2 * R * math.asin(math.sqrt(a))


def bearing_deg(lat1, lng1, lat2, lng2) -> float:
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dlmb = math.radians(lng2 - lng1)
    y = math.sin(dlmb) * math.cos(p2)
    x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dlmb)
    return (math.degrees(math.atan2(y, x)) + 360) % 360


def angle_diff(a, b) -> float:
    d = abs(a - b) % 360
    return min(d, 360 - d)


def min_distance_to_route_m(lat, lng, route: List[Tuple[float, float]]) -> float:
    """Approximate perpendicular distance from a point to the nearest route segment."""
    if not route:
        return float("inf")
    if len(route) == 1:
        return haversine_m(lat, lng, route[0][0], route[0][1])

    best = float("inf")
    for i in range(len(route) - 1):
        best = min(best, _point_to_segment_m(lat, lng, route[i], route[i + 1]))
    return best


def _point_to_segment_m(lat, lng, p1, p2) -> float:
    # Flat-earth local approximation, fine for short corridor checks.
    lat0 = math.radians((p1[0] + p2[0]) / 2)
    mx = 111320.0 * math.cos(lat0)
    my = 111320.0

    x, y = lng * mx, lat * my
    x1, y1 = p1[1] * mx, p1[0] * my
    x2, y2 = p2[1] * mx, p2[0] * my

    dx, dy = x2 - x1, y2 - y1
    if dx == 0 and dy == 0:
        return math.hypot(x - x1, y - y1)

    t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)
    t = max(0, min(1, t))
    px, py = x1 + t * dx, y1 + t * dy
    return math.hypot(x - px, y - py)


# ---------------- Routing (OSRM) ----------------
async def fetch_route(start_lat, start_lng, end_lat, end_lng) -> List[Tuple[float, float]]:
    url = f"{OSRM_BASE_URL}/{start_lng},{start_lat};{end_lng},{end_lat}?overview=full&geometries=geojson"
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(url)
        resp.raise_for_status()
        data = resp.json()
    coords = data["routes"][0]["geometry"]["coordinates"]  # [ [lng,lat], ... ]
    return [(lat, lng) for lng, lat in coords]


# ---------------- Matching logic ----------------
async def evaluate_and_alert():
    if ambulance_state.lat is None or not ambulance_state.emergency:
        return

    for vid, v in list(connected_vehicles.items()):
        vlat, vlng = v["lat"], v["lng"]
        if vlat is None or vlng is None:
            continue

        dist = haversine_m(ambulance_state.lat, ambulance_state.lng, vlat, vlng)
        if dist > WARNING_DISTANCE_M:
            continue

        # Is the vehicle roughly ahead of the ambulance, in its direction of travel?
        bearing_to_vehicle = bearing_deg(ambulance_state.lat, ambulance_state.lng, vlat, vlng)
        if angle_diff(bearing_to_vehicle, ambulance_state.heading_deg) > BEARING_TOLERANCE_DEG:
            continue

        # Is the vehicle close to the planned route corridor (lane/path proxy)?
        if route_points and min_distance_to_route_m(vlat, vlng, route_points) > CORRIDOR_WIDTH_M:
            continue

        try:
            await v["ws"].send_json({
                "type": "alert",
                "message": "Emergency vehicle approaching. Please safely clear the path when safe and legal.",
                "distance_m": round(dist),
            })
        except Exception:
            connected_vehicles.pop(vid, None)


# ---------------- Routes ----------------
@app.post("/route")
async def set_route(req: RouteRequest):
    global route_points
    route_points = await fetch_route(req.start_lat, req.start_lng, req.end_lat, req.end_lng)
    return {"points": len(route_points)}


@app.get("/status")
async def status():
    return {
        "ambulance": vars(ambulance_state) if ambulance_state.lat else None,
        "route_points": len(route_points),
        "connected_vehicles": list(connected_vehicles.keys()),
    }


@app.websocket("/ws/ambulance")
async def ws_ambulance(websocket: WebSocket):
    global ambulance_ws
    await websocket.accept()
    ambulance_ws = websocket
    try:
        while True:
            raw = await websocket.receive_json()
            try:
                data = AmbulancePing(**raw)
            except ValidationError as exc:
                print(f"[ws_ambulance] invalid payload, skipping: {exc}")
                continue
            ambulance_state.lat = data.lat
            ambulance_state.lng = data.lng
            ambulance_state.speed_kmh = data.speed_kmh
            ambulance_state.heading_deg = data.heading_deg
            ambulance_state.emergency = data.emergency
            ambulance_state.last_update = time.time()
            await evaluate_and_alert()
    except WebSocketDisconnect:
        pass
    finally:
        global ambulance_ws
        ambulance_ws = None


@app.websocket("/ws/vehicle/{vehicle_id}")
async def ws_vehicle(websocket: WebSocket, vehicle_id: str):
    await websocket.accept()
    connected_vehicles[vehicle_id] = {"lat": None, "lng": None, "ws": websocket}
    try:
        while True:
            raw = await websocket.receive_json()
            try:
                data = VehiclePing(**raw)
            except ValidationError as exc:
                print(f"[ws_vehicle:{vehicle_id}] invalid payload, skipping: {exc}")
                continue
            connected_vehicles[vehicle_id]["lat"] = data.lat
            connected_vehicles[vehicle_id]["lng"] = data.lng
    except WebSocketDisconnect:
        pass
    finally:
        connected_vehicles.pop(vehicle_id, None)
  
