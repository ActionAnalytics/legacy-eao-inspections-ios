//
//  PFGeoPoint.swift
//  EAO
//
//  Created by Micha Volin on 2017-05-08.
//  Copyright © 2017 FreshWorks. All rights reserved.
//

import Parse
extension PFGeoPoint{
	func toString()->String?{
		let lat = "\(latitude)".trimBy(numberOfChar: 10)
		let lon = "\(longitude)".trimBy(numberOfChar: 10)
		return "\(lat) by \(lon)"
	}
}
