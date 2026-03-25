#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>

const char* WIFI_NAME = "Gimbernat_docencia";
const char* WIFI_PASSWORD = "";

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

  Serial.println("\nConectado a WiFi");
}


void setup() {
  Serial.begin(115200);
  Serial.println("Hello, ESP32-S3...");

  connectWifi();
}

auto requestHttp(String url) {
  if (url == "") {
    Serial.println("URL vacía");
    return String("URL vacía");
  }

  HTTPClient http;
  http.begin(url);
  int httpResponseCode = http.GET();

  auto result = String();

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.println("Respuesta HTTP:");
    Serial.println(response);

    result = response;
  } else {
    Serial.println("Error en la solicitud HTTP");

    result = http.errorToString(httpResponseCode).c_str();
  }

  http.end();

  return result;
}

void loop() {
  delay(10000);

  if (isConnectedWifi() == false) return;

  Serial.println("Realizando solicitud HTTP...");
}
