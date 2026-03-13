#include "WiFi.h"

const char* ssid = "ESP32_HOST";
const char* password = "regelepetric";
const int port = 80;
const char* serverIP = "192.168.4.1"; //default esp32 ap ip

void setup() {
  Serial.begin(115200);
  delay(2000);
  Serial.println("Serial connection ready");

  // connect to the access point
  WiFi.begin(ssid, password);
  Serial.println("Connecting to acces point...");
  while(WiFi.status() != WL_CONNECTED)
  delay(10);
  Serial.println("Connected to acces point");


}

void loop() {
  WiFiClient client;
  // connect to TCP server
  Serial.println("Connecting to server");
  if(client.connect(serverIP, port)){
    Serial.println("Connected to server");
    Serial.println("\n\tChat started\n");
    while(client.connected()){
      // send message to host
      if(Serial.available()){
        String clientMsg = Serial.readStringUntil('\n');
        client.println(clientMsg);
        Serial.print("Client: ");
        Serial.println(clientMsg);
      }

      // check for messages from the host
      if(client.available()){
        Serial.print("Host: ");
        Serial.println(client.readStringUntil('\n'));
      }
    }
  }
  else Serial.println("Connection failed, retrying ...");
  delay(2000);

}
