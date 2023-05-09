//
//  ViewController.swift
//  __cbtest
//
//  Created by teanet on 09.05.2023.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController {

	let bluetoothManager = TionBluetoothManager()

	override func viewDidLoad() {
		super.viewDidLoad()

		bluetoothManager.start(TionUpdate(fanSpeed: 2))

//		DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: {
//
//			self.bluetoothManager.start(TionUpdate(fanSpeed: 2))
//		})

//		DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: {
//
//			self.bluetoothManager.start(TionUpdate(fanSpeed: 2))
//		})
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	


}
