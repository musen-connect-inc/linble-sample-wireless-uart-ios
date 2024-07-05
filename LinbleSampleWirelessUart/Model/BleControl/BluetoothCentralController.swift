import Foundation
import CoreBluetooth
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: #file)

@Observable
class DeviceBluetoothStateHolder {
    var value = DeviceBluetoothState.unknown {
        didSet {
            let valueString = "\(value)"
            logger.info("\(#function) \(valueString)")
        }
    }
}

class BluetoothCentralController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private(set) var centralManager: CBCentralManager!
    
    private(set) var peripheral: CBPeripheral? = nil
    
    var isConnected: Bool {
        get {
            dataFromPeripheral?.isNotifying ?? false
        }
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    static let operationTimeoutSec: Double = 5.0
    
    private var linbleSetupTimeoutDetector: Timer? = nil
    
    // ..端末のBluetooth状態の監視..
    private weak var deviceBluetoothStateMonitoringDelegate: DeviceBluetoothStateMonitoringDelegate? = nil
    
    private(set) var currentDeviceBluetoothState: DeviceBluetoothStateHolder = DeviceBluetoothStateHolder()
    
    func startDeviceBluetoothStateMonitoring (delegate: DeviceBluetoothStateMonitoringDelegate) {
        deviceBluetoothStateMonitoringDelegate = delegate
        
        deviceBluetoothStateMonitoringDelegate?.bluetoothCentralController(self, didChangeState: currentDeviceBluetoothState.value)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.info("\(#function) state=\(central.state.rawValue)")
        
        guard let newDeviceBluetoothState: DeviceBluetoothState = {
            switch central.state {
            case .poweredOn:
                return DeviceBluetoothState.poweredOn
            case .resetting, .unsupported, .poweredOff:
                /*
                 iOSのBLEでは、端末のBluetooth状態がオフになった場合、
                 処理中のオブジェクトからはエラー通知を起こしてくれません。
                 手動で状態を巻き戻す必要があります。
                 */
                
                clearPeripheral()
                return DeviceBluetoothState.poweredOff
                
            case .unauthorized:
                return DeviceBluetoothState.unauthorized
                
            case .unknown:
                clearPeripheral()
                return DeviceBluetoothState.unknown
            @unknown default:
                return nil
            }
        }() else { return }
        
        if currentDeviceBluetoothState.value == newDeviceBluetoothState {
            return
        }
        
        currentDeviceBluetoothState.value = newDeviceBluetoothState
        
        deviceBluetoothStateMonitoringDelegate?.bluetoothCentralController(self, didChangeState: newDeviceBluetoothState)
    }
    
    func stopDeviceBluetoothStateMonitoring() {
        deviceBluetoothStateMonitoringDelegate = nil
    }
    
    // ..スキャン..
    
    private weak var scanAdvertisementsDelegate: ScanAdvertisementsDelegate? = nil
    
    func scanAdvertisements(delegate: ScanAdvertisementsDelegate) {
        logger.info("\(#function)")
        
        scanAdvertisementsDelegate = delegate
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        /*
         peripheral.nameから取得できるデバイス名ですが、これはOSが認識しているデバイス名のキャッシュ情報であるため、
         実際にLINBLE側がリアルタイムで発信している名前と異なる可能性があります。
         
         LINBLEの名前を頻繁に変える使い方を想定している場合、
         CBAdvertisementDataLocalNameKeyからデバイス名を取得したほうが安全です。
         */
        let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        
        logger.info("\(#function) rssi=\(RSSI) deviceName=\(String(describing: deviceName)) identifier=\(peripheral.identifier)")
        
        let advertisement = Advertisement(deviceName: deviceName, peripheral: peripheral)
        
        scanAdvertisementsDelegate?.bluetoothCentralController(self, didScanAdvertisement: advertisement)
    }
    
    func cancelScan() {
        logger.info("\(#function)")
        
        scanAdvertisementsDelegate = nil
        
        centralManager.stopScan()
    }
    
    // ..接続..
    
    private weak var linbleSetupDelegate: LinbleSetupDelegate? = nil
    
    func connect(target: Advertisement, linbleSetupDelegate: LinbleSetupDelegate) {
        logger.info("\(#function)")
        
        if writeOperationDelegate != nil {
            return
        }
        
        self.linbleSetupDelegate = linbleSetupDelegate
        
        peripheral = target.peripheral
        
        centralManager.connect(target.peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.peripheral?.delegate = self
        
        linbleSetupTimeoutDetector = Timer.scheduledTimer(withTimeInterval: BluetoothCentralController.operationTimeoutSec, repeats: false) { _ in
            self.linbleSetupDelegate?.bluetoothCentralController(self, didFailToSetupWithError: FailureGattOperationException.timeout("didConnect"))
        }
        
        let services = [Linble.linbleUartService]
        peripheral.discoverServices(services)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.info("\(#function) services=\(String(describing: peripheral.services))")
        
        linbleSetupTimeoutDetector?.invalidate()
        
        if let error {
            logger.error("\(#function) error=\(error)")
            linbleSetupDelegate?.bluetoothCentralController(self, didFailToSetupWithError: FailureGattOperationException.response("discoverServices"))
            return
        }
        
        guard let linbleUartService = peripheral.services?.first(where: {
            $0.uuid == Linble.linbleUartService
        }) else {
            logger.error("\(#function) linbleUartService == nil")
            linbleSetupDelegate?.bluetoothCentralController(self, didFailToSetupWithError: BluetoothConnectionError.UnsupportedDeviceConnectedException)
            return
        }
        
        linbleSetupTimeoutDetector = Timer.scheduledTimer(withTimeInterval: BluetoothCentralController.operationTimeoutSec, repeats: false) { _ in
            self.linbleSetupDelegate?.bluetoothCentralController(self, didFailToSetupWithError: FailureGattOperationException.timeout("discoverServices"))
        }
        
        peripheral.discoverCharacteristics([Linble.dataFromPeripheral, Linble.dataToPeripheral], for: linbleUartService)
    }
    
    private var dataToPeripheral: CBCharacteristic? = nil
    private var dataFromPeripheral: CBCharacteristic? = nil
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        logger.info("\(#function) characteristics=\(String(describing: service.characteristics))")
        linbleSetupTimeoutDetector?.invalidate()
        
        if let error {
            logger.error("\(#function) error=\(error)")
            linbleSetupDelegate?.bluetoothCentralController(self, didFailToSetupWithError: FailureGattOperationException.response("discoverCharacteristics"))
            return
        }
        
        dataFromPeripheral = service.characteristics?.first(where: { $0.uuid == Linble.dataFromPeripheral })
        dataToPeripheral = service.characteristics?.first(where: { $0.uuid == Linble.dataToPeripheral })
        
        guard let dataFromPeripheral, let _ = dataToPeripheral else {
            logger.error("\(#function) dataFromPeripheral == nil ? \(self.dataFromPeripheral == nil) || dataToPeripheral == nil ? \(self.dataToPeripheral == nil)")
            linbleSetupDelegate?.bluetoothCentralController(self, didFailToSetupWithError: BluetoothConnectionError.UnsupportedDeviceConnectedException)
            return
        }
        
        linbleSetupTimeoutDetector = Timer.scheduledTimer(withTimeInterval: BluetoothCentralController.operationTimeoutSec, repeats: false) { _ in
            self.linbleSetupDelegate?.bluetoothCentralController(self, didFailToSetupWithError: FailureGattOperationException.timeout("setNotifyValue"))
        }
        
        peripheral.setNotifyValue(true, for: dataFromPeripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        logger.info("\(#function) characteristic=\(characteristic)")
        
        linbleSetupTimeoutDetector?.invalidate()
        
        if let error {
            logger.error("\(#function) error=\(error)")
            linbleSetupDelegate?.bluetoothCentralController(self, didFailToSetupWithError: FailureGattOperationException.response("writeDescriptor"))
            return
        }
        
        logger.info("\(#function) maximumWriteValueLength=\(peripheral.maximumWriteValueLength(for: .withoutResponse))")
        
        linbleSetupDelegate?.bluetoothCentralControllerDidCompleteSetup(self)
    }
    
    private weak var writeOperationDelegate: WriteOperationDelegate? = nil
    
    private var pendingChunk: Data? = nil
    
    func writeData(chunk: Data, writeOperationDelegate: WriteOperationDelegate) {
        logger.info("\(#function)")
        
        self.writeOperationDelegate = writeOperationDelegate
        
        guard let peripheral, let dataToPeripheral else {
            writeOperationDelegate.bluetoothCentralController(self, didFailToWriteWithError: BluetoothConnectionError.DisconnectedAfterOnlineException)
            return
        }
        
        let canSendWriteWithoutResponse = peripheral.canSendWriteWithoutResponse
        logger.info("\(#function) canSendWriteWithoutResponse=\(canSendWriteWithoutResponse)")
        if !canSendWriteWithoutResponse {
            pendingChunk = chunk
            return
        }
        
        peripheral.writeValue(chunk, for: dataToPeripheral, type: .withoutResponse)
        
        pendingChunk = nil
        
        writeOperationDelegate.bluetoothCentralController(self, didWriteData: chunk)
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        logger.info("\(#function)")
        
        guard let pendingChunk, let writeOperationDelegate else {
            return
        }
        
        writeData(chunk: pendingChunk, writeOperationDelegate: writeOperationDelegate)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = characteristic.value
        logger.info("\(#function) data=\(String(describing: data?.toHexString()))")
        
        linbleSetupTimeoutDetector?.invalidate()
        
        if let error {
            logger.error("\(#function) error=\(error)")
            return
        }
        
        if let data {
            linbleSetupDelegate?.bluetoothCentralController(self, didReceiveNotification: NotificationEvent(data: data))
        }
    }
    
    func cancelConnection() {
        logger.info("\(#function) peripheral == nil ? \(self.peripheral == nil)")
        
        if let peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        
        clearPeripheral()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("\(#function) peripheral=\(peripheral) error=\(error)")
        
        clearPeripheral()
        
        linbleSetupDelegate?.bluetoothCentralController(self, didFailToSetupWithError: BluetoothConnectionError.DisconnectedAfterOnlineException)
    }
    
    private func clearPeripheral() {
        peripheral = nil
        
        dataToPeripheral = nil
        dataFromPeripheral = nil
        
        pendingChunk = nil
        writeOperationDelegate = nil
    }
}
