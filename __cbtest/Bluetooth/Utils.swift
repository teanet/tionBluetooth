//
//  Utils.swift
//  __cbtest
//
//  Created by teanet on 09.05.2023.
//

import Foundation

class U {

	func command_getStatus() -> Data {
		var data: [UInt8] = [
			U.SINGLE_PACKET_ID,
			0x10,
			0x00,
			U.MAGIC_NUMBER,
			0xa1,
		]
		data += self.REQUEST_PARAMS()
		data += random4()
		data += random4()
		data += self.CRC()
		return Data(data)
	}

	private let command_PAIR: UInt8 = 5
	private let command_REQUEST_PARAMS: UInt8 = 1
	private let command_SET_PARAMS: UInt8 = 2
	private let command_prefix: UInt8 = 61
	private let command_suffix: UInt8 = 90
	static let SINGLE_PACKET_ID: UInt8 = 0x80
	static let MAGIC_NUMBER: UInt8 = 0x3a  //# 58
	static let FIRST_PACKET_ID: UInt8 = 0x00
	static let MIDDLE_PACKET_ID: UInt8 = 0x40
	static let END_PACKET_ID: UInt8 = 0xc0

	func dataForState(_ state: Tion) -> Data {
		let sb: UInt8 = 0x00
		let tb: UInt8 = state.heaterTemp > 0 || state.fanSpeed > 0 ? 0x02 : 0x01
		let lb: [UInt8] = [0x60, 0x00]
		var data: [UInt8] = [0x00, 0x1e, 0x00, U.MAGIC_NUMBER, self.random()]
		data += self.SET_PARAMS() + self.random4() + self.random4()
		data += [state.encode_state, sb, tb, state.heaterTemp, state.fanSpeed]
		data += __presets() + lb + [0x00] + CRC()

		return Data(data)
	}

	func requests(from data: Data) -> [Data] {
		var data = Data(data)
		_ = data.popFirst()
		if data.count < 20 {
			data.insert(U.SINGLE_PACKET_ID, at: 0)
			return [data]
		}

		let packetSize = 19
		let count = Int(ceil(Double(data.count) / Double(packetSize)))
		var datas = [Data]()

		let q = Data(data)
		for i in 0..<count {
			if i == count - 1 {
				var dataChunk = Data(q[i*packetSize..<data.count])
				dataChunk.insert(U.END_PACKET_ID, at: 0)
				datas.append(dataChunk)
			} else if i == 0 {
				var dataChunk = Data(q[i*packetSize..<(i + 1) * packetSize])
				dataChunk.insert(U.FIRST_PACKET_ID, at: 0)
				datas.append(dataChunk)
			} else {
				var dataChunk = Data(q[i*packetSize..<(i + 1) * packetSize])
				dataChunk.insert(U.MIDDLE_PACKET_ID, at: 0)
				datas.append(dataChunk)
			}
		}
		return datas
	}

	private func random4() -> [UInt8] {
		[self.random(), self.random(), self.random(), self.random()]
	}

	private func random() -> UInt8 {
		UInt8.random(in: 0..<0xFF)
	}

	private func CRC() -> [UInt8] {
		return [0xbb, 0xaa]  // 0x32 0x32
	}
	private func REQUEST_PARAMS() -> [UInt8] {
		return [50, 50]  // 0x32 0x32
	}
	private func SET_PARAMS() -> [UInt8] {
		return [48, 50] //  # 0x30 0x32
	}
	private func __presets() -> [UInt8] {
		return [0x0a, 0x14, 0x19, 0x02, 0x04, 0x06]
	}

}
