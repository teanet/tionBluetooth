//
//  Tion.swift
//  __cbtest
//
//  Created by teanet on 09.05.2023.
//

import Foundation

typealias PendingUpdate = (Data) -> Tion?

class Tion {
	var mode: UInt8 = 0
	var isOn: UInt8 = 0
	var sound: UInt8 = 0
	var light: UInt8 = 0
	var heater: UInt8 = 0
	var fanSpeed: UInt8 = 0
	var heaterTemp: UInt8 = 0
	fileprivate(set) var in_temp: UInt8 = 0
	fileprivate(set) var out_temp: UInt8 = 0

	var encode_state: UInt8 {
		self.isOn | self.sound << 1 | self.light << 2 | self.heater << 3
	}
}

struct TionUpdate {
	var mode: UInt8?
	var isOn: UInt8?
	var heater: UInt8?
	var fanSpeed: UInt8?
	var heaterTemp: UInt8?
}

extension Tion {

	func apply(update: TionUpdate) {
		update.mode.map { self.mode = $0 }
		update.isOn.map { self.isOn = $0 }
		update.heater.map { self.heater = $0 }
		update.fanSpeed.map { self.fanSpeed = $0 }
		update.heaterTemp.map { self.heaterTemp = $0 }
	}

	func update(with data: Data) {
		let response = Data(data[15..<data.count])
		self.mode = response[2]
		self.heaterTemp = response[3]
		self.fanSpeed = response[4]
		self.in_temp = self.decode_temperature(response[5])
		self.out_temp = self.decode_temperature(response[6])
		self.isOn = response[0] & 1
		self.sound = response[0] >> 1 & 1
		self.light = response[0] >> 2 & 1
		self.heater = response[0] >> 4 & 1
	}

	func decode_temperature(_ response: UInt8) -> UInt8 {
		//		let _filter_remain = int.from_bytes(response[17:20], byteorder='little', signed=False) / 86400
		print("decode_temperature>>>>>\(response)")
		return response
	}

}
