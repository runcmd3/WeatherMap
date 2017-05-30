//
//  ViewController.swift
//  WeatherMap
//
//  Created by David Argilan on 5/28/17.
//  Copyright © 2017 David Argilan. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var cityLbl: UILabel!
    @IBOutlet weak var conditionLbl: UILabel!
    @IBOutlet weak var degreeLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var imgView: UIImageView!
    
    var degree:Int!
    var rh:Int!
    var condition:String!
    var imgURL:String!
    var city:String!
    var slat:Double!
    var slon:Double!
    var exists = true
    var locationEnabled = true
    var enableTimer:Timer!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Request authorization for location
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = 1000
            locationManager.startUpdatingLocation()
        }
        loadSaved()
    }

    //Move map location
    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //Delegate method for location change
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locationEnabled {
            locationEnabled = false
            enableTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(enableLocation), userInfo: nil, repeats: false)
            let locValue:CLLocationCoordinate2D = manager.location!.coordinate
            print(locValue)
            centerMapOnLocation(location: CLLocation(latitude: locValue.latitude, longitude: locValue.longitude))
            slon = locValue.longitude
            slat = locValue.latitude
            requestWeather(withQuery: "\(locValue.latitude),\(locValue.longitude)")
        }
    }
    //Prevents multiple calls to update
    func enableLocation() {
        locationEnabled = true
        print("enabled")
    }
    
    func loadSaved() {
        for result in getSaved() {
            if let name = result.value(forKey: "name") {
                print(name)
            }
            if let lon = result.value(forKey: "longitude") {
                print(lon)
            }
            if let lat = result.value(forKey: "latitude") {
                print(lat)
            }
        }
    }
    //Get all saved objects from coredata
    func getSaved()-> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName:"Places")
        request.returnsObjectsAsFaults = false
        print("loading")
        do{
            let results = try context.fetch(request)
            if results.count > 0 {
                return results as! [NSManagedObject]
            }
        } catch {
            
        }
        return []
    }
    //Save a place to core data
    func savePlace() {
        var duplicate: NSManagedObject? = nil
        for result in getSaved() {
            if let name = result.value(forKey: "name") {
                if name as! String == self.city {
                    duplicate = result//return
                }
            }
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let context = appDelegate.persistentContainer.viewContext
        
        if duplicate != nil {
            let child = (self.childViewControllers.last! as! TableViewController)
            child.listItems.remove(at: child.listItems.index(of: duplicate!)!)
            context.delete(duplicate!)
        }
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(self.city, forKey: "name")
        newPlace.setValue(self.slat, forKey: "latitude")
        newPlace.setValue(self.slon, forKey: "longitude")
        newPlace.setValue(self.imgURL, forKey: "image")
        newPlace.setValue(self.rh, forKey: "humidity")
        newPlace.setValue(self.degree, forKey: "temperature")
        newPlace.setValue(self.condition, forKey: "condition")
        
        
        
        do {
            try context.save()
            (self.childViewControllers.last as! TableViewController).addLast(add: newPlace)
        } catch {
            print("error")
        }

    }
    //Make a request to Weather API
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
                        if let rh = current["humidity"] as? Int {
                            self.rh = rh
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
                            self.degreeLbl.text = "\(self.rh.description)% \(self.degree.description)°F"
                            self.cityLbl.text = self.city
                            self.conditionLbl.text = self.condition
                            self.imgView.downloadImage(from: self.imgURL!)
                            self.savePlace()
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
//extension to load a downloaded image into imageview
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

