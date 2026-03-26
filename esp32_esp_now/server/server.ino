#include <WiFi.h>
#include <esp_now.h>

#define RXD2 16
#define TXD2 17
#define BLOCK_SIZE 16

uint8_t buffer[BLOCK_SIZE];
uint8_t peer[] = {0x3C,0x0F,0x02,0xCF,0x53,0x74}; // Peer MAC address

void setup() {
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, RXD2, TXD2);

  WiFi.mode(WIFI_STA);


  WiFi.disconnect();

  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW init failed");
    while (true);
  }


  esp_now_peer_info_t p = {};
  memcpy(p.peer_addr, peer, 6);
  p.channel = 0;
  p.encrypt = false;
  if (esp_now_add_peer(&p) != ESP_OK) {
    Serial.println("Failed to add peer");
  } else {
    Serial.print("Peer added: ");
    for(int i=0; i<6; i++) { Serial.printf("%02X", peer[i]); if(i<5) Serial.print(":"); }
    Serial.println();
  }
  Serial.print(WiFi.macAddress());

}

void loop() {
  static int block_index = 0;

  // Read bytes until we have BLOCK_SIZE
  while (Serial2.available() && block_index < BLOCK_SIZE) {
    uint8_t b = Serial2.read();
    buffer[block_index++] = b;
    Serial.printf("%02X ", b); // Debug: print received byte
  }

  // Optionally print how many bytes are currently buffered
  if (block_index > 0 && block_index < BLOCK_SIZE) {
    Serial.print("[Buffered: ");
    Serial.print(block_index);
    Serial.println(" bytes]");
  }

  if (block_index == BLOCK_SIZE) {
    // Debug: print exactly what you are about to send
    Serial.print("\nPreparing to send block: ");
    for (int i = 0; i < BLOCK_SIZE; i++) {
      if (buffer[i] < 16) Serial.print("0");
      Serial.print(buffer[i], HEX);
      Serial.print(" ");
    }

    // Actually send the block
    esp_err_t result = esp_now_send(peer, buffer, BLOCK_SIZE);

    Serial.println(result == ESP_OK ? "-> Success" : "-> Failed");

    block_index = 0;
  }
}