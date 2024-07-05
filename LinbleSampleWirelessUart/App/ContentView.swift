import SwiftUI
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: #file)

struct ContentView: View {
    @State private var wirelessUartController = WirelessUartController()
    
    @State private var toast: Toast? = nil
    
    var body: some View {
        let deviceBluetoothState = wirelessUartController.deviceBluetoothState.value
        let operationStep = wirelessUartController.operationStep
        let receivedPacket = wirelessUartController.receivedPacket
        
        return VStack(spacing: 28) {
            Text("端末のBluetooth状態: \(deviceBluetoothState.toText())")
                .foregroundStyle(deviceBluetoothState == .poweredOn ? .blue : .red)
            
            Text(operationStep.toText())
                .foregroundStyle(operationStep == .connected ? .blue : .red)
            
            let commandButtonDisabled = operationStep != .connected
            
            ForEach(commandList, id: \.0) { commandName, command in
                Button(action: {
                    sendCommand(uartCommand: command)
                }) {
                    Text(commandName)
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .foregroundStyle(Color.white)
                .background(Color.blue)
                .cornerRadius(.infinity)
                .disabled(commandButtonDisabled)
                .opacity(commandButtonDisabled ? 0.5 : 1.0)
                .padding(.horizontal, 30)
            }
        }.onAppear {
            wirelessUartController.start()
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
            wirelessUartController.stop()
        }
        .toastView(toast: $toast)
        .onChange(of: deviceBluetoothState) {
            self.bluetoothUnauthorized = deviceBluetoothState == .unauthorized
        }
        .onChange(of: receivedPacket) {
            guard let packet = receivedPacket else {
                return
            }
            
            toast = Toast(message: "受信: \(packet.toString())")
        }
        .alert("設定アプリからBluetooth権限の許可を行ってください", isPresented: $bluetoothUnauthorized) {
            Button(action: {
                exit(0)
            }) {
                Text("OK")
            }
        } message: {
            Text("OKを押すとアプリを終了します。")
        }
    }
    
    private let commandList: [(String, UartCommand)] = [
        ("導通テスト", UartCommandConnectionTest()),
        ("レジスタ値アクセス.取得", UartCommandRegisterRead(registerNumber: RegisterNumber(value: 1))),
        ("レジスタ値アクセス.設定", UartCommandRegisterWrite(registerNumber: RegisterNumber(value: 1), hexdecimal: UInt8(0xAB))),
        ("ホストマイコンバージョン確認", UartCommandVersionRead()),
        ("センササンプリング実行要求", UartCommandSensorSampling(duration: DurationIntervalSeconds(value: 5))),
        ("デバイス名.取得", UartCommandDeviceNameRead()),
        ("デバイス名.設定", UartCommandDeviceNameWrite(name: AsciiString(value: "Sample-UartController-002"))),
    ]
    
    private func sendCommand(uartCommand: UartCommand) {
        toast = Toast(message: "送信: \(uartCommand.toString())")
        wirelessUartController.write(command: uartCommand)
    }
    
    @State private var bluetoothUnauthorized: Bool = false
}

extension DeviceBluetoothState {
    func toText() -> String {
        return switch self {
        case .unknown:
            "不明"
        case .poweredOff:
            "OFF"
        case .poweredOn:
            "ON"
        case .unauthorized:
            "権限がありません"
        }
    }
}

extension OperationStep {
    func toText() -> String {
        return switch self {
        case .scanning:
            "\(WirelessUartController.targetDeviceName)を\(self.toString())"
        case .connecting, .connected:
            "\(WirelessUartController.targetDeviceName)と\(self.toString())"
        default:
            self.toString()
        }
    }
}

#Preview {
    ContentView()
}
