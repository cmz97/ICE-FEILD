

import CoreBluetooth
//Uart Service uuid


let kBLEService_UUID = "FFE0"
let kBLE_Characteristic_uuid_Tx = "FFE1"
let kBLE_Characteristic_uuid_Rx = "FFE1"
let MaxCharacters = 20

let BLEService_UUID = CBUUID(string: kBLEService_UUID)
let BLE_Characteristic_uuid_Tx = CBUUID(string: kBLE_Characteristic_uuid_Tx)//(Property = Write without response)
let BLE_Characteristic_uuid_Rx = CBUUID(string: kBLE_Characteristic_uuid_Rx)// (Property = Read/Notify)
