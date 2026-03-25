#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// ✅ FIX ①: PROGMEM + F() — literales viven en flash, no en SRAM
const char WIFI_NAME[]     PROGMEM = "Wokwi-GUEST";
const char WIFI_PASSWORD[] PROGMEM = "";
const char NTFY_URL[]      PROGMEM = "https://ntfy.sh/hct99Q3DhOcNvlzN";
const char NTFY_PAYLOAD[]  PROGMEM = "¡Hola desde ESP32-S3!";

// FIX ①②: struct mínimo + salida por referencia (elimina RVO ambiguo)
struct NtfyResponse {
  String message;   // único campo que se usa realmente
  bool   ok = false;
};

static HTTPClient http;

void parseResponse(const JsonDocument& doc, NtfyResponse& out) {
  out.message = doc["message"].as<String>();
  out.ok      = true;
}

bool isConnectedWifi() {
  return WiFi.status() == WL_CONNECTED;
}

void connectWifi() {
  WiFi.begin(WIFI_NAME, WIFI_PASSWORD);
  Serial.println(F("Conectando a WiFi..."));
  while (!isConnectedWifi()) {
    delay(500);
    Serial.print(F("."));
  }
  Serial.println();
  Serial.println(F("Conectado a WiFi"));
}

void requestHttp(const char* url, const char* payload, NtfyResponse& out) {
  http.begin(url);
  http.setReuse(true);
  http.setConnectTimeout(3000);
  http.setTimeout(5000);

  int code = http.POST(String(payload));

  if (code >= 200 && code < 300) {
    StaticJsonDocument<256> doc;
    WiFiClient* stream = http.getStreamPtr();
    if (!deserializeJson(doc, *stream)) {
      parseResponse(doc, out);
    }
  } else {
    Serial.print(F("Error HTTP: "));
    Serial.println(code);
    out.message = http.errorToString(code);
  }

  http.end();
}

void setup() {
  Serial.begin(115200);
  Serial.println(F("Hello, ESP32-S3..."));
  connectWifi();
}

static unsigned long lastSend = 0;
const  unsigned long INTERVAL  = 10000UL;

void sendMessage() {
  Serial.println(F("Realizando solicitud HTTP..."));
  NtfyResponse response;
  requestHttp(NTFY_URL, NTFY_PAYLOAD, response);
  Serial.print(F("Respuesta: "));
  Serial.println(response.message);
}

void loop() {
  if (!isConnectedWifi()) return;
  unsigned long now = millis();
  if (now - lastSend >= INTERVAL) {
    lastSend = now;
    sendMessage();
  }
}
