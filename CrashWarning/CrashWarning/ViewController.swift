//
//  ViewController.swift
//  CrashWarning
//
//  Created by Zack Noyes on 30/07/2016.
//  Copyright © 2016 Zack Noyes. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

	@IBOutlet weak var riskLabel: UILabel!
	@IBOutlet weak var causeLabel: UILabel!

	let locationManager = CLLocationManager()
	var JSONData: [[AnyObject]]! = nil

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		JSONData = parseJSON()!["data"] as! [[AnyObject]]!
		let authStatus = CLLocationManager.authorizationStatus()
		if authStatus == .NotDetermined {
			locationManager.requestWhenInUseAuthorization()
			return
		}
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
		locationManager.startUpdatingLocation()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func parseJSON() -> [String: AnyObject]? {
		let path = NSBundle.mainBundle().pathForResource("Crashes", ofType: "json")
		let data = NSData(contentsOfFile: path!)
		do {
			return try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String: AnyObject]
		} catch {
			return nil
		}
	}

	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		let newLocation = locations.last!
		var crashes: [[AnyObject]] = []
		for crash in JSONData {
			if Double(crash[16] as! String)! + 0.0025 > newLocation.coordinate.latitude && Double(crash[16] as! String)! - 0.0025 < newLocation.coordinate.latitude {
				if Double(crash[17] as! String)! + 0.0025 > newLocation.coordinate.longitude && Double(crash[17] as! String)! - 0.0025 < newLocation.coordinate.longitude {
					crashes.append(crash)
				}
			}
		}
		riskLabel.text = "\(crashes.count)"
		var causes = [String: Int]()
		for crash in crashes {
			if let _ = causes[crash[12] as! String] {
				causes[crash[12] as! String]! += 1
			} else {
				causes[crash[12] as! String] = 1
			}
		}
		var highestCause = ("", 0)
		for (key, value) in causes {
			if value >= highestCause.1 {
				highestCause = (key, value)
			}
		}
		causeLabel.text = highestCause.0
		for crash in crashes where crash[11] as! String == "Injury" || crash[11] as! String == "Fatal" {
			riskLabel.text = "\(Int(riskLabel.text!)! + 2)"
			if crash[11] as! String == "Fatal" {
				riskLabel.text = "\(Int(riskLabel.text!)! + 5)"
			}
		}
		let date = NSDate()
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components([ .Hour, .Minute, .Second], fromDate: date)
		let hour = components.hour
		let minutes = components.minute
		let minutesPastMidnight = hour*60+minutes
		var totalRisk: Double = 0
		for crash in crashes {
			let timeOfCrash = crash[10] as! String
			let hourOfCrash = Int(timeOfCrash[timeOfCrash.startIndex.advancedBy(0)...timeOfCrash.startIndex.advancedBy(1)])
			let minuteOfCrash = Int(timeOfCrash[timeOfCrash.startIndex.advancedBy(3)...timeOfCrash.startIndex.advancedBy(4)])
			let timeOfCrashInMinutes = hourOfCrash!*60+minuteOfCrash!
			var distanceBetweenTimes = abs(timeOfCrashInMinutes - minutesPastMidnight)
			if distanceBetweenTimes > 720 {
				distanceBetweenTimes = 1440 - distanceBetweenTimes
			}
			let halfScore = Double(Int(riskLabel.text!)!/2)
			let ratio = halfScore/720
			let riskImpact = halfScore - Double(distanceBetweenTimes) * ratio
			totalRisk += riskImpact
		}
		let averageRisk = Int(round(totalRisk/Double(crashes.count)))
		riskLabel.text = "\(Int(riskLabel.text!)! + averageRisk)"
	}

}

