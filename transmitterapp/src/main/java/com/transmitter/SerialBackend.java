package com.transmitter;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Consumer;

import com.fazecast.jSerialComm.SerialPort;
import com.fazecast.jSerialComm.SerialPortDataListener;
import com.fazecast.jSerialComm.SerialPortEvent;

public class SerialBackend{
    // constants
    private final int baudRate = 115200;
    private final int numDataBits = 8;

    // port object to connect 
    private SerialPort port;
    
    // Block transmission state
    private ByteArrayOutputStream blockBuffer = new ByteArrayOutputStream(16); // accumulates bytes
    private volatile boolean readyForInput = true; // flag marked true after all the bytes are echoed back
    private AtomicInteger blocksExpected = new AtomicInteger(0); 
    private AtomicInteger blocksReceived = new AtomicInteger(0); // count how many blocks were echoed
    
    // Callback for block logging
    private Consumer<String> blockLogCallback;
    
    public ArrayList<String> getAvailablePorts(){
        // list with com ports
        ArrayList <String> comPorts = new ArrayList<>(); 

        for(SerialPort port: SerialPort.getCommPorts()){
            comPorts.add(port.getSystemPortName());
        }
        return comPorts;
    }
    public boolean connect(String portName, int baudRate){
        // get port by name
        port = SerialPort.getCommPort(portName); 

        // config
        port.setBaudRate(baudRate);
        port.setNumDataBits(numDataBits);
        port.setNumStopBits(SerialPort.ONE_STOP_BIT);
        port.setParity(SerialPort.NO_PARITY);
        
        // open port
        return port.openPort(); 

    }

    public boolean disconnect(){
        if (port!= null && port.isOpen()){
            port.closePort(); //close port
            return true;
        }
        return false;
    }

    public boolean isConnected(){
        return (port!= null && port.isOpen());
     }

    public int getBaudRate(){
        return this.baudRate;
    }


    public boolean sendText(String text){
        if(!isConnected())
            return false;
        byte[] buffer = (text + "\n").getBytes();
        int written = port.writeBytes(buffer, buffer.length); 
        return written == buffer.length;
    }
    
     // Send raw bytes (16-byte blocks)
    public boolean sendBytes(byte[] data) {
        if(!isConnected())
            return false;
        int written = port.writeBytes(data, data.length);
        return written == data.length;
    }
    
    
    // Check if ready for next message
    public boolean isReadyForInput() {
        return readyForInput;
    }
    

     // Set the block log callback to output messages on the log
    public void setBlockLogCallback(Consumer<String> callback) {
        this.blockLogCallback = callback;
    }
    
    
     // Setup for block-based transmission
    public void setupBlockTransmission(int totalBlocks) {
        blocksExpected.set(totalBlocks);
        blocksReceived.set(0);
        readyForInput = false;
        blockBuffer.reset();
    }
    
    
     // Wait until all blocks are received
    public void waitForAllBlocks() {
        while (!readyForInput) {
            try {
                Thread.sleep(10);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
    }
    
    // pass the function received from controller -> data arrives -> function gets called with the data
    public void startListening(Consumer<String> onMessageReceived){ 
        //onMessageReceived = message -> {lambda function to be implemented based on message}

        // add dataListener to port
        port.addDataListener(new SerialPortDataListener() {

            // implement getListeningEvents()
            @Override   
            public int getListeningEvents(){ 
                return SerialPort.LISTENING_EVENT_DATA_AVAILABLE; // fire when data is available
            }

            // implement serialEvent() - jserial calls it automatically when data arrives
            @Override
            public void serialEvent(SerialPortEvent event){
                if(event.getEventType() != SerialPort.LISTENING_EVENT_DATA_AVAILABLE)
                    return; // ignore other events
            
                int available = port.bytesAvailable(); // available bytes
                if(available<=0) return; // nothing to read

                byte[] buffer = new byte [available];
                // read bytes
                port.readBytes(buffer, buffer.length); 

                // Process data as blocks
                synchronized (blockBuffer) {
                    for (byte b : buffer) {
                        blockBuffer.write(b);
                        if (blockBuffer.size() == 16) {
                            byte[] block = blockBuffer.toByteArray();
                            int blockNum = blocksReceived.get() + 1;
                            
                            // Format and log the block
                            String logMsg = formatBlockLog("[RX] Block " + blockNum + "/" + blocksExpected.get() + " received: ", block);
                            if (blockLogCallback != null) {
                                blockLogCallback.accept(logMsg); // call the lambda and display the log msg
                            }
                            
                            blockBuffer.reset();
                            
                            // Increment counter and check if all blocks received
                            if (blocksReceived.incrementAndGet() >= blocksExpected.get()) {
                                if (blockLogCallback != null) {
                                    blockLogCallback.accept("[INFO] All blocks received.");
                                }
                                readyForInput = true;
                                blocksExpected.set(0);
                                blocksReceived.set(0);
                            }
                        }
                    }
                }
                
                // pass to the general message callback for raw data
                String message = new String (buffer);
                onMessageReceived.accept(message);
            }
        });
    }

    public void stopListening(){
        port.removeDataListener();
    }
    
    
    // Format a block for logging (printable characters as-is, non-printable as hex)
    private String formatBlockLog(String prefix, byte[] block) {
        StringBuilder sb = new StringBuilder(prefix);
        for (byte b : block) {
            if (b >= 32 && b < 127) {
                sb.append((char) b);
            } else {
                sb.append(String.format("\\x%02X", b));
            }
        }
        return sb.toString();
    }
}
