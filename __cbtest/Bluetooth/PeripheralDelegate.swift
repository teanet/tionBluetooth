//
//  PeripheralDelegate.swift
//  __cbtest
//
//  Created by teanet on 09.05.2023.
//

import Foundation
import CoreBluetooth

class PeripheralDelegate: NSObject, CBPeripheralDelegate {

	private var write: CBCharacteristic?
	private var notify: CBCharacteristic?
	private var data = Data()
	private var services = Set<CBService>()
	private var isCollectState = false
	private var have_breezer_state = false
	private var have_full_package = false
	private var got_new_sequence = false

	let peripheral: CBPeripheral
	let utlis = U()

	var onUpdate: PendingUpdate?
	var completion: (() -> Void)?

	init(peripheral: CBPeripheral) {
		self.peripheral = peripheral
		super.init()
		peripheral.delegate = self
	}

	enum Fail: Error {
		case noWrite
	}

	private var writeCompletion: (() -> Void)?
	private func writeData(_ data: Data) async throws {
		guard let write else {
			assertionFailure()
			throw Fail.noWrite
		}

		try await withCheckedThrowingContinuation { body in
			self.writeCompletion = {
				body.resume()
			}
			self.peripheral.writeValue(data, for: write, type: .withResponse)
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		print("didDiscoverCharacteristicsFor>>>>>\(String(describing: service.characteristics))")

		if let characteristics = service.characteristics {
			for c in characteristics {
				let uuid_write = "98F00002-3788-83EA-453E-F52244709DDB"
				let uuid_notify = "98F00003-3788-83EA-453E-F52244709DDB"

				if c.uuid.uuidString == uuid_write {
					self.write = c
				} else if c.uuid.uuidString == uuid_notify {
					self.notify = c
					self.isCollectState = true
					peripheral.setNotifyValue(true, for: c)
				}
				//				if c.properties.contains(.write) {
				//					peripheral.readValue(for: c)
				////					let d = self.data(with: command_PAIR)
				////					peripheral.writeValue(d, for: c, type: CBCharacteristicWriteType.withResponse)
				//				}
				//				if c.properties.contains(.notify) {
				//					peripheral.setNotifyValue(true, for: c)
				//				}
				//				if c.properties.contains(.read) {
				//					print(">>>>>\(c)")
				//				}

			}
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
		print("didModifyServices>>>>>\(invalidatedServices)")
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
		print("didUpdateNotificationStateFor>>>>>\(characteristic) \(String(describing: error))")

		if characteristic.isNotifying {
			self.collectState()
		}
	}

	private func collectState() {
		guard self.isCollectState else { return }

		have_breezer_state = false
		Task {
			try? await self.writeData(self.utlis.command_getStatus())
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		if let s = peripheral.services?.first {
			services.insert(s)
			peripheral.discoverCharacteristics(nil, for: s)
		}
		print(">>>>>\(String(describing: peripheral.services))")
	}

	func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		print("didWriteValueFor>>>>>\(characteristic) \(String(describing: error))")

		self.writeCompletion?()
		self.writeCompletion = nil
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		print("didUpdateValueFor>>>>>\(characteristic) \(String(describing: error))")
		self.handlePeripheralData(characteristic.value)
	}

	private func handlePeripheralData(_ data: Data?) {
		guard self.isCollectState, let package = data else { return }

		if package[0] == U.FIRST_PACKET_ID || package[0] == U.SINGLE_PACKET_ID {
			self.data = package
			self.have_full_package = package[0] == U.SINGLE_PACKET_ID
			self.got_new_sequence = package[0] == U.FIRST_PACKET_ID
		} else if package[0] == U.MIDDLE_PACKET_ID {
			if !self.got_new_sequence {
				assertionFailure()
			}
			self.data += package.dropFirst()
		} else if package[0] == U.END_PACKET_ID {
			if got_new_sequence {
				self.have_full_package = true
				self.got_new_sequence = false
				self.data += package.dropFirst()
			} else {
				assertionFailure()
			}
		} else {
			assertionFailure()
		}

		if self.have_full_package {
			//					let header = self.data[0..<15]
			//					let data = self.data[15..<self.data.count - 2]
			//					let crc = self.data.suffix(2)
			self.decode(self.data)
			self.isCollectState = false
		}
	}

	private func decode(_ data: Data) {

		if let tion = self.onUpdate?(data) {
			let data = self.utlis.dataForState(tion)
			let requests = self.utlis.requests(from: data)
			Task {
				for request in requests {
					try? await writeData(request)
				}
				completion?()
			}
		} else {
			completion?()
		}

//		self.state.update(with: data)
//		print(">>>>>\(self.state)")
//
//		self.state.fanSpeed = 2
//		self.state.mode = 0
	}

}


//	func data(with command: UInt8) -> Data {
//		let data: [UInt8] = [
//			command_prefix,
//			command,
//			command == command_PAIR ? 1 : 0,
//			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//			command_suffix,
//		]
//		return Data(data)
//	}
