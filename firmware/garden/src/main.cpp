#define SENSOR_POWER 25
#define SENSOR_PIN   32
#define RELAY_PIN    27

#include <WiFi.h>
#include <HTTPClient.h>
#include <time.h>
#include <secrets.h>

// --- Calibration ---
const int DRY_VALUE          = 4095;
const int WET_VALUE          = 980;
const int MOISTURE_THRESHOLD = 50;

void connectWifi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected, IP: " + WiFi.localIP().toString());
}

bool syncTime() {
  configTzTime("CET-1CEST,M3.5.0/2,M10.5.0/3", "pool.ntp.org", "time.google.com");
  struct tm timeinfo;
  for (int i = 0; i < 20; i++) {
    if (getLocalTime(&timeinfo, 500)) {
      Serial.println("Time synced");
      return true;
    }
    delay(250);
  }
  Serial.println("Time sync failed");
  return false;
}

String getDateString() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo, 500)) return "unknown";
  char buf[11];
  strftime(buf, sizeof(buf), "%d-%m-%Y", &timeinfo);
  return String(buf);
}

String getTimeString() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo, 500)) return "unknown";
  char buf[6];
  strftime(buf, sizeof(buf), "%H:%M", &timeinfo);
  return String(buf);
}

String buildEvent(const String& eventName, const String& extraJson = "") {
  String p = "{\"source\":\"esp32\",\"date\":\"" + getDateString() +
             "\",\"time\":\"" + getTimeString() +
             "\",\"event\":\"" + eventName + "\"";
  if (extraJson.length() > 0) p += "," + extraJson;
  p += "}";
  return p;
}

void publishEvent(const String& payload) {
  HTTPClient http;
  http.begin(API_ENDPOINT);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("x-api-key", API_KEY);

  int statusCode = http.POST(payload);
  Serial.print("POST " + payload + " -> HTTP ");
  Serial.println(statusCode);

  http.end();
}

void setup() {
  Serial.begin(115200);
  delay(2000);  // allow Serial Monitor to reconnect after deep sleep wake

  pinMode(SENSOR_POWER, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH);

  connectWifi();
  syncTime();

  publishEvent(buildEvent("device_boot"));

  // --- Measure ---
  digitalWrite(SENSOR_POWER, HIGH);
  delay(2000);

  long sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += analogRead(SENSOR_PIN);
    delay(30);
  }
  int rawValue = sum / 10;

  int moisturePercent = map(rawValue, DRY_VALUE, WET_VALUE, 0, 100);
  moisturePercent = constrain(moisturePercent, 0, 100);

  Serial.printf("Raw: %d  Moisture: %d%%\n", rawValue, moisturePercent);

  publishEvent(buildEvent(
    "measurement_taken",
    "\"raw_value\":" + String(rawValue) + ",\"moisture_percent\":" + String(moisturePercent)
  ));

  digitalWrite(SENSOR_POWER, LOW);

  // --- Water or skip ---
  if (moisturePercent <= MOISTURE_THRESHOLD) {
    publishEvent(buildEvent(
      "watering_started",
      "\"moisture_percent\":" + String(moisturePercent) + ",\"threshold\":" + String(MOISTURE_THRESHOLD)
    ));

    digitalWrite(RELAY_PIN, LOW);
    delay(7000);
    digitalWrite(RELAY_PIN, HIGH);

    publishEvent(buildEvent("watering_finished", "\"duration_seconds\":5"));
  } else {
    publishEvent(buildEvent(
      "watering_skipped",
      "\"reason\":\"soil_ok\",\"moisture_percent\":" + String(moisturePercent)
    ));
  }

  // --- Sleep ---
  publishEvent(buildEvent("device_sleeping", "\"sleep_seconds\":3600"));

  WiFi.disconnect(true);
  esp_sleep_enable_timer_wakeup(3600ULL * 1000000ULL);
  esp_deep_sleep_start();
}

void loop() {}
