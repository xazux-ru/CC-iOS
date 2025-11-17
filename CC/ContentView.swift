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
    @State private var maxSpeed: Double = 500 // Default max speed
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Section - Controls and Status
                VStack(spacing: 20) {
                    Text("Cart Controller")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Bluetooth Status, Device Selection, and Disconnect in one line
                    HStack {
                        // Connection Status
                        HStack {
                            Circle()
                                .fill(bluetoothManager.isConnected ? .green : .red)
                                .frame(width: 10, height: 10)
                            Text(bluetoothManager.isConnected ? "Connected" : "Disconnected")
                                .foregroundColor(bluetoothManager.isConnected ? .green : .red)
                        }
                        
                        Spacer()
                        
                        // Device Selection with simple Menu - Always centered
                        HStack {
                            if bluetoothManager.isScanning {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 4)
                            }
                            
                            Menu {
                                // Devices List - Directly in the main menu
                                if bluetoothManager.discoveredDevices.isEmpty {
                                    Button("No devices found") { }
                                        .disabled(true)
                                } else {
                                    ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                                        Button(action: {
                                            bluetoothManager.connectToDevice(device)
                                        }) {
                                            HStack {
                                                Text(device.name ?? "Unknown Device")
                                                Spacer()
                                                if bluetoothManager.connectedPeripheral?.identifier == device.identifier {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                // Scan/Stop Scan Button at bottom
                                Button(action: {
                                    if bluetoothManager.isScanning {
                                        bluetoothManager.stopScan()
                                    } else {
                                        bluetoothManager.startScan()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: bluetoothManager.isScanning ? "stop.circle" : "arrow.clockwise")
                                        Text(bluetoothManager.isScanning ? "Stop Scan" : "Scan for Devices")
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                    if let connectedDevice = bluetoothManager.connectedPeripheral {
                                        Text(connectedDevice.name ?? "Connected Device")
                                            .lineLimit(1)
                                    } else {
                                        Text("Select Device")
                                    }
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                        
                        Spacer()
                        
                        // Disconnect Button - Only show when connected
                        if bluetoothManager.isConnected {
                            Button("Disconnect") {
                                bluetoothManager.disconnect()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .font(.system(size: 14, weight: .semibold))
                        } else {
                            // Invisible spacer to maintain balance when disconnected
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 80, height: 1)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Max Speed Slider
                    VStack(spacing: 10) {
                        Text("Max Motor Speed: \(Int(maxSpeed))")
                            .font(.headline)
                        
                        HStack {
                            Text("10")
                            Slider(value: $maxSpeed, in: 10...1000, step: 10)
                                .onChange(of: maxSpeed) { oldValue, newValue in
                                    bluetoothManager.maxSpeed = Int(newValue)
                                }
                            Text("1000")
                        }
                        
                        HStack {
                            Button("25%") { maxSpeed = 250 }
                                .padding(6)
                                .background(Color.blue.opacity(0.3))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                                .contentShape(Rectangle())
                            
                            Button("50%") { maxSpeed = 500 }
                                .padding(6)
                                .background(Color.blue.opacity(0.3))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                                .contentShape(Rectangle())
                            
                            Button("75%") { maxSpeed = 750 }
                                .padding(6)
                                .background(Color.blue.opacity(0.3))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                                .contentShape(Rectangle())
                            
                            Button("100%") { maxSpeed = 1000 }
                                .padding(6)
                                .background(Color.blue.opacity(0.3))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                                .contentShape(Rectangle())
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Control Buttons Row
                    VStack(spacing: 10) {
                        HStack(spacing: 20) {
                            // Left Button (-1) - передает -1 сразу при нажатии
                            Button(action: {
                                bluetoothManager.sendThirdParameter(-1)
                            }) {
                                Text("DOWN")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(height: 50)
                            .background(Color.orange.opacity(0.7))
                            .cornerRadius(10)
                            
                            // Center Button (Stop) - передает 0 сразу при нажатии
                            Button(action: {
                                bluetoothManager.sendThirdParameter(0)
                            }) {
                                Text("STOP")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(height: 50)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(10)
                            
                            // Right Button (+1) - передает +1 сразу при нажатии
                            Button(action: {
                                bluetoothManager.sendThirdParameter(1)
                            }) {
                                Text("UP")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(height: 50)
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(height: geometry.size.height * 0.5) // Верхняя секция занимает 50% экрана
                
                // Bottom Section - Joystick (50% of screen height) привязан к низу
                VStack(spacing: 10) {
                    JoystickView(
                        bluetoothManager: bluetoothManager,
                        maxSpeed: Int(maxSpeed),
                        screenWidth: geometry.size.width,
                        containerHeight: geometry.size.height * 0.5
                    )
                    .frame(height: geometry.size.height * 0.5 - 50) // Account for title and spacing
                }
                .frame(height: geometry.size.height * 0.5)
                .padding()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .alert("Bluetooth Error", isPresented: $bluetoothManager.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(bluetoothManager.errorMessage)
        }
        .onAppear {
            bluetoothManager.maxSpeed = Int(maxSpeed)
        }
    }
}

// Updated Joystick View with dynamic sizing and bottom alignment
struct JoystickView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    let maxSpeed: Int
    let screenWidth: CGFloat
    let containerHeight: CGFloat
    
    @State private var dragLocation: CGPoint = .zero
    @State private var isDragging = false
    
    private var baseSize: CGFloat {
        // Use the smaller dimension to ensure the joystick fits
        min(screenWidth * 0.8, containerHeight * 0.8)
    }
    
    private var joystickSize: CGFloat {
        baseSize * 0.3
    }
    
    var body: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: baseSize, height: baseSize)
            
            // Center indicator
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: baseSize * 0.05, height: baseSize * 0.05)
            
            // Direction indicators
            VStack {
                Text("▲")
                    .font(.system(size: baseSize * 0.08))
                    .foregroundColor(.gray)
                Spacer()
                Text("▼")
                    .font(.system(size: baseSize * 0.08))
                    .foregroundColor(.gray)
            }
            .frame(height: baseSize)
            
            HStack {
                Text("◀")
                    .font(.system(size: baseSize * 0.08))
                    .foregroundColor(.gray)
                Spacer()
                Text("▶")
                    .font(.system(size: baseSize * 0.08))
                    .foregroundColor(.gray)
            }
            .frame(width: baseSize)
            
            // Joystick handle
            Circle()
                .fill(isDragging ? Color.blue : Color.blue.opacity(0.7))
                .frame(width: joystickSize, height: joystickSize)
                .position(
                    x: baseSize / 2 + dragLocation.x,
                    y: baseSize / 2 + dragLocation.y
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            
                            // Calculate bounded position
                            let maxDistance = (baseSize - joystickSize) / 2
                            let translation = CGSize(
                                width: max(-maxDistance, min(maxDistance, value.translation.width)),
                                height: max(-maxDistance, min(maxDistance, value.translation.height))
                            )
                            
                            dragLocation = CGPoint(x: translation.width, y: translation.height)
                            
                            // Calculate motor speeds
                            let normalizedX = Double(translation.width / maxDistance)
                            let normalizedY = Double(-translation.height / maxDistance) // Invert Y for intuitive control
                            
                            // Calculate left and right motor speeds using tank steering
                            let (leftSpeed, rightSpeed) = calculateTankSpeeds(x: normalizedX, y: normalizedY)
                            
                            // Update motor speeds directly and send immediately
                            bluetoothManager.updateMotorSpeeds(left: leftSpeed, right: rightSpeed)
                        }
                        .onEnded { _ in
                            isDragging = false
                            withAnimation(.spring()) {
                                dragLocation = .zero
                            }
                            
                            // Reset motor speeds and send stop command immediately
                            bluetoothManager.sendStopCommand()
                        }
                )
        }
        .frame(width: baseSize, height: baseSize)
        .frame(maxHeight: .infinity, alignment: .bottom) // Привязка к низу контейнера
        .padding(.bottom, 20) // Отступ от нижнего края
    }
    
    private func calculateTankSpeeds(x: Double, y: Double) -> (Int, Int) {
        // Tank steering calculation
        // y controls forward/backward movement
        // x controls turning (left/right)
        
        let baseSpeed = y * Double(maxSpeed) // Use maxSpeed from slider
        
        // Standard tank steering:
        let turnFactor = x * Double(maxSpeed)
        
        // Right turn: left motor faster, right motor slower
        // Left turn: right motor faster, left motor slower
        var leftSpeed = baseSpeed + turnFactor
        var rightSpeed = baseSpeed - turnFactor
        
        // Clamp values to -maxSpeed to maxSpeed range
        leftSpeed = max(-Double(maxSpeed), min(Double(maxSpeed), leftSpeed))
        rightSpeed = max(-Double(maxSpeed), min(Double(maxSpeed), rightSpeed))
        
        return (Int(leftSpeed), Int(rightSpeed))
    }
}

// Bluetooth Manager (остается без изменений)
class BluetoothManager: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    
    // HM-10 Service and Characteristic UUIDs
    let HM10_SERVICE_UUID = CBUUID(string: "FFE0")
    let HM10_CHARACTERISTIC_UUID = CBUUID(string: "FFE1")
    
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var isConnected = false
    @Published var isScanning = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var leftMotorSpeed = 0
    @Published var rightMotorSpeed = 0
    @Published var lastSentData = ""
    @Published var updateCount = 0
    @Published var maxSpeed = 500
    @Published var bluetoothState: String = "Unknown"
    @Published var debugLog: String = ""
    @Published var connectedPeripheral: CBPeripheral? = nil
    
    private var writeCharacteristic: CBCharacteristic?
    
    // Throttling properties
    private var lastSendTime: Date = Date()
    private let sendInterval: TimeInterval = 0.05
    private var lastLeftSpeed = 0
    private var lastRightSpeed = 0
    
    // Device tracking to prevent duplicates
    private var discoveredDeviceIds: Set<UUID> = []
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    func startScan() {
        guard centralManager.state == .poweredOn else {
            showError(message: "Bluetooth is not available. State: \(bluetoothState)")
            return
        }
        
        // Clear previous devices
        DispatchQueue.main.async {
            self.discoveredDevices.removeAll()
            self.discoveredDeviceIds.removeAll()
            self.isScanning = true
            self.debugLog = "Scanning started..."
        }
        
        // Scan for all devices
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        // Stop scanning after 15 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if self.isScanning {
                self.stopScan()
            }
        }
    }
    
    func stopScan() {
        centralManager.stopScan()
        DispatchQueue.main.async {
            self.isScanning = false
            self.debugLog = "Scanning stopped. Found \(self.discoveredDevices.count) devices."
        }
    }
    
    func connectToDevice(_ peripheral: CBPeripheral) {
        stopScan()
        peripheral.delegate = self
        connectedPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func updateMotorSpeeds(left: Int, right: Int) {
        DispatchQueue.main.async {
            self.leftMotorSpeed = left
            self.rightMotorSpeed = right
        }
        sendJoystickData(thirdParameter: 0) // По умолчанию третий параметр 0 при движении джойстика
    }
    
    func sendThirdParameter(_ value: Int) {
        // Передаем текущие скорости моторов и указанное значение третьего параметра
        sendDataWithThirdParameter(value)
    }
    
    func sendStopCommand() {
        DispatchQueue.main.async {
            self.leftMotorSpeed = 0
            self.rightMotorSpeed = 0
        }
        sendStopDataImmediately()
    }
    
    func disconnect() {
        sendStopCommand()
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            DispatchQueue.main.async {
                self.connectedPeripheral = nil
            }
        }
    }
    
    private func sendJoystickData(thirdParameter: Int) {
        let now = Date()
        if now.timeIntervalSince(lastSendTime) < sendInterval {
            return
        }
        
        guard let characteristic = writeCharacteristic,
              let peripheral = connectedPeripheral else {
            return
        }
        
        if leftMotorSpeed == lastLeftSpeed && rightMotorSpeed == lastRightSpeed {
            return
        }
        
        let dataString = String(format: "%d:%d:%d\n", leftMotorSpeed, rightMotorSpeed, thirdParameter)
        
        if let data = dataString.data(using: .utf8) {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            
            DispatchQueue.main.async {
                self.lastSentData = dataString.trimmingCharacters(in: .whitespacesAndNewlines)
                self.updateCount += 1
                self.lastLeftSpeed = self.leftMotorSpeed
                self.lastRightSpeed = self.rightMotorSpeed
            }
            
            lastSendTime = now
        }
    }
    
    private func sendDataWithThirdParameter(_ thirdParameter: Int) {
        guard let characteristic = writeCharacteristic,
              let peripheral = connectedPeripheral else {
            return
        }
        
        let dataString = String(format: "%d:%d:%d\n", leftMotorSpeed, rightMotorSpeed, thirdParameter)
        
        if let data = dataString.data(using: .utf8) {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            
            DispatchQueue.main.async {
                self.lastSentData = dataString.trimmingCharacters(in: .whitespacesAndNewlines)
                self.updateCount += 1
            }
            
            lastSendTime = Date()
        }
    }
    
    private func sendStopDataImmediately() {
        guard let characteristic = writeCharacteristic,
              let peripheral = connectedPeripheral else {
            return
        }
        
        let stopString = "0:0:0\n"
        if let data = stopString.data(using: .utf8) {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            
            DispatchQueue.main.async {
                self.lastSentData = stopString.trimmingCharacters(in: .whitespacesAndNewlines)
                self.updateCount += 1
                self.lastLeftSpeed = 0
                self.lastRightSpeed = 0
            }
            
            lastSendTime = Date()
        }
    }
    
    private func showError(message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
    
    private func updateDebugLog(_ message: String) {
        DispatchQueue.main.async {
            self.debugLog = message
        }
    }
    
    // Add device to discovered list with proper main thread handling
    private func addDiscoveredDevice(_ peripheral: CBPeripheral) {
        // Check if we already have this device
        guard !discoveredDeviceIds.contains(peripheral.identifier) else {
            return
        }
        
        // Add to tracking set
        discoveredDeviceIds.insert(peripheral.identifier)
        
        // Update on main thread
        DispatchQueue.main.async {
            self.discoveredDevices.append(peripheral)
            self.debugLog = "\(peripheral.name ?? "Unknown") - \(self.discoveredDevices.count) total"
        }
    }
}

// CBCentralManagerDelegate (остается без изменений)
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            DispatchQueue.main.async {
                self.bluetoothState = "Powered On"
            }
        case .poweredOff:
            DispatchQueue.main.async {
                self.bluetoothState = "Powered Off"
                self.isConnected = false
                self.connectedPeripheral = nil
            }
            showError(message: "Bluetooth is powered off")
        case .resetting:
            DispatchQueue.main.async {
                self.bluetoothState = "Resetting"
            }
        case .unauthorized:
            DispatchQueue.main.async {
                self.bluetoothState = "Unauthorized"
            }
            showError(message: "Bluetooth access is not authorized")
        case .unknown:
            DispatchQueue.main.async {
                self.bluetoothState = "Unknown"
            }
        case .unsupported:
            DispatchQueue.main.async {
                self.bluetoothState = "Unsupported"
            }
            showError(message: "Bluetooth is not supported on this device")
        @unknown default:
            DispatchQueue.main.async {
                self.bluetoothState = "Unknown"
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Use the new method to add device with proper main thread handling
        addDiscoveredDevice(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectedPeripheral = peripheral
        }
        
        peripheral.discoverServices([HM10_SERVICE_UUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedPeripheral = nil
            self.writeCharacteristic = nil
            self.leftMotorSpeed = 0
            self.rightMotorSpeed = 0
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        showError(message: "Failed to connect to device: \(error?.localizedDescription ?? "Unknown error")")
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedPeripheral = nil
        }
    }
}

// CBPeripheralDelegate (остается без изменений)
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            showError(message: "Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            showError(message: "No services found")
            return
        }
        for service in services {
            peripheral.discoverCharacteristics([HM10_CHARACTERISTIC_UUID], for: service)
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
                self.writeCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.sendStopCommand()
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            return
        }
    }
}

#Preview {
    ContentView()
}
