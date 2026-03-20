#include <Arduino.h>

#define PIN_LED_1 6
#define PIN_LED_2 7
#define PIN_SWITCH 42
#define PIN_BUTTON 41

int status_led_1 = LOW;
int status_led_2 = LOW;
int status_switch = HIGH;
int last_read_status_switch = HIGH;
int status_button = HIGH;
int last_read_status_button = HIGH;

unsigned long last_time_1 = 0;
unsigned long last_time_2 = 0;
unsigned long last_time_switch = 0;
unsigned long last_time_button = 0;

const long interval_1 = 200; // LED 1 (200ms)
const long interval_2 = 1000 * 5; // LED 2 (5s)
const long debounce_time = 30;


void setup() {
  Serial.begin(115200);
  Serial.println("Hello, ESP32-S3...");

  pinMode(PIN_LED_1, OUTPUT);
  pinMode(PIN_LED_2, OUTPUT);
  pinMode(PIN_SWITCH, INPUT_PULLUP);
  pinMode(PIN_BUTTON, INPUT_PULLUP);
}

void ledsRun() {
  unsigned long time_now = millis();

  if (time_now - last_time_1 >= interval_1) {
    last_time_1 = time_now;

    status_led_1 = !status_led_1;
    digitalWrite(PIN_LED_1, status_led_1);

    // if (status_led_1) {
    //   Serial.println("LED 1 Encendido");
    // } else {
    //   Serial.println("LED 1 Apagado");
    // }
  }

  if (time_now - last_time_2 >= interval_2) {
    last_time_2 = time_now;

    status_led_2 = !status_led_2;
    digitalWrite(PIN_LED_2, status_led_2);

    // if (status_led_2) {
    //   Serial.println("LED 2 Encendido");
    // } else {
    //   Serial.println("LED 2 Apagado");
    // }
  }
}

void switchRun() {
  unsigned long time_now = millis();

  const int read_status_switch = digitalRead(PIN_SWITCH);

  if (read_status_switch != last_read_status_switch) {
    last_time_switch = time_now;
  }

  if ((time_now - last_time_switch) >= debounce_time && status_switch != read_status_switch) {
    status_switch = read_status_switch;
    if (status_switch == HIGH) {
      Serial.println("Switch Apagado");
    } else if (status_switch == LOW) {
      Serial.println("Switch Encendido");
    }
  }

  last_read_status_switch = read_status_switch;
}

void buttonRun() {
  unsigned long time_now = millis();

  const int read_status_button = digitalRead(PIN_BUTTON);
  if (read_status_button != last_read_status_button) {
    last_time_button = time_now;
  }

  if ((time_now - last_time_button) >= debounce_time && status_button != read_status_button) {
    status_button = read_status_button;

    if (status_button == HIGH) {
      Serial.println("Button Soltado");
    } else if (status_button == LOW) {
      Serial.println("Button Presionado");
    }
  }

  last_read_status_button = read_status_button;
}

void loop() {
  ledsRun();
  switchRun();
  buttonRun();
}
