//
//  MyLocationManager.swift
//  Maps
//
//  Created by HuangShih-Hsuan on 22/03/2017.
//  Copyright © 2017 HuangShih-Hsuan. All rights reserved.
//

import UIKit
import CoreLocation

class MyLocationManager: NSObject, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var completionHandler: ((CLLocation) -> Void)?
    
    var isRequestingLocation = false
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocation(completionHandler: @escaping (CLLocation) -> Void) {
        self.completionHandler = completionHandler
        isRequestingLocation = true
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if !isRequestingLocation {
            return
        }
        
        let location = locations.first!;
        
        completionHandler?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager Fail")
    }
    
}
