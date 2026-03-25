#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

static const String WIFI_NAME = "Wokwi-GUEST";
static const String WIFI_PASSWORD = "";

class NtfyResponse {
public:
  String id;
  String time;
  int expires;
  String event;
  String topic;
  String message;
  NtfyResponse() : id(""), time(""), expires(0), event(""), topic(""), message("") {}
  NtfyResponse(String response) {
    DynamicJsonDocument doc(512);
    deserializeJson(doc, response);

    id = doc["id"].as<String>();
    time = doc["time"].as<String>();
    expires = doc["expires"];
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
  if (url == "") {
    Serial.println("Debes especificar una URL válida");
    return NtfyResponse(String("Invalid URL"));
  }

  HTTPClient http;
  http.begin(url);
  int httpResponseCode;
  if (method == "GET") {
    httpResponseCode = http.GET();
  } else if (method == "POST") {
    httpResponseCode = http.POST(payload);
  } else {
    Serial.println("Método HTTP no soportado");
    return NtfyResponse(String("Unsupported HTTP method"));
  }

  NtfyResponse result = NtfyResponse();

  if (httpResponseCode > 0) {
    String response = http.getString();

    result = NtfyResponse(response);
  } else {
    Serial.println("Error en la solicitud HTTP: " + String(httpResponseCode));

    result.message = http.errorToString(httpResponseCode).c_str();
  }

  http.end();

  return result;
}

void loop() {
  if (isConnectedWifi() == true) {
    Serial.println("Realizando solicitud HTTP...");
    NtfyResponse response = requestHttp("POST", "https://ntfy.sh/hct99Q3DhOcNvlzN", "¡Hola desde ESP32-S3!");
    Serial.print("Respuesta HTTP:");
    Serial.println(response.message);

    Serial.println("Esperando 10 segundos para la próxima solicitud...");
    delay(1000 * 10);
  }
}
