#include <WiFi.h>
const char* ssid = "ESP32_HOST";
const char* password = "regelepetric";
const int port = 80;
WiFiServer server(port); //listen on port 80

void setup(){
  Serial.begin(115200);
  delay(2000);
  Serial.println("Serial connection ready");

  // start the server
  WiFi.softAP(ssid, password); // create acces point
  server.begin(); // start listening for connections
  Serial.println("Server started");

  // show host ip
  Serial.print("Server ip: ");
  Serial.println(WiFi.softAPIP());
}
void loop(){
  //check if any client is connected
  WiFiClient client = server.available();
  if (client){
    Serial.println("Client connected");
    Serial.println("\n\tChat Started\n");

    while(client.connected()){
       // send message to client
      if(Serial.available()){
         String hostMsg = Serial.readStringUntil('\n');
         client.println(hostMsg);
         Serial.print("Host: ");
         Serial.println(hostMsg);
      }

      //check for messages from client
      if(client.available()){
          Serial.print("Client: ");
          Serial.println( client.readStringUntil('\n'));
      }
    }
    Serial.println("Client disconneced");
  }
}