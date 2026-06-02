// File: scrap_esp32.ino
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "HX711.h"

// -------------------------------------------------
// 1️⃣ Wi‑Fi credentials
// -------------------------------------------------
const char* ssid     = "Converge_2.4GHz_p4Rg";
const char* password = "j5EkZQYF";

// -------------------------------------------------
// 2️⃣ Server endpoint (must match the Flask host)
// -------------------------------------------------
const char* serverUrl = "http://192.168.100.3:3000/scrap-data";

// -------------------------------------------------
// 3️⃣ HX711 scale setup (adjust pins if needed)
// -------------------------------------------------
const int LOADCELL_DOUT_PIN = 21; // Yellow Wire
const int LOADCELL_SCK_PIN  = 22; // Green Wire
HX711 scale;
float calibration_factor = 214.1; // Adjust after calibration

// -------------------------------------------------
// 4️⃣ Scrap data structure
// -------------------------------------------------
struct ScrapItem {
  String id;          // unique id, e.g. UUID
  String name;        // food name
  double weight;      // in grams (from HX711)
  String category;    // e.g. "vegetable"
  String timestamp;   // ISO‑8601 string
};

// -------------------------------------------------
// 5️⃣ Scale initialization
// -------------------------------------------------
void setupScale() {
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale();
  scale.tare();
  scale.set_scale(calibration_factor);
  Serial.println("Scale calibrated. Ready to read weight.");
}

// -------------------------------------------------
// 6️⃣ Create scrap item from scale reading
// -------------------------------------------------
ScrapItem createScrapFromScale() {
  ScrapItem item;
  item.id        = "item-" + String(millis());
  item.name      = "Food"; // you can replace with actual label later
  item.weight    = scale.get_units(10);
  item.category  = "unknown";
  // Use current time for timestamp (ISO‑8601)
  time_t now = time(nullptr);
  char buf[32];
  strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", gmtime(&now));
  item.timestamp = String(buf);
  return item;
}

// -------------------------------------------------
// 7️⃣ Send JSON to Flask server
// -------------------------------------------------
bool sendScrap(const ScrapItem& item) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Wi‑Fi not connected");
    return false;
  }

  HTTPClient http;
  http.begin(serverUrl);
  http.addHeader("Content-Type", "application/json");

  // Build JSON payload
  DynamicJsonDocument doc(256);
  doc["id"]        = item.id;
  doc["name"]      = item.name;
  doc["weight"]    = item.weight;
  doc["category"]  = item.category;
  doc["timestamp"] = item.timestamp;

  String payload;
  serializeJson(doc, payload);

  int httpResponseCode = http.POST(payload);
  if (httpResponseCode == 200) {
    Serial.println("✅ Scrap data sent successfully");
    Serial.printf("Weight: %.1f g\n", item.weight);
    http.end();
    return true;
  } else {
    Serial.printf("❌ Failed, code %d\n", httpResponseCode);
    http.end();
    return false;
  }
}

// -------------------------------------------------
// 8️⃣ Setup & loop
// -------------------------------------------------
void setup() {
  Serial.begin(115200);
  delay(1000);

  // Initialize scale
  setupScale();

  // Connect to Wi‑Fi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to Wi‑Fi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ Wi‑Fi connected, IP: " + WiFi.localIP().toString());
}

void loop() {
  // Read weight and send as scrap data every 30 seconds
  ScrapItem item = createScrapFromScale();
  sendScrap(item);
  delay(30000);
}