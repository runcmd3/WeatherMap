//
//  TableViewController.swift
//  WeatherMap
//
//  Created by David Argilan on 5/29/17.
//  Copyright © 2017 David Argilan. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class TableViewController: UITableViewController {

    var listItems = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    //load in all the places from coredata
    override func viewWillAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName:"Places")
        
        do{
            let results = try context.fetch(request)
            if results.count > 0 {
                listItems = results as! [NSManagedObject]
            }
        } catch {
        }
    }
    //when user clicks on the cell go to that location on the map and update the weather for that location
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! TableViewCell
        
        let par = (parent! as! ViewController)
        let lat = cell.latitude!
        let lon = cell.longitude!
        par.slat = lat
        par.slon = lon
        par.requestWeather(withQuery: "\(lat.description),\(lon.description)")
        par.centerMapOnLocation(location: CLLocation(latitude: lat , longitude: lon ))
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    //add in new places visited
    func addLast(add: NSManagedObject) {
        listItems.insert(add, at: 0)
        self.tableView.reloadData()
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }
    //loads cells with content
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")! as! TableViewCell
        
        let item = listItems[indexPath.row]
        cell.myImage.downloadImage(from: (item.value(forKey: "image") as! String))
        cell.name.text = (item.value(forKey: "name") as! String)
        cell.condition.text = "\(item.value(forKey: "condition") as! String) \(item.value(forKey: "humidity") as! Int)% \(item.value(forKey: "temperature") as! Int)°F"
        cell.longitude = item.value(forKey: "longitude") as! Double
        cell.latitude = item.value(forKey: "latitude") as! Double
        
        //print((item.value(forKey: "name") as! String))
        return cell
    }

}
