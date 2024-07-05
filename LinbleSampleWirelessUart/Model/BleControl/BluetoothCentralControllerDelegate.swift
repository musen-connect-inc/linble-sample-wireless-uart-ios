import Foundation

// ..端末のBluetooth状態の監視..
protocol DeviceBluetoothStateMonitoringDelegate: AnyObject {
    func bluetoothCentralController(_: BluetoothCentralController, didChangeState deviceBluetoothState: DeviceBluetoothState)
}


// ..スキャン..
protocol ScanAdvertisementsDelegate: AnyObject {
    func bluetoothCentralController(_: BluetoothCentralController, didScanAdvertisement advertisement: Advertisement)
}


// ..GATT操作..

protocol LinbleSetupDelegate: AnyObject {
    func bluetoothCentralController(_: BluetoothCentralController, didFailToSetupWithError error: Error)
    func bluetoothCentralControllerDidCompleteSetup(_: BluetoothCentralController)
    func bluetoothCentralController(_: BluetoothCentralController, didReceiveNotification notification: NotificationEvent)
}

protocol WriteOperationDelegate: AnyObject {
    func bluetoothCentralController(_: BluetoothCentralController, didFailToWriteWithError error: Error)
    func bluetoothCentralController(_: BluetoothCentralController, didWriteData data: Data)
}
