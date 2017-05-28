//
//  ViewController.swift
//  WeatherMap
//
//  Created by David Argilan on 5/28/17.
//  Copyright © 2017 David Argilan. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var cityLbl: UILabel!
    @IBOutlet weak var conditionLbl: UILabel!
    @IBOutlet weak var degreeLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var imgView: UIImageView!
    
    var degree:Int!
    var condition:String!
    var imgURL:String!
    var city:String!
    var exists = true
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Request authorization for location
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 100
            locationManager.startUpdatingLocation()
        }
        
        
        
    }

    //Move map location
    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //Delegate method for location change
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print(locValue)
        centerMapOnLocation(location: CLLocation(latitude: locValue.latitude, longitude: locValue.longitude))
        requestWeather(withQuery: "\(locValue.latitude),\(locValue.longitude)")
    }
    func requestWeather(withQuery:String) {
        let urlRequest = URLRequest(url: URL(string: "https://api.apixu.com/v1/current.json?key=fcb109a886a64bd796d183043172805&q=\(withQuery)")!)
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            
            if error == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String : AnyObject]
                    
                    if let current = json["current"] as? [String : AnyObject] {
                        
                        if let temp = current["temp_f"] as? Int {
                           self.degree = temp
                        }
                        if let condition = current["condition"] as? [String : AnyObject] {
                           self.condition = condition["text"] as! String
                            let icon = condition["icon"] as! String
                            self.imgURL = "https:\(icon)"
                        }
                    }
                    if let location = json["location"] as? [String : AnyObject] {
                        print(location)
                        self.city = location["name"] as! String
                    }
                    if let _ = json["error"] {
                        self.exists = false
                    }
                    DispatchQueue.main.async {
                        if self.exists{
                            self.degreeLbl.isHidden = false
                            self.conditionLbl.isHidden = false
                            self.imgView.isHidden = false
                            self.degreeLbl.text = "\(self.degree.description)°F"
                            self.cityLbl.text = self.city
                            self.conditionLbl.text = self.condition
                            self.imgView.downloadImage(from: self.imgURL!)
                            
                        }else {
                            self.degreeLbl.isHidden = true
                            self.conditionLbl.isHidden = true
                            self.imgView.isHidden = true
                            self.cityLbl.text = "No matching city found"
                            self.exists = true
                        }
                    }
                } catch let jsonError {
                    print(jsonError.localizedDescription)
                }
            }
        }
        
        task.resume()
    }
}

extension UIImageView {
    
    func downloadImage(from url: String) {
        let urlRequest = URLRequest(url: URL(string: url)!)
        
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if error == nil {
                DispatchQueue.main.async {
                    self.image = UIImage(data: data!)
                }
            }
        }
        task.resume()
    }
    
}

