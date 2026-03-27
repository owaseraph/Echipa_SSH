#!/bin/bash

echo "Rebuilding ..."
rm -rf SerialMonitor
mvn clean package
mkdir -p /target/libs
mvn dependency:copy-dependencies -DoutputDirectory=target/libs
cp target/transmitterapp-1.0-SNAPSHOT.jar target/libs
jpackage --input target/libs --name SerialMonitor --main-jar transmitterapp-1.0-SNAPSHOT.jar --main-class com.transmitter.Launcher --type app-image