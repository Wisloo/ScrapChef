#include <WiFi.h>
#include <PubSubClient.h>
#include <HX711.h>

// WiFi Configuration
const char* ssid = "Skybroadband0143";
const char* password = "123456789";

// MQTT Configuration
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;
const char* mqtt_client_id = "scrapchef_esp32";
const char* mqtt_topic = "scrapchef/weight";

// HX711 Configuration
const int DOUT_PIN = 21;  // Data pin (DT)
const int SCK_PIN = 22;   // Clock pin (SCK)
const float calibration_factor = 212.0;  // Calibrated for your load cell
const int num_readings = 10;  // Number of readings to average

HX711 scale;
WiFiClient espClient;
PubSubClient client(espClient);

unsigned long lastPublishTime = 0;
const unsigned long publishInterval = 500;  // Publish every 500ms
float lastWeight = 0.0;
const float weightChangeThreshold = 1.0;  // Only publish if weight changes by 1.0g

void setup() {
  Serial.begin(115200);
  
  // Initialize HX711
  scale.begin(DOUT_PIN, SCK_PIN);
  Serial.print("Raw reading before calibration: ");
  Serial.println(scale.read());
  scale.set_scale(calibration_factor);
  scale.tare();  // Reset scale to 0
  delay(2000);  // Wait for readings to stabilize after tare
  Serial.print("Raw reading after tare: ");
  Serial.println(scale.read());
  Serial.print("Calibrated reading (no weight): ");
  Serial.println(scale.get_units(10));
  
  Serial.println("HX711 initialized");
  
  // Connect to WiFi
  setupWiFi();
  
  // Setup MQTT
  client.setServer(mqtt_server, mqtt_port);
}

void setupWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println();
  Serial.println("WiFi connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void reconnectMQTT() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    
    if (client.connect(mqtt_client_id)) {
      Serial.println("connected");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retrying in 5 seconds");
      delay(5000);
    }
  }
}

void loop() {
  // Reconnect MQTT if disconnected
  if (!client.connected()) {
    reconnectMQTT();
  }
  client.loop();
  
  // Read weight from HX711
  if (scale.is_ready()) {
    float weight = scale.get_units(num_readings);  // Average multiple readings
    
    // Only publish if weight changed significantly
    if (abs(weight - lastWeight) >= weightChangeThreshold) {
      unsigned long currentTime = millis();
      
      // Only publish at specified interval
      if (currentTime - lastPublishTime >= publishInterval) {
        String weightStr = String(weight, 1);  // 1 decimal place
        
        if (client.publish(mqtt_topic, weightStr.c_str())) {
          Serial.print("Published weight: ");
          Serial.println(weightStr);
          lastWeight = weight;
          lastPublishTime = currentTime;
        } else {
          Serial.println("Failed to publish weight");
        }
      }
    }
  }
  
  delay(100);
}
