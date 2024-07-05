import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: #file)

@Observable class WirelessUartController: ScanAdvertisementsDelegate, DeviceBluetoothStateMonitoringDelegate, LinbleSetupDelegate, UartDataParserDelegate, WriteOperationDelegate {
    
    private let bluetoothCentralController: BluetoothCentralController = BluetoothCentralController()
    
    static let targetDeviceName: String = "LINBLE-Z1"
    // `BTLX` コマンドで確認できるデバイス名をここに貼り付けてください。
    
    var didChangeOperationStep: ((OperationStep) -> Void)?
    
    private(set) var deviceBluetoothState: DeviceBluetoothStateHolder
    
    private(set) var operationStep: OperationStep = OperationStep.initializing {
        didSet {
            logger.info("\(#function) didSet \(self.operationStep.toString())")
            
            didChangeOperationStep?(operationStep)
        }
    }
    
    init() {
        deviceBluetoothState = bluetoothCentralController.currentDeviceBluetoothState
        
        uartDataParser = UartDataParser(delegate: self)
    }
    
    func start() {
        logger.info("\(#function)")
        
        bluetoothCentralController.startDeviceBluetoothStateMonitoring(delegate: self)
    }
    
    var didChangeDeviceBluetoothState: ((DeviceBluetoothState) -> Void)?
    
    func bluetoothCentralController(_: BluetoothCentralController, didChangeState deviceBluetoothState: DeviceBluetoothState) {
        didChangeDeviceBluetoothState?(deviceBluetoothState)
        
        switch deviceBluetoothState {
        case DeviceBluetoothState.poweredOn:
            startScan()
        case .unauthorized, .unknown, .poweredOff:
            // NOP
            break
        }
    }
    
    private func startScan(toReconnect: Bool = false) {
        logger.info("\(#function)")
        
        if toReconnect {
            bluetoothCentralController.cancelConnection()
        }
        
        if bluetoothCentralController.isConnected {
            // 接続済みである場合、スキャンは行わせません。
            logger.warning("\(#function) ignored")
            return
        }
        
        operationStep = OperationStep.scanning
        bluetoothCentralController.scanAdvertisements(delegate: self)
    }
    
    func bluetoothCentralController(_: BluetoothCentralController, didScanAdvertisement advertisement: Advertisement) {
        guard let deviceName = advertisement.deviceName else { return }
        if deviceName != WirelessUartController.targetDeviceName {
            return
        }
        
        logger.info("\(#function) advertisement=\(String(describing: advertisement))")
        
        bluetoothCentralController.cancelScan()
        
        operationStep = OperationStep.connecting
        bluetoothCentralController.connect(target: advertisement, linbleSetupDelegate: self)
    }
    
    func bluetoothCentralController(_: BluetoothCentralController, didFailToSetupWithError error: Error) {
        logger.error("\(#function) error=\(error)")
        
        startScan(toReconnect: true)
    }
    
    func bluetoothCentralControllerDidCompleteSetup(_: BluetoothCentralController) {
        // LINBLEとの通信準備完了
        logger.info("\(#function)")
        
        uartDataParser.clear()
        
        operationStep = OperationStep.connected
    }
    
    private var uartDataParser: UartDataParser!
    
    func bluetoothCentralController(_: BluetoothCentralController, didReceiveNotification notification: NotificationEvent) {
        uartDataParser.parse(data: notification.data)
    }
    
    var receivedPacket: UartRxPacket? = nil
    
    func uartDataParserDelegate(_: UartDataParser, didParse rxPacket: UartRxPacket) {
        logger.info("\(#function) rxPacket: \(rxPacket.toString())")
        
        receivedPacket = rxPacket
    }
    
    private var txPacketDivider: TxPacketDivider? = nil
    
    func write(command: UartCommand) {
        logger.info("\(#function) \(command.toString()) \(command.toData().toHexString())")
        
        txPacketDivider = TxPacketDivider(data: command.toData(), size: 20)
        
        writeFragmentedDataList()
    }
    
    private func writeFragmentedDataList() {
        guard let txPacketDivider else { return }
        
        logger.info("\(#function) remainPacketSize=\(txPacketDivider.remain.count)")
        
        guard let chunk = txPacketDivider.next else {
            logger.info("\(#function) txPacketDivider.next == null")
            
            self.txPacketDivider = nil
            return
        }
        
        logger.info("\(#function) chunk=\(chunk.toHexString())")
        
        bluetoothCentralController.writeData(chunk: chunk, writeOperationDelegate: self)
    }
    
    func bluetoothCentralController(_: BluetoothCentralController, didWriteData data: Data) {
        // 次のデータを送信する
        writeFragmentedDataList()
    }
    
    func bluetoothCentralController(_: BluetoothCentralController, didFailToWriteWithError error: any Error) {
        logger.error("\(#function) error=\(error)")
    }
    
    func stop() {
        logger.info("\(#function)")
        
        bluetoothCentralController.stopDeviceBluetoothStateMonitoring()
        bluetoothCentralController.cancelScan()
        bluetoothCentralController.cancelConnection()
    }
}
