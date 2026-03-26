import java.io.ByteArrayOutputStream;
import java.util.Scanner;
import com.fazecast.jSerialComm.*;

public class Transmitter {
    static ByteArrayOutputStream blockBuffer = new ByteArrayOutputStream(16);
    static volatile boolean readyForInput = true;

    public static void main(String[] args){
        SerialPort comPort = SerialPort.getCommPort("ttyUSB2");
        comPort.setBaudRate(115200);

        if(!comPort.openPort()){
            System.out.println("Could not open port!");
            return;
        }
        System.out.println("Connected to: "+ comPort.getSystemPortName());
        System.out.println("Type a 16-character message to send to the port.\n");

        comPort.addDataListener(new SerialPortDataListener() {
            @Override
            public int getListeningEvents(){
                return SerialPort.LISTENING_EVENT_DATA_AVAILABLE;
            }

            @Override
            public void serialEvent(SerialPortEvent event) {
                if (event.getEventType() != SerialPort.LISTENING_EVENT_DATA_AVAILABLE)
                    return;

                byte[] newData = new byte[comPort.bytesAvailable()];
                comPort.readBytes(newData, newData.length);

                synchronized (blockBuffer) {
                    for (byte b : newData) {
                        blockBuffer.write(b);
                        // Only print when a full 16-byte block received:
                        if (blockBuffer.size() == 16) {
                            byte[] block = blockBuffer.toByteArray();
                            System.out.print("\nReceived echo: ");
                            for (byte c : block) System.out.print((char)c);
                            System.out.println();
                            blockBuffer.reset();

                            // Allow the main thread to prompt again:
                            readyForInput = true;
                        }
                    }
                }
            }
        });

        Scanner scanner = new Scanner(System.in);
        while (true) {
            // Wait until ready
            while (!readyForInput) {
                try { Thread.sleep(10); } catch (InterruptedException e) {}
            }
            System.out.print("Message: ");
            String input = scanner.nextLine();
            if (input.equalsIgnoreCase("exit"))
                break;

            if (input.length() != 16) {
                System.out.println("Please enter EXACTLY 16 characters!");
                continue;
            }

            byte[] buffer = input.getBytes();
            comPort.writeBytes(buffer, buffer.length);
            readyForInput = false; // Wait for echo before next prompt
        }

        comPort.removeDataListener();
        comPort.closePort();
        System.out.println("Closed Port.");
    }
}