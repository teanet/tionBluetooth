import Foundation
import CoreBluetooth

class TionBluetoothManager: NSObject, CBCentralManagerDelegate {
	private let cm = CBCentralManager()
	private var delegates = [CBPeripheral: PeripheralDelegate]()

	enum Constants {
		static let deivceUUID = CBUUID(string: "98F00001-3788-83EA-453E-F52244709DDB")
	}

	let tion = Tion()

	private var isStarted = false
	private var update: TionUpdate?

	override init() {
		super.init()
		self.cm.delegate = self
	}

	func start(_ update: TionUpdate?) {
		self.stop()
		self.update = update
		self.isStarted = true
		self.startIfNeeded()
	}

	private func stop() {
		self.isStarted = false
		self.cm.stopScan()
		for p in delegates.keys {
			p.delegate = nil
			self.cm.cancelPeripheralConnection(p)
		}
		self.delegates.removeAll()
	}

	func startIfNeeded() {
		guard self.isStarted else { return }
		if self.cm.state == .poweredOn, !self.cm.isScanning {
			print(">>>>>scanForPeripherals \(self.cm.isScanning)")
			cm.scanForPeripherals(withServices: [
				Constants.deivceUUID,
			])
		}
	}

	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		print("centralManagerDidUpdateState>>>>>\(central.state.rawValue)")
		self.startIfNeeded()
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		print("didDisconnectPeripheral>>>>>\(peripheral) \(String(describing: error))")
		self.delegates.removeValue(forKey: peripheral)
	}

	func centralManager(
		_ central: CBCentralManager,
		didDiscover peripheral: CBPeripheral,
		advertisementData: [String : Any],
		rssi RSSI: NSNumber
	) {
		//		print(">>>>>\(peripheral.name)")
		//		if peripheral.name == "RFS-KMC004", ppp.isEmpty {
		//			ppp.insert(peripheral)
		//			peripheral.delegate = self
		//			central.cancelPeripheralConnection(peripheral)
		//			central.connect(peripheral)
		//			print("didDiscover>>>>>\(peripheral) \(advertisementData)")
		//		}

		//		if peripheral.name == "Breezer 4S" {
		//			print(">>>>>\(peripheral)")
		//		}

		if delegates[peripheral] == nil {

			let delegate = PeripheralDelegate(peripheral: peripheral)
			delegate.completion = {
				central.cancelPeripheralConnection(peripheral)
			}
			delegate.onUpdate = { data -> Tion? in
				self.tion.update(with: data)

				if let update = self.update {
					self.tion.apply(update: update)
					self.update = nil
					return self.tion
				} else {
					return nil
				}
			}
			self.delegates[peripheral] = delegate

			central.cancelPeripheralConnection(peripheral)
			central.connect(peripheral)
			print("didDiscover>>>>>\(peripheral) \(advertisementData)")
			central.stopScan()
		}
	}

	func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
		print("willRestoreState>>>>>\(dict)")
	}

	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		print("didConnect>>>>>\(String(describing: peripheral.name))")
		peripheral.discoverServices(nil)
		print("discoverServices>>>>>")
	}

	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		print("didFailToConnect>>>>>\(String(describing: error))")
	}
}
