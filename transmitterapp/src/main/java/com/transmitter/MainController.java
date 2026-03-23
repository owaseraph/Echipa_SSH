package com.transmitter;

import java.net.URL;
import java.util.ResourceBundle;

import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.ComboBox;
import javafx.scene.control.TextArea;
import javafx.scene.control.TextField;

// implements initializable to override initialize for startup 
public class MainController implements Initializable{ 
    // instantiate serialBackend obj
    private SerialBackend backend = new SerialBackend(); 

    private String lastPort = ""; // last opened port name

    @FXML private TextArea messageArea; // central message area
    @FXML private TextField messageInput; // message input 
    @FXML private ComboBox portComboBox; // port combo box

    // initialize ComboBox with ports
    @Override
    public void initialize(URL url, ResourceBundle rb){
        portComboBox.getItems().addAll(backend.getAvailablePorts());
    }

    
    // refresh ports
    @FXML
    private void onRefresh(){
        portComboBox.getItems().clear();
        portComboBox.getItems().addAll(backend.getAvailablePorts());
    }
    
    // try connecting
    @FXML
    private void onConnect(){
        String portName = (String)portComboBox.getValue();
        if (portName == null){ // check for ports selected
            messageArea.appendText("No port selected\n");
            return;
        }
        int baudRate = backend.getBaudRate();
        // try to connect
        if(backend.connect(portName, baudRate) && backend.isConnected()){
            messageArea.appendText("Connected to " + portName +"\n");
            lastPort = portName;
            
            // start listening to the port
            // pass a lambda function to the backend to be executed called when there's bytes available to read
            // message will be passed to the lambda function
            // used so backend doesn't communicate directly with ui elements
            backend.startListening(message ->{ 
                Platform.runLater(() -> {
                    messageArea.appendText("Received " + message + " from FPGA\n");
                });
            });
        }
        else 
            messageArea.appendText(" Failed to connected to " + portName + "\n");        
    }
    
    // disconnect
    @FXML
    private void onDisconnect(){
        if(backend.disconnect()){
            messageArea.appendText("Disconnected from " + lastPort + "\n");
            backend.stopListening();
        }
    }

    // send messsage to fpga
    @FXML
    private void onSend() {
        String input = messageInput.getText().trim();
        if(input.isEmpty()) return;
        // send bytes to FPGA
        if(backend.sendText(input)){
            // write on message Area
            messageArea.appendText("Sent to FPGA: " + input + "\n");
        }
        else // port is not connected
            messageArea.appendText("Not connected to any port\n");
        messageInput.clear();
    }

} 