
import UIKit
import CoreBluetooth
import DeflateSwift

class UartModuleViewController: UIViewController, CBPeripheralManagerDelegate, UITextViewDelegate, UITextFieldDelegate {
    
    //UI
    @IBOutlet weak var baseTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var xLButton: UIButton!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var switchUI: UISwitch!
    @IBOutlet weak var voiceButton: UIButton!
    
    //Global Constant
    let MAX_DATA_LENGTH = 1000
    
    //Data
    var peripheralManager: CBPeripheralManager?
    var peripheral: CBPeripheral!
    private var consoleAsciiText:NSAttributedString? = NSAttributedString(string: "")
    var timer = Timer()
    
    //XL Function Relavent Parameters
    var counter = 0
    let totalXLdatalength = 5
    
    //SmallPackge Parameters
    var smallPackageCounter = 0 //Count the number of small package Sent
    let smallPackageSize = 20 //Size of the each small package
    let tickRate = 0.006  //TickRate of the timer
    var smallPackageTimer = Timer()
    var headerBytes = Data(bytes: [])
    let footerBytes = Data(bytes: [0x7d,0x5d,0x3e,0x0,0x0,0x0])
    
    var audioData:Data = Data(bytes: [1])
    var DataByteEndFlag = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.plain, target:nil, action:nil)
        self.baseTextView.delegate = self
        self.inputTextField.delegate = self
        //Base text view setup
        self.baseTextView.layer.borderWidth = 3.0
        self.baseTextView.layer.borderColor = UIColor.blue.cgColor
        self.baseTextView.layer.cornerRadius = 3.0
        self.baseTextView.text = ""
        //Input Text Field setup
        self.inputTextField.layer.borderWidth = 2.0
        self.inputTextField.layer.borderColor = UIColor.blue.cgColor
        self.inputTextField.layer.cornerRadius = 3.0
        //Create and start the peripheral manager
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        //-Notification for updating the text view with incoming text
        updateIncomingData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.baseTextView.text = ""
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // peripheralManager?.stopAdvertising()
        // self.peripheralManager = nil
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        
    }
    
    func updateIncomingData () {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "Notify"), object: nil , queue: nil){
            notification in
            let appendString = "\n"
            let myFont = UIFont(name: "Helvetica Neue", size: 15.0)
            let myAttributes2 = [NSAttributedStringKey.font: myFont!, NSAttributedStringKey.foregroundColor: UIColor.red]
            let attribString = NSAttributedString(string: "[Rx]: " + (characteristicASCIIValue as String) + appendString, attributes: myAttributes2)
            let newAsciiText = NSMutableAttributedString(attributedString: self.consoleAsciiText!)
            self.baseTextView.attributedText = NSAttributedString(string: characteristicASCIIValue as String , attributes: myAttributes2)
            
            newAsciiText.append(attribString)
            
            self.consoleAsciiText = newAsciiText
            self.baseTextView.attributedText = self.consoleAsciiText
            
        }

    }
    
    @IBAction func clickSendAction(_ sender: AnyObject) {
        outgoingData()
    }
    
    @IBAction func sendLargeData(_ sender: AnyObject) {
        timer = Timer.scheduledTimer(timeInterval: tickRate, target: self, selector: #selector (UartModuleViewController.updateTimer) , userInfo: nil, repeats: true)
    }
    

    
    
    func outgoingData () {
        let appendString = "\n"
        
        let inputText = inputTextField.text
        
        let myFont = UIFont(name: "Helvetica Neue", size: 15.0)
        let myAttributes1 = [NSAttributedStringKey.font: myFont!, NSAttributedStringKey.foregroundColor: UIColor.blue]
        
        writeValueBLE(data: inputText!)
        
        let attribString = NSAttributedString(string: "[Tx]: " + inputText! + appendString, attributes: myAttributes1)
        let newAsciiText = NSMutableAttributedString(attributedString: self.consoleAsciiText!)
        newAsciiText.append(attribString)
        
        consoleAsciiText = newAsciiText
        baseTextView.attributedText = consoleAsciiText
        //erase what's in the text field
        inputTextField.text = ""
    }
    
    // Write functions
    func writeValueBLE(data: String){
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        //change the "data" to valueString
        if let blePeripheral = blePeripheral{
            if let txCharacteristic = txCharacteristic {
                blePeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
    }
    


    func writeCharacteristic(val: Int8){
        var val = val
        let ns = NSData(bytes: &val, length: MemoryLayout<Int8>.size)
        blePeripheral!.writeValue(ns as Data, for: txCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    
    
    //MARK: UITextViewDelegate methods
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView === baseTextView {
            //tapping on consoleview dismisses keyboard
            inputTextField.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.setContentOffset(CGPoint(x:0, y:250), animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        scrollView.setContentOffset(CGPoint(x:0, y:0), animated: true)
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            return
        }
        print("Peripheral manager is running")
    }
    
    //Check when someone subscribe to our characteristic, start sending the data
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Device subscribe to characteristic")
    }
    
    //This on/off switch sends a value of 1 and 0 to the Arduino
    //This can be used as a switch or any thing you'd like
    @IBAction func switchAction(_ sender: Any) {
        if switchUI.isOn {
            print("On ")
            writeCharacteristic(val: 1)
        }
        else
        {
            print("Off")
            writeCharacteristic(val: 0)
            print(writeCharacteristic)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        outgoingData()
        return(true)
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("\(error)")
            return
        }
    }
    
    //Modified
    
    //Segue shit
    
    
    //Extract an segments of bite array, then remove it from original data
    func extract(from data: inout Data, length: Int) -> Data? {
        guard data.count > 0 else {
            return nil
        }
        let range = Range(0..<length)
        let subData = data.subdata(in: range)
        data.removeSubrange(range)
        return subData
    }
    
    func sendVoiceData (voiceURL:URL){
        do {
            audioData =  try Data(contentsOf: voiceURL)
            print("raw data \(audioData)\n")
            
            //print(encodedString)
            //let decodedData = Data(base64Encoded: encodedString)!
            //let decodedString = String(data: decodedData, encoding: .utf8)!
            //let data = decodedString.data(using: .utf8)!
            //let array = [UInt8](data)
            //print("\n\n\n\n")
            //print(array)
            
            //encodedString = dataCompressor(unCompressedData:encodedString) // Compress Encoded String
            
            DataByteEndFlag = false
            smallPackageTimer = Timer.scheduledTimer(timeInterval: tickRate, target: self, selector: #selector (UartModuleViewController.smallPackageSender) , userInfo: nil, repeats: true)
            } catch {
            print("Error while Sending Voice Data ")
        }
    }
    
    func dataCompressor (unCompressedData:String) -> String{
        let deflater = DeflateStream()
        let encodedStringInByte = [UInt8](unCompressedData.utf8)
        let (deflated, err) = deflater.write(bytes: encodedStringInByte, flush: true)
        if err != nil{
            fatalError("\(err!)")
        }
        let compressedString = String(data: Data(deflated), encoding: .utf8)
        return compressedString!
    }
    
    @objc func smallPackageSender(){
        if (DataByteEndFlag == false) {
            var header : Data = Data.init(count:8);
            header[0] = 0x3c;
            header[1] = 0x5b;
            header[2] = 0x8b;
            var footer : Data = Data.init(count:6);
            footer[0] = 0x7d;
            footer[1] = 0x6d;
            footer[2] = 0x3e;
            
            
            
            var foot3: UInt8 = 0x0;
            var foot4: UInt8 = 0x0;
            var foot5: UInt8 = 0x0;
            
            if (smallPackageCounter % 1000 == 0) {
                // header package
                header[3] = 0x3;
                header[4] = 0x3;
                header[5] = 232;
                header[6] = UInt8(smallPackageCounter / 1000);
                header[7] = UInt8(audioData.count / 1000 + 1);
                writeDataValueBLE(data:header)
                print("header sent: \(header)");
            }
            
            if (smallPackageSize < audioData.count){
                
                let smallPackage = extract(from: &audioData,length: Int(smallPackageSize))
                for nByte in 0...20 {
                    let byte : UInt8 = smallPackage![nByte];
                    foot3 = foot3 ^ byte;
                    if (nByte % 2 == 0) {
                        foot4 = foot4 ^ byte;
                    } else if (nByte % 2 == 1) {
                        foot5 = foot5 ^ byte;
                    }
                }
                writeDataValueBLE(data:smallPackage!)
                smallPackageCounter += smallPackageSize
                print("Small Package That Got Extracted: \(String(describing: smallPackage)), Remain Data: \(audioData), Current Counter: \(smallPackageCounter)\n")
            }else{
                let smallPackage = extract(from: &audioData,length: Int(audioData.count))
                writeDataValueBLE(data:smallPackage!)
                smallPackageCounter += smallPackageSize
                print("Last Small Package That Got Extracted: \(String(describing: smallPackage)), Remain Data: \(audioData), Current Counter: \(smallPackageCounter)\n")
                
                // smallPackageCounter = 0
                DataByteEndFlag = true
                smallPackageTimer.invalidate()
            }
            
            if (smallPackageCounter % 1000 == 0) {
                // footer package
                footer[3] = foot3;
                footer[4] = foot4;
                footer[5] = foot5;
                foot3 = 0x0;
                foot4 = 0x0;
                foot5 = 0x0;
                writeDataValueBLE(data:footer)
                print("header sent: \(footer)");
            }
            
        }
    }
    
    func writeDataValueBLE(data: Data){
        if let blePeripheral = blePeripheral{
            if let txCharacteristic = txCharacteristic {
                blePeripheral.writeValue(data, for: txCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
            }
        }
    }
    
    // Retiring Function
    
    @objc func updateTimer(){ // XL Button
        if(counter == 0){
            writeDataValueBLE(data: Data(bytes: [0x3c,0x5b,0x7b,0x3,0b0,0b1001010,0,1]))
        }else if(counter == totalXLdatalength - 1){
            writeDataValueBLE(data: Data(bytes: [0x7d,0x5d,0x3e,0x0,0x0,0x0]))
        }else{
            writeDataValueBLE(data: Data(bytes: [0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68,0x68]))
        }
        
        print("\(counter) \n")
        
        if(counter + 1 >= totalXLdatalength){
            timer.invalidate()
            counter = 0
        }else{
            counter += 1
        }
        
        
    }
}
