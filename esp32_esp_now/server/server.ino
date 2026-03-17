#include <WiFi.h>
#include <esp_now.h>

uint8_t peer[] = {0x1C, 0xDB, 0xD4, 0x74, 0xAF, 0xB8}; // Peer MAC address

#define RXD2 16
#define TXD2 17

uint8_t buffer[200];

void setup() {
  Serial.begin(115200);                     // Debug output to USB
  Serial2.begin(115200, SERIAL_8N1, RXD2, TXD2); // UART input from FPGA

  WiFi.mode(WIFI_STA);
  WiFi.disconnect();

  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW init failed");
    while (true);
  }

  // Add peer
  esp_now_peer_info_t p = {};
  memcpy(p.peer_addr, peer, 6);
  if (esp_now_add_peer(&p) != ESP_OK) {
    Serial.println("Failed to add peer");
  } else {
    Serial.println("Peer added successfully");
  }
}

void loop() {
  int len = 0;

  // Read all bytes from UART
  while (Serial2.available() && len < sizeof(buffer)) {
    buffer[len++] = Serial2.read();
  }

  if (len > 0) {
    // Send via ESP-NOW
    esp_err_t result = esp_now_send(peer, buffer, len);

    // Debug: print bytes in HEX for exact value
    Serial.print("UART->ESP-NOW [");
    Serial.print(len);
    Serial.print(" bytes]: ");
    for (int i = 0; i < len; i++) {
      if (buffer[i] < 16) Serial.print("0"); // leading zero
      Serial.print(buffer[i], HEX);
      Serial.print(" ");
    }
    Serial.println(result == ESP_OK ? "-> Success" : "-> Failed");

    len = 0; // reset buffer length
  }

  delay(10); // small delay for readability, can remove in production
}