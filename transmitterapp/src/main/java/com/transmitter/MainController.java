/*
Main controller for the App
-handles the connection between backend and main, backend can't directly modify ui elements
-implements functions and handles connection states and edge cases

*/

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

    @FXML private TextArea serialInputArea; // input serial area
    @FXML private TextArea serialOutputArea; // output (received) area
    @FXML private TextArea logsArea; // logs area
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
        onDisconnect(); // disconnect from last port

        String portName = (String)portComboBox.getValue();
        if (portName == null){ // check for ports selected
            logsArea.appendText("No port selected\n");
            return;
        }
        int baudRate = backend.getBaudRate();
        // try to connect
        if(backend.connect(portName, baudRate) && backend.isConnected()){
            logsArea.appendText("Connected to " + portName +"\n");
            lastPort = portName;
            
            // start listening to the port
            // pass a lambda function to the backend to be executed called when there's bytes available to read
            // message will be passed to the lambda function
            // used so backend doesn't communicate directly with ui elements
            backend.startListening(message ->{ 
                Platform.runLater(() -> {
                    serialOutputArea.appendText(message + "\n");
                });
            });
        }
        else 
            logsArea.appendText("Failed to connected to " + portName + "\n");        
    }
    
    // disconnect
    @FXML
    private void onDisconnect(){
        if(backend.isConnected()){
            backend.stopListening();
            backend.disconnect();
            logsArea.appendText("Disconnected from " + lastPort + "\n");
        }
    }

    // send messsage to fpga
    @FXML
    private void onSend() {
        String input = messageInput.getText().trim();
        if(input.isEmpty()) return;
        // send bytes to FPGA
        if(!backend.sendText(input)){ // not connected (port Disconnected or failed)
            logsArea.appendText("Not connected to any port\n");
        }
        else // connected
            serialInputArea.appendText(input + "\n");
        
        messageInput.clear();
    }

    // cleanup for soft close
    public void cleanup(){
        onDisconnect();
    }
} 