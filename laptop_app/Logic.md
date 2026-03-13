# Serial Port Checker

## 1. Hardware-to-Software Mapping
The code utilizes `SerialPort.getCommPorts()`, which acts as a bridge between high-level Java code and low-level C++ system structures. 
* On **Windows**, it looks for registry entries for COM ports.
* On **Linux/macOS**, it scans the `/dev/` directory for `ttyUSB` or `ttyACM` devices.

## 2. Resource Enumeration
Rather than hard-coding a port name (like "COM3"), which might change depending on which USB slot is used, the code **enumerates** all available resources. This makes the tool portable and helps in debugging "Device Not Found" errors.

## Sequence of Execution

1. **Initialization**: The program prints a status message to the console to confirm the JVM has started successfully.
2. **Polling**: The `getCommPorts()` method is called. This sends a request to the OS kernel to list all active Universal Asynchronous Receiver/Transmitter (UART) devices.
3. **Iteration**: A `for-each` loop traverses the resulting array of `SerialPort` objects.
4. **Data Extraction**: For each object, `getSystemPortName()` is called to retrieve the identifier string used by the OS (e.g., "COM4").
5. **Reporting**: The names are printed to the standard output, providing the user with the exact string needed for the main communication module.


## Dependencies
* **Library**: `jSerialComm` (fazecast)
* **Reasoning**: This library is preferred over the older RXTX or JSSC because it is actively maintained and does not require manual installation of native `.dll` or `.so` files, as they are bundled within the JAR.

# Transmitter & Listener

## 1. Connection Setup
The program initializes the communication channel by targeting a specific hardware address.
* **Port Selection**: It targets `ttyUSB1`, predefined port for my FPGA.
* **Baud Rate Matching**: The speed is set to **115,200**. This is a hard requirement; if the Java baud rate does not match the Verilog constant (`868` cycles per bit at 100MHz), the synchronization between the PC and FPGA will fail.
* **Port Opening**: The code includes a safety check to ensure the port is available before proceeding, preventing crashes if the hardware is disconnected.


## 2. Asynchronous Data Listener
The core of the receiver logic is the `SerialPortDataListener`. This runs in a **separate background thread**, ensuring the UI remains responsive.
* **Event Trigger**: The listener stays dormant until the `LISTENING_EVENT_DATA_AVAILABLE` event is fired by the OS.
* **Dynamic Buffering**:
    * `bytesAvailable()`: Determines exactly how much data is waiting in the system buffer.
    * `readBytes()`: Pulls the raw bytes into a local array.
* **Data Reconstruction**: The raw bytes are converted back into a Java `String` for display. This is where the user sees the "+1 modified" character returned by the FPGA.


## 3. Transmission Logic
The main execution thread handles user interaction through a standard `Scanner` loop.
* **User Input**: The program captures strings from the console until the user types "exit".
* **Serialization**: Since UART communicates bit-by-bit, the code converts the String into a byte array using `.getBytes()`.
* **Message Framing**: A newline character (`\n`) is appended to the input. This helps define the end of a data packet, which is a standard practice in serial protocols.


## 4. Resource Management
To ensure the system remains stable after the program ends, the code performs a "Clean Teardown":
1. **Remove Listener**: Stops the background thread from monitoring hardware interrupts.
2. **Close Port**: Releases the serial hardware back to the Operating System so other applications (or a future run of this program) can access it.


### Functional Summary
| Software Component | Hardware Interaction |
| :--- | :--- |
| `Scanner / nextLine()` | Human Input |
| `comPort.writeBytes()` | Sends to FPGA `uart_rx` |
| `SerialPortDataListener` | Waits for FPGA `uart_tx` |
| `newData +1` (FPGA side) | Data Transformation |