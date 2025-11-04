//
//  ContentView.swift
//  CC
//
//  Created by macbook on 11/4/25.
//

import SwiftUI
import CoreBluetooth
import Combine

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            Text("HM-10 Bluetooth Controller")
                .font(.title2)
                .fontWeight(.bold)
            
            // Bluetooth Status
            HStack {
                Circle()
                    .fill(bluetoothManager.isConnected ? .green : .red)
                    .frame(width: 10, height: 10)
                Text(bluetoothManager.isConnected ? "Connected" : "Disconnected")
                    .foregroundColor(bluetoothManager.isConnected ? .green : .red)
            }
            
            // Scan Button
            Button(action: {
                if bluetoothManager.isScanning {
                    bluetoothManager.stopScan()
                } else {
                    bluetoothManager.startScan()
                }
            }) {
                HStack {
                    Image(systemName: bluetoothManager.isScanning ? "stop.circle" : "antenna.radiowaves.left.and.right")
                    Text(bluetoothManager.isScanning ? "Stop Scan" : "Scan for Devices")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            // Devices List
            List(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                HStack {
                    VStack(alignment: .leading) {
                        Text(device.name ?? "Unknown Device")
                            .fontWeight(.medium)
                        Text(device.identifier.uuidString)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    if bluetoothManager.connectedPeripheral?.identifier == device.identifier {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    bluetoothManager.connectToDevice(device)
                }
            }
            .frame(height: 200)
            
            // Send Data Section
            VStack(spacing: 10) {
                Text("Send Data to HM-10")
                    .font(.headline)
                
                HStack {
                    TextField("Enter text to send", text: $bluetoothManager.textToSend)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send") {
                        bluetoothManager.sendData()
                    }
                    .disabled(!bluetoothManager.isConnected || bluetoothManager.textToSend.isEmpty)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(bluetoothManager.isConnected && !bluetoothManager.textToSend.isEmpty ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
            
            // Disconnect Button
            if bluetoothManager.isConnected {
                Button("Disconnect") {
                    bluetoothManager.disconnect()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .alert("Bluetooth Error", isPresented: $bluetoothManager.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(bluetoothManager.errorMessage)
        }
    }
}

// Bluetooth Manager
class BluetoothManager: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    
    // HM-10 Service and Characteristic UUIDs
    let HM10_SERVICE_UUID = CBUUID(string: "FFE0")
    let HM10_CHARACTERISTIC_UUID = CBUUID(string: "FFE1")
    
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var isConnected = false
    @Published var isScanning = false
    @Published var textToSend = ""
    @Published var showError = false
    @Published var errorMessage = ""
    
    var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScan() {
        guard centralManager.state == .poweredOn else {
            showError(message: "Bluetooth is not available")
            return
        }
        
        discoveredDevices.removeAll()
        isScanning = true
        // Scan for devices with HM-10 service
        centralManager.scanForPeripherals(withServices: [HM10_SERVICE_UUID], options: nil)
        
        // Stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isScanning {
                self.stopScan()
            }
        }
    }
    
    func stopScan() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func connectToDevice(_ peripheral: CBPeripheral) {
        stopScan()
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func sendData() {
        guard let characteristic = writeCharacteristic,
              let peripheral = connectedPeripheral,
              let data = textToSend.data(using: .utf8) else {
            return
        }
        
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        textToSend = "" // Clear the input field after sending
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            showError(message: "Bluetooth is powered off")
            isConnected = false
        case .resetting, .unauthorized, .unknown, .unsupported:
            showError(message: "Bluetooth is not available")
            isConnected = false
        @unknown default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectedPeripheral = peripheral
        peripheral.discoverServices([HM10_SERVICE_UUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedPeripheral = nil
        writeCharacteristic = nil
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        showError(message: "Failed to connect to device")
        isConnected = false
    }
}

// CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            showError(message: "Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == HM10_SERVICE_UUID {
                peripheral.discoverCharacteristics([HM10_CHARACTERISTIC_UUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            showError(message: "Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == HM10_CHARACTERISTIC_UUID {
                writeCharacteristic = characteristic
                // Enable notifications to receive data from HM-10
                peripheral.setNotifyValue(true, for: characteristic)
                print("Connected to HM-10 and ready to send/receive data")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error receiving data: \(error.localizedDescription)")
            return
        }
        
        if let data = characteristic.value,
           let receivedString = String(data: data, encoding: .utf8) {
            print("Received from HM-10: \(receivedString)")
            // Handle received data here
        }
    }
}

#Preview {
    ContentView()
}
