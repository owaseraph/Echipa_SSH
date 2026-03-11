import java.util.Scanner;
import com.fazecast.jSerialComm.*;

public class Transmitter {
    public static void main(String[] args){
        SerialPort comPort = SerialPort.getCommPort("ttyUSB1");
        comPort.setBaudRate(115200);

        if(!comPort.openPort()){
            System.out.println("Could not open port!");

            return;
        }
        System.out.println("Connected to: "+ comPort.getSystemPortName());
        System.out.println("Type a message to send to the port: ");

        // adding the listener
        // this runs in a different thread

        comPort.addDataListener(new SerialPortDataListener() {
            @Override
            public int getListeningEvents(){
                return SerialPort.LISTENING_EVENT_DATA_AVAILABLE;
            }

            @Override
            public void serialEvent(SerialPortEvent event){
                if(event.getEventType() != SerialPort.LISTENING_EVENT_DATA_AVAILABLE)
                    return;


                byte[] newData = new byte[comPort.bytesAvailable()];

                comPort.readBytes(newData, newData.length);
                System.out.println("\nReceived echo: " +new String(newData));
                System.out.println("\nMessage: "); //print the prompt you entered
            }
        });


        //the transmitter
        Scanner scanner = new Scanner(System.in);
        while (true) {
            System.out.println("Message: ");
            String input = scanner.nextLine();
            if (input.equalsIgnoreCase("exit"))
                break;
            
            byte[] buffer = (input+"\n").getBytes();

            comPort.writeBytes(buffer, buffer.length);
        }
        comPort.removeDataListener();
        comPort.closePort();
        System.out.println("Closed Port.");

    }    
}
