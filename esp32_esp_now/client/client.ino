#include <WiFi.h>
#include <esp_now.h>

#define BUFFER_SIZE 256
uint8_t rxBuffer[BUFFER_SIZE];
volatile int rxLen = 0;

void onData(const esp_now_recv_info_t *info, const uint8_t *data, int len) {
  if (len > 0 && len <= BUFFER_SIZE) {
    for (int i = 0; i < len; i++) {
      rxBuffer[i] = data[i];
    }
    rxLen = len; // mark buffer as ready
  }
}

void setup() {
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  esp_now_init();
  esp_now_register_recv_cb(onData);
}

void loop() {
  if (rxLen > 0) {
    Serial.write(rxBuffer, rxLen);
    rxLen = 0; // reset
  }
}