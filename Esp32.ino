/*
  Lane-Aware Emergency Vehicle Alert System
  Ambulance Unit Firmware (ESP32 + NEO-6M GPS)

  Reads GPS fixes over Serial2 (pins 16/17) and streams
  {lat, lng, speed_kmh, heading, emergency} as JSON to the
  backend over a persistent WebSocket connection.

  Libraries required (Library Manager):
    - TinyGPSPlus
    - WebSockets (Markus Sattler / Links2004)
    - ArduinoJson
*/

#include <WiFi.h>
#include <WebSocketsClient.h>
#include <ArduinoJson.h>
#include <TinyGPSPlus.h>
#include <HardwareSerial.h>

// ---------- CONFIG: edit these ----------
const char* WIFI_SSID   = "YOUR_HOTSPOT_SSID";
const char* WIFI_PASS   = "YOUR_HOTSPOT_PASSWORD";
const char* WS_HOST     = "192.168.1.100";  // backend LAN IP
const uint16_t WS_PORT  = 8000;
const char* WS_PATH     = "/ws/ambulance";
const unsigned long SEND_INTERVAL_MS = 2000;
// -----------------------------------------

HardwareSerial GPSSerial(2);   // UART2: RX2=16, TX2=17
TinyGPSPlus gps;
WebSocketsClient webSocket;

bool emergencyMode = true;     // set false if you want a manual toggle later
unsigned long lastSend = 0;

void webSocketEvent(WStype_t type, uint8_t* payload, size_t length) {
  switch (type) {
    case WStype_DISCONNECTED:
      Serial.println("[WS] Disconnected");
      break;
    case WStype_CONNECTED:
      Serial.println("[WS] Connected to backend");
      break;
    case WStype_TEXT:
      // Backend may send config/ack messages; log for debugging
      Serial.printf("[WS] Message: %s\n", payload);
      break;
    default:
      break;
  }
}

void connectWiFi() {
  Serial.printf("Connecting to WiFi '%s'...\n", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(400);
    Serial.print(".");
  }
  Serial.println();
  Serial.printf("WiFi connected. IP: %s\n", WiFi.localIP().toString().c_str());
}

void setup() {
  Serial.begin(115200);
  GPSSerial.begin(9600, SERIAL_8N1, 16, 17); // RX2=16 <- GPS TX, TX2=17 -> GPS RX

  connectWiFi();

  webSocket.begin(WS_HOST, WS_PORT, WS_PATH);
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(3000);
}

void sendLocation() {
  if (!gps.location.isValid()) {
    Serial.println("Waiting for GPS fix...");
    return;
  }

  StaticJsonDocument<256> doc;
  doc["lat"] = gps.location.lat();
  doc["lng"] = gps.location.lng();
  doc["speed_kmh"] = gps.speed.isValid() ? gps.speed.kmph() : 0.0;
  doc["heading_deg"] = gps.course.isValid() ? gps.course.deg() : 0.0;
  doc["emergency"] = emergencyMode;
  doc["ts"] = millis();

  String out;
  serializeJson(doc, out);
  webSocket.sendTXT(out);

  Serial.println(out);
}

void loop() {
  webSocket.loop();

  // Feed GPS parser
  while (GPSSerial.available() > 0) {
    gps.encode(GPSSerial.read());
  }

  unsigned long now = millis();
  if (now - lastSend >= SEND_INTERVAL_MS) {
    lastSend = now;
    sendLocation();
  }
}
