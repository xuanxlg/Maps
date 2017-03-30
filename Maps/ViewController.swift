//
//  ViewController.swift
//  Maps
//
//  Created by HuangShih-Hsuan on 22/03/2017.
//  Copyright © 2017 HuangShih-Hsuan. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps
import Alamofire
import SwiftMessages

class ViewController: UIViewController, MKMapViewDelegate, GMSMapViewDelegate {
    
    let locationManager = CLLocationManager()
    let myLocationManager = MyLocationManager()
    let zoom = 18
    let mapInsets = UIEdgeInsetsMake(150.0, 50.0, 130.0, 50.0)
    
    var marker = GMSMarker()
    var point:MKPointAnnotation = MKPointAnnotation();
    var tap = false
    var isGoogleMap = false
    
    var storeName = ""
    var storeRating = 0.0
    var storeNumber = ""
    var storeDistance = 0.0
    var storeArrivalTime = 0.0
    var storeAddress = ""
    var storeImageUrl = ""
    
    @IBOutlet weak var iOSMap: MKMapView!
    @IBOutlet weak var googleMap: GMSMapView!
    
    @IBOutlet weak var mapMode: UIButton!
    @IBOutlet weak var distance: UISlider!
    
    @IBOutlet weak var distanceRange: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showMap()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func showMap() {
        if isGoogleMap {
            iOSMap.isHidden = true
            googleMap.isHidden = false
            showGoogleMap()
        } else {
            iOSMap.isHidden = false
            googleMap.isHidden = true
            showiOSMap()
        }
    }
    
    private func showGoogleMap() {
        
        clearLabel()
        googleMap.clear()
        googleMap.delegate = self
        
        tap = true
        myLocationManager.requestLocation(completionHandler: { location in
            if (self.tap == true) {
                self.tap = false
                
                let nowLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude);
                
                let camera = GMSCameraPosition.camera(withLatitude: nowLocation.latitude, longitude: nowLocation.longitude, zoom: Float(self.zoom))
                self.googleMap.camera = camera
                self.googleMap.isMyLocationEnabled = true
                self.googleMap.settings.compassButton = true
                self.googleMap.padding = self.mapInsets
            }
        })
    }
    
    private func showiOSMap() {
        
        iOSMap.delegate = self
        
        clearLabel()
        iOSMap.removeAnnotation(point)
        clearOverlay()
        
        tap = true
        myLocationManager.requestLocation(completionHandler: { location in
            if (self.tap == true) {
                self.tap = false
                
                let nowLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude);
                let currentLocationSpan:MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005);
                self.iOSMap.setRegion(MKCoordinateRegion(center: nowLocation, span: currentLocationSpan), animated: true);
                self.iOSMap.showsUserLocation = true
            }
        })
    }
    
    @IBAction func switchMapMode(_ sender: Any) {
        isGoogleMap = !isGoogleMap
        showMap()
    }
    
    @IBAction func distanceChange(_ sender: Any) {
        let distanceValue = round(distance.value*10)/10
        distance.value = distanceValue
        distanceRange.text = "\(distanceValue)"
    }
    
    private func call() {
        if self.storeNumber != "" {
            guard let number = URL(string: "telprompt://" + self.storeNumber) else { return }
            UIApplication.shared.open(number, options: [:], completionHandler: nil)
        } else {
            self.showAlert(title: "Attention", message: "No phone number")
        }
    }
    
    @IBAction func search(_ sender: Any) {
        if isGoogleMap {
            searchGoogleMap()
        } else {
            searchiOSMap()
        }
    }
    
    private func searchGoogleMap() {
        tap = true
        myLocationManager.requestLocation(completionHandler: { location in
            if (self.tap == true) {
                self.tap = false
                
                let distance = self.distance.value;
                
                Alamofire.request("https://food-locator-dot-hpd-io.appspot.com/v1/location_query?latitude=\(location.coordinate.latitude)&longitude=\(location.coordinate.longitude)&distance=\(distance)").responseJSON(completionHandler: { response in
                    if response.result.isSuccess {
                        // convert data to dictionary array
                        if let result = response.value as? [[String: Any]] {
                            
                            DispatchQueue.main.async {
                                
                                self.clearLabel()
                                
                                let randomNum:UInt32 = arc4random_uniform(UInt32(result.count))
                                let getResult = result[Int(randomNum)]
                                
                                let latitude = getResult["latitude"] as! Double
                                let longitude = getResult["longitude"] as! Double
                                
                                self.storeName = getResult["name"] as! String
                                self.storeRating = getResult["rating"] as! Double
                                self.storeNumber = getResult["phone"] as! String
                                self.storeAddress = getResult["address"] as! String
                                self.storeImageUrl = getResult["photo"] as! String
                                
                                self.addGooglePointAnnotation(
                                    latitude: latitude,
                                    longitude: longitude,
                                    storeName: self.storeName,
                                    storeRating: self.storeRating
                                );
                                
                                let currentLocationPlacemark = MKPlacemark(coordinate: location.coordinate, addressDictionary: nil)
                                let currentLocationMapItem = MKMapItem(placemark: currentLocationPlacemark)
                                
                                let destionationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                let destionationPlacemark = MKPlacemark(coordinate: destionationCoordinate, addressDictionary: nil)
                                let destionationMapItem = MKMapItem(placemark: destionationPlacemark)
                                
                                print("to new Location: (\(destionationCoordinate.latitude),\(destionationCoordinate.longitude))")
                                
                                /***
                                 * Camera for bounds
                                 ***/
                                let current = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
                                let target = CLLocationCoordinate2DMake(latitude, longitude)
                                let bounds = GMSCoordinateBounds(coordinate: current, coordinate: target)
                                let camera = self.googleMap.camera(for: bounds, insets:UIEdgeInsets.zero)
                                self.googleMap.camera = camera!
                                
                                let request = MKDirectionsRequest()
                                request.source = currentLocationMapItem
                                request.destination = destionationMapItem
                                request.transportType = .walking
                                
                                let directions = MKDirections(request: request)
                                directions.calculateETA(completionHandler: {response, error in
                                    if let error = error {
                                        print("calculateETA error: \(error)")
                                        return
                                    }
                                    
                                    DispatchQueue.main.async {
                                        let response = response!
                                        
                                        print("Info name: \(getResult["name"] as! String)")
                                        print("Info phone: \(getResult["phone"] as! String)")
                                        print("Info photo: \(getResult["photo"] as! String)")
                                        print("Info distance: \(response.distance)")
                                        print("Info expectedTravelTime: \(round((response.expectedTravelTime/60.0)*10)/10)")
                                        
                                        self.storeDistance = response.distance
                                        self.storeArrivalTime = round((response.expectedTravelTime/60.0)*10)/10
                                        
                                        self.showInfo(url: self.storeImageUrl)
                                    }
                                    
                                })
                                
                                Alamofire.request("https://maps.googleapis.com/maps/api/directions/json?origin=\(location.coordinate.latitude),\(location.coordinate.longitude)&destination=\(latitude),\(longitude)&sensor=false&mode=walking").responseJSON(completionHandler: { response in
                                    if response.result.isSuccess {
                                        // convert data to dictionary array
                                        if let result = response.value as? [String: AnyObject] {
                                            if let array = result["routes"] as? NSArray {
                                                if let routes = array[0] as? NSDictionary{
                                                    if let overview_polyline = routes["overview_polyline"] as? NSDictionary{
                                                        if let points = overview_polyline["points"] as? String{
                                                            print("points \(points)")
                                                            // Use DispatchQueue.main for main thread for handling UI
                                                            DispatchQueue.main.async {
                                                                // show polyline
                                                                let path = GMSPath(fromEncodedPath:points)
                                                                let polyline = GMSPolyline(path:path)
                                                                polyline.strokeWidth = 5
                                                                polyline.strokeColor = UIColor.init(hue: 210/360, saturation: 100/100, brightness: 100/100, alpha: 1)
                                                                polyline.map = self.googleMap
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        print("error: \(response.error)")
                                    }
                                })
                            }

                        }
                    } else {
                        print("error: \(response.error)")
                    }
                })
            }
        })
    }
    
    private func searchiOSMap() {
        tap = true
        myLocationManager.requestLocation(completionHandler: { location in
            
            if (self.tap == true) {
                self.tap = false
                
                print("location.coordinate: (\(location.coordinate.latitude), \(location.coordinate.longitude))")
                
                let distance = self.distance.value;
                
                Alamofire.request("https://food-locator-dot-hpd-io.appspot.com/v1/location_query?latitude=\(location.coordinate.latitude)&longitude=\(location.coordinate.longitude)&distance=\(distance)").responseJSON(completionHandler: { response in
                    if response.result.isSuccess {
                        // convert data to dictionary array
                        if let result = response.value as? [[String: Any]] {
                            
                            DispatchQueue.main.async {
                                
                                self.clearLabel()
                                self.clearOverlay()
                                
                                let randomNum:UInt32 = arc4random_uniform(UInt32(result.count))
                                let getResult = result[Int(randomNum)]
                                
                                let latitude = getResult["latitude"] as! Double
                                let longitude = getResult["longitude"] as! Double
                                
                                self.storeName = getResult["name"] as! String
                                self.storeRating = getResult["rating"] as! Double
                                self.storeNumber = getResult["phone"] as! String
                                self.storeAddress = getResult["address"] as! String
                                self.storeImageUrl = getResult["photo"] as! String
                                
                                print("calculateETA result.count: \(result.count)")
                                print("calculateETA getResult.name: \(getResult["name"] as! String)")
                                print("calculateETA getResult.phone: \(getResult["phone"] as! String)")
                                print("calculateETA getResult.photo: \(getResult["photo"] as! String)")
                                
                                let currentLocationPlacemark = MKPlacemark(coordinate: location.coordinate, addressDictionary: nil)
                                let currentLocationMapItem = MKMapItem(placemark: currentLocationPlacemark)
                                
                                let destionationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                let destionationPlacemark = MKPlacemark(coordinate: destionationCoordinate, addressDictionary: nil)
                                let destionationMapItem = MKMapItem(placemark: destionationPlacemark)
                                
                                let centerLatitude = (location.coordinate.latitude + latitude) / 2
                                let centerLongitude = (location.coordinate.longitude + longitude) / 2
                                let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
                                
                                let intervalLatitude = abs(location.coordinate.latitude - latitude)
                                let intervalLongitude = abs(location.coordinate.longitude - longitude)
                                var interval = 0.0
                                if (intervalLatitude >= intervalLongitude) {
                                    interval = intervalLatitude
                                } else {
                                    interval = intervalLongitude
                                }
                                let coordinateDeltaDegrees = CLLocationDegrees(interval+0.001)
                                let destionationLocationSpan:MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: coordinateDeltaDegrees, longitudeDelta: coordinateDeltaDegrees);
                                self.iOSMap.setRegion(MKCoordinateRegion(center: centerCoordinate, span: destionationLocationSpan), animated: true);
                                self.addiOSPointAnnotation(
                                    latitude: latitude,
                                    longitude: longitude,
                                    storeName: self.storeName,
                                    storeRating: self.storeRating
                                );
                                
                                let request = MKDirectionsRequest()
                                request.source = currentLocationMapItem
                                request.destination = destionationMapItem
                                request.transportType = .walking
                                
                                let directions = MKDirections(request: request)
                                directions.calculate(completionHandler: {response, error in
                                    if let error = error {
                                        print("calculateETA error: \(error)")
                                        return
                                    }
                                    
                                    DispatchQueue.main.async {
                                        
                                        let response = response!
                                        print("calculateETA response.distance: \(response.routes[0].distance)")
                                        print("calculateETA response.expectedTravelTime: \(round((response.routes[0].expectedTravelTime/60.0)*10)/10)")
                                        
                                        self.storeDistance = response.routes[0].distance
                                        self.storeArrivalTime = round((response.routes[0].expectedTravelTime/60.0)*10)/10
                                        
                                        self.showInfo(url: self.storeImageUrl)
                                        
                                        print("calculateETA response.routes.count: \(response.routes.count)")
                                        for route in response.routes {
                                            self.iOSMap.add(route.polyline, level: MKOverlayLevel.aboveRoads)
                                        }
                                        
                                    }
                                    
                                })
                            }
                        }
                    } else {
                        print("error: \(response.error)")
                    }
                })
            }
        })
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        showInfo(url: storeImageUrl)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        showInfo(url: storeImageUrl)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polyLineRenderer = MKPolylineRenderer(overlay: overlay)
        polyLineRenderer.strokeColor = UIColor(hue: 210/360, saturation: 100/100, brightness: 100/100, alpha: 1.0)
        polyLineRenderer.lineWidth = 5.0
        return polyLineRenderer
    }
    
    private func clearOverlay() {
        for overlay in self.iOSMap.overlays {
            self.iOSMap.remove(overlay)
        }
    }
    
    private func addGooglePointAnnotation(latitude: CLLocationDegrees, longitude: CLLocationDegrees, storeName: String, storeRating: Double){
        googleMap.clear()
        
        marker = GMSMarker(position: CLLocationCoordinate2DMake(latitude, longitude))
        marker.title = storeName
        marker.snippet = "Rating \(storeRating)"
        marker.map = self.googleMap
        print("marker location: (\(latitude),\(longitude))")
    }
    
    private func addiOSPointAnnotation(latitude:CLLocationDegrees , longitude:CLLocationDegrees, storeName: String, storeRating: Double){
        iOSMap.removeAnnotation(point)
        
        point.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        point.title = storeName
        point.subtitle = "Rating \(storeRating)"
        
        iOSMap.addAnnotation(point);
    }
    
    private func clearLabel() {
        mapMode.setTitle("", for: .normal)
        
        if isGoogleMap {
            mapMode.setTitle("Google Map", for: .normal)
        } else {
            mapMode.setTitle("Apple Map", for: .normal)
        }
        
        storeName = ""
        storeRating = 0.0
        storeNumber = ""
        storeDistance = 0.0
        storeArrivalTime = 0.0
        storeAddress = ""
        storeImageUrl = ""
    }
    
    private func showAlert(title: String, message: String) {
        let actionSheetController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    private func showInfo(url: String) {
        
        if url != "" {
            let catPictureURL = URL(string: "\(url)")!
            // Creating a session object with the default configuration.
            // You can read more about it here https://developer.apple.com/reference/foundation/urlsessionconfiguration
            let session = URLSession(configuration: .default)
            
            // Define a download task. The download task will download the contents of the URL as a Data object and then you can do what you wish with that data.
            let downloadPicTask = session.dataTask(with: catPictureURL) { (data, response, error) in
                // The download has finished.
                if let e = error {
                    print("Error downloading cat picture: \(e)")
                } else {
                    // No errors found.
                    // It would be weird if we didn't have a response, so check for that too.
                    if let res = response as? HTTPURLResponse {
                        print("Downloaded cat picture with response code \(res.statusCode)")
                        if let imageData = data {
                            // Finally convert that Data into an image and do what you wish with it.
                            //                            self.imageView.image = UIImage(data: imageData)
                            DispatchQueue.main.async {
                                
                                let view = MessageView.viewFromNib(layout: .CardView)
                                
                                view.button?.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
                                view.button?.setBackgroundImage(UIImage(named: "call")?.withRenderingMode(.automatic), for: .normal)
                                view.buttonTapHandler = { _ in self.call()}
                                
                                view.configureTheme(.warning)
                                view.configureDropShadow()
                                view.configureContent(
                                    backgroundColor: UIColor(hue: 60/360, saturation: 75/100, brightness: 100/100, alpha: 0.5),
                                    fontColor: UIColor.white,
                                    name: self.storeName,
                                    rating: "\(self.storeRating)",
                                    distance: "\(self.storeDistance) m",
                                    arrivalTime: "\(self.storeArrivalTime) mins",
                                    address: self.storeAddress,
                                    image: UIImage(data: imageData)!)
                                
                                var config = SwiftMessages.Config()
                                config.presentationStyle = .bottom
                                config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
                                config.duration = .forever
                                config.dimMode = .gray(interactive: true)
                                config.interactiveHide = false
                                config.preferredStatusBarStyle = .lightContent
                                
                                // Specify one or more event listeners to respond to show and hide events.
                                config.eventListeners.append() { event in
                                    if case .didHide = event { print("yep") }
                                }
                                
                                SwiftMessages.show(config: config, view: view)
                                
                            }
                            
                            // Do something with your image.
                        } else {
                            print("Couldn't get image: Image is nil")
                        }
                    } else {
                        print("Couldn't get response code for some reason")
                    }
                }
            }
            
            downloadPicTask.resume()
        }
    }
    
    
}
