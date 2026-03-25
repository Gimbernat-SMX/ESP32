#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

const String WIFI_NAME = "Wokwi-GUEST";
const String WIFI_PASSWORD = "";

class NtfyResponse {
public:
  String id;
  String time;
  int expires;
  String event;
  String topic;
  String message;

  static NtfyResponse fromJson(const String& response) {
    NtfyResponse result;
    DynamicJsonDocument doc(512);

    if (deserializeJson(doc, response)) {
      return result;
    }

    result.loadFromDoc(doc);

    return result;
  }

  static NtfyResponse addMessage(String message) {
    NtfyResponse result;

    result.message = message;

    return result;
  }

private:
  void loadFromDoc(const JsonDocument& doc) {
    id = doc["id"].as<String>();
    time = doc["time"].as<String>();
    expires = doc["expires"].as<int>();
    event = doc["event"].as<String>();
    topic = doc["topic"].as<String>();
    message = doc["message"].as<String>();
  }
};

bool isConnectedWifi() {
  return WiFi.status() == WL_CONNECTED;
}

void connectWifi() {
  WiFi.begin(WIFI_NAME, WIFI_PASSWORD);

  Serial.println("Conectando a WiFi...");

  while (isConnectedWifi() == false) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("Conectado a WiFi");
}


void setup() {
  Serial.begin(115200);
  Serial.println("Hello, ESP32-S3...");

  connectWifi();
}

NtfyResponse requestHttp(String method, String url, String payload = "") {
  HTTPClient http;
  http.begin(url);

  int httpResponseCode = 0;
  if (method == "GET") {
    httpResponseCode = http.GET();
  } else if (method == "POST") {
    httpResponseCode = http.POST(payload);
  } else {
    Serial.println("Método HTTP no soportado");
    return NtfyResponse::addMessage("Unsupported HTTP method");
  }

  NtfyResponse result = NtfyResponse();

  if (httpResponseCode >= 200 && httpResponseCode < 300) {
    String response = http.getString();

    result = NtfyResponse::fromJson(response);
  } else {
    Serial.println("Error en la solicitud HTTP: " + String(httpResponseCode));

    result = NtfyResponse::addMessage(http.errorToString(httpResponseCode));
  }

  http.end();

  return result;
}

void sendMessage() {
  Serial.println("Realizando solicitud HTTP...");

  NtfyResponse response = requestHttp("POST", "https://ntfy.sh/hct99Q3DhOcNvlzN", "¡Hola desde ESP32-S3!");
  Serial.print("Respuesta HTTP:");
  Serial.println(response.message);

  Serial.println("Esperando 10 segundos para la próxima solicitud...");
  delay(1000 * 10);
}

void loop() {
  if (isConnectedWifi() == true) sendMessage();
}
