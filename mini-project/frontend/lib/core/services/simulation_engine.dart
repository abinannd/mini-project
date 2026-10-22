import 'dart:async';
import 'dart:math';
import '../models/vehicle_node.dart';
import '../models/emergency_alert.dart';

class SimulationEngine {
  // Configurable parameters
  static const double alertZoneMeters = 600.0;
  static const double baseLat = 12.9716; // Reference coordinates (e.g. Bangalore / standard city road)
  static const double baseLng = 77.5946;

  VehicleNode _ambulance = VehicleNode(
    id: 'AMB01',
    label: 'Ambulance 01',
    latitude: baseLat,
    longitude: baseLng,
    speedKmh: 75.0,
    headingDeg: 0.0, // North
    lane: 2, // Center lane
    isEmergencyVehicle: true,
    lastUpdated: DateTime.now(),
  );

  final Map<String, VehicleNode> _vehicles = {
    'V001': VehicleNode(
      id: 'V001',
      label: 'Vehicle 001 (Sedan)',
      latitude: baseLat + 0.0020, // ~220m ahead
      longitude: baseLng - 0.00004, // Lane 1 offset
      speedKmh: 45.0,
      headingDeg: 0.0,
      lane: 1, // Left lane
      lastUpdated: DateTime.now(),
    ),
    'V002': VehicleNode(
      id: 'V002',
      label: 'Vehicle 002 (SUV)',
      latitude: baseLat + 0.0032, // ~350m ahead
      longitude: baseLng, // Lane 2 (Same as Ambulance)
      speedKmh: 40.0,
      headingDeg: 0.0,
      lane: 2, // Center lane - TARGETED
      lastUpdated: DateTime.now(),
    ),
    'V003': VehicleNode(
      id: 'V003',
      label: 'Vehicle 003 (Hatchback)',
      latitude: baseLat + 0.0025, // ~280m ahead
      longitude: baseLng + 0.00004, // Lane 3 offset
      speedKmh: 50.0,
      headingDeg: 0.0,
      lane: 3, // Right lane
      lastUpdated: DateTime.now(),
    ),
  };

  bool _isEmergencyMode = true;
  Timer? _ticker;
  final _stateChangeController = StreamController<void>.broadcast();

  Stream<void> get onStateChange => _stateChangeController.stream;

  VehicleNode get ambulance => _ambulance;
  Map<String, VehicleNode> get vehicles => Map.unmodifiable(_vehicles);
  bool get isEmergencyMode => _isEmergencyMode;

  // Targeting Pipeline (Section 7)
  EmergencyAlert? evaluateTargeting(String currentVehicleId) {
    if (!_isEmergencyMode) return null;

    final vehicle = _vehicles[currentVehicleId];
    if (vehicle == null) return null;

    // Step 1: Lane check - vehicle must be in the ambulance's lane
    if (vehicle.lane != _ambulance.lane) return null;

    // Step 2: Ahead check - vehicle must be ahead along the travel path
    if (!isVehicleAhead(_ambulance, vehicle)) return null;

    // Step 3: Direction check - roughly same heading (+/- 45 deg)
    final headingDiff = (vehicle.headingDeg - _ambulance.headingDeg).abs();
    if (headingDiff > 45 && headingDiff < 315) return null;

    // Step 4: Distance threshold within the alert corridor zone (600m)
    final distance = calculateDistanceMeters(_ambulance, vehicle);
    if (distance > alertZoneMeters) return null;

    final relativeSpeedMs = max((_ambulance.speedKmh - vehicle.speedKmh) * 1000 / 3600, 5.0);
    final eta = (distance / relativeSpeedMs).round();

    return EmergencyAlert(
      toId: vehicle.id,
      ambulanceId: _ambulance.id,
      ambulanceLat: _ambulance.latitude,
      ambulanceLon: _ambulance.longitude,
      distanceMeters: distance,
      etaSeconds: max(eta, 1),
      emergencyState: true,
      ambulanceLane: _ambulance.lane,
      messageCode: 'AMBULANCE_APPROACHING_CLEAR_LANE_SAFELY',
      humanMessage:
          'Emergency vehicle approaching in your lane. Please safely clear the path when safe and legal.',
      timestamp: DateTime.now(),
    );
  }

  /// Evaluates which connected vehicle ahead is in the ambulance's path
  VehicleNode? getTargetVehicle() {
    if (!_isEmergencyMode) return null;

    VehicleNode? closestTarget;
    double minAheadDistance = double.infinity;

    for (final vehicle in _vehicles.values) {
      // Step 4 & 5: Direction check (must head roughly the same direction +/- 45 deg)
      final headingDiff = (vehicle.headingDeg - _ambulance.headingDeg).abs();
      if (headingDiff > 45 && headingDiff < 315) continue;

      // Step 6: Ahead check (is vehicle ahead along the ambulance heading?)
      final distMeters = calculateDistanceMeters(_ambulance, vehicle);
      final isAhead = isVehicleAhead(_ambulance, vehicle);
      if (!isAhead) continue;

      // Step 7: Lane relevance check (matching ambulance lane)
      if (vehicle.lane != _ambulance.lane) continue;

      // Step 9: Alert zone threshold
      if (distMeters <= alertZoneMeters && distMeters < minAheadDistance) {
        minAheadDistance = distMeters;
        closestTarget = vehicle;
      }
    }

    return closestTarget;
  }

  // Mutators for Interactive Viva Demonstration (Section 11)
  void setEmergencyMode(bool active) {
    _isEmergencyMode = active;
    _notify();
  }

  void setVehicleLane(String vehicleId, int newLane) {
    if (_vehicles.containsKey(vehicleId)) {
      final current = _vehicles[vehicleId]!;
      _vehicles[vehicleId] = current.copyWith(
        lane: newLane,
        longitude: baseLng + ((newLane - 2) * 0.00004),
        lastUpdated: DateTime.now(),
      );
      _notify();
    }
  }

  void setAmbulanceLane(int newLane) {
    _ambulance = _ambulance.copyWith(
      lane: newLane,
      longitude: baseLng + ((newLane - 2) * 0.00004),
      lastUpdated: DateTime.now(),
    );
    _notify();
  }

  void updateVehiclePosition(String vehicleId, double distanceOffsetMeters) {
    if (_vehicles.containsKey(vehicleId)) {
      final current = _vehicles[vehicleId]!;
      // 1 degree lat ~ 111,320 meters
      final latOffset = distanceOffsetMeters / 111320.0;
      _vehicles[vehicleId] = current.copyWith(
        latitude: baseLat + latOffset,
        lastUpdated: DateTime.now(),
      );
      _notify();
    }
  }

  void resetToDefaultScenario() {
    _ambulance = _ambulance.copyWith(
      latitude: baseLat,
      longitude: baseLng,
      lane: 2,
      speedKmh: 75.0,
      headingDeg: 0.0,
    );
    _vehicles['V001'] = _vehicles['V001']!.copyWith(
      latitude: baseLat + 0.0020,
      longitude: baseLng - 0.00004,
      lane: 1,
    );
    _vehicles['V002'] = _vehicles['V002']!.copyWith(
      latitude: baseLat + 0.0032,
      longitude: baseLng,
      lane: 2,
    );
    _vehicles['V003'] = _vehicles['V003']!.copyWith(
      latitude: baseLat + 0.0025,
      longitude: baseLng + 0.00004,
      lane: 3,
    );
    _isEmergencyMode = true;
    _notify();
  }

  // Animated Drive Simulation (vehicles move in real time)
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  void togglePlayback() {
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
        _tick(0.5);
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
    _notify();
  }

  void _tick(double dtSeconds) {
    // Move ambulance forward
    final ambDistM = (_ambulance.speedKmh * 1000 / 3600) * dtSeconds;
    final ambLatDelta = ambDistM / 111320.0;
    _ambulance = _ambulance.copyWith(
      latitude: _ambulance.latitude + ambLatDelta,
      lastUpdated: DateTime.now(),
    );

    // Move vehicles forward
    for (final entry in _vehicles.entries) {
      final v = entry.value;
      final distM = (v.speedKmh * 1000 / 3600) * dtSeconds;
      final latDelta = distM / 111320.0;
      _vehicles[entry.key] = v.copyWith(
        latitude: v.latitude + latDelta,
        lastUpdated: DateTime.now(),
      );
    }

    // Loop back if traveled too far
    if (_ambulance.latitude - baseLat > 0.015) {
      resetToDefaultScenario();
    }

    _notify();
  }

  void _notify() {
    _stateChangeController.add(null);
  }

  // Geospatial Math Helpers
  static double calculateDistanceMeters(VehicleNode a, VehicleNode b) {
    const earthRadius = 6371000.0; // meters
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final sinDlat2 = sin(dLat / 2);
    final sinDlon2 = sin(dLon / 2);

    final aVal = sinDlat2 * sinDlat2 + cos(lat1) * cos(lat2) * sinDlon2 * sinDlon2;
    final cVal = 2 * atan2(sqrt(aVal), sqrt(1 - aVal));

    return earthRadius * cVal;
  }

  static bool isVehicleAhead(VehicleNode ambulance, VehicleNode vehicle) {
    // Assuming travel direction along latitude (North = heading 0)
    // Positive latitude difference means vehicle is ahead
    return vehicle.latitude > ambulance.latitude;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);

  void dispose() {
    _ticker?.cancel();
    _stateChangeController.close();
  }
}
