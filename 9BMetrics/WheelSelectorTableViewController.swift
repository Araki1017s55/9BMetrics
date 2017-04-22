//
//  WheelSelectorTableViewController.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 2/1/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import UIKit
import GyrometricsDataModel

class WheelSelectorTableViewController: UITableViewController {
    
    let database = WheelDatabase.sharedInstance
    var delegate : WheelSelectorDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return database.database.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wheelSelectorCellIdentifier", for: indexPath)
        
        if indexPath.row < database.database.count {
        
            let uuid = Array(database.database.keys)[indexPath.row]
            let wheel = database.getWheelFromUUID(uuid: uuid)!
        
        if let cel1 = cell as? WheelInfoCell{
            cel1.fTitle!.text = wheel.name
            cel1.fSubtitle!.text = wheel.brand + " " + wheel.model
            cel1.fDistance!.text = String(format: "%@", UnitManager.sharedInstance.formatDistance(wheel.totalDistance))
        }else {
            cell.textLabel!.text = wheel.name
            cell.detailTextLabel!.text = wheel.brand + " " + wheel.model
        }
        }
        else {
            if let cel1 = cell as? WheelInfoCell{
                cel1.fTitle!.text = "New Wheel".localized()
                cel1.fSubtitle!.text = ""
                cel1.fDistance!.text = ""
            }
            
        }
         return cell
    }
    
    //MARK : - Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let store = UserDefaults.standard
        
        var wheel : Wheel?
        
        if indexPath.row < database.database.count {
        
        let dataArray = Array(database.database.keys)
        let uuid = dataArray[indexPath.row]
        wheel = database.getWheelFromUUID(uuid: uuid)!
        
        
        // Now set data from the wheel
            
            if let wh = wheel {
        
        store.set(uuid, forKey:  BLESimulatedClient.kLast9BDeviceAccessedKey)
        store.set(wh.password, forKey : kPassword)
        store.set(wh.alarmSpeed, forKey : kSpeedAlarm)
        store.set(wh.batteryAlarm, forKey : kBatteryAlarm)
            }
        
        }
        else {
            store.removeObject(forKey: BLESimulatedClient.kLast9BDeviceAccessedKey)
            store.removeObject(forKey : kPassword)
            store.removeObject(forKey : kSpeedAlarm)
            store.removeObject(forKey : kBatteryAlarm)
        }
        
        if let dele = delegate {
            dele.selectedWheel(wheel)
        }else if let nav = self.navigationController{
            nav.popViewController(animated: true)
            
        }

        
        // Just as a test compute data
        
        //wheel.recomputeAdjust()
        //database.setWheel(wheel: wheel)
        
        
        
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // Get the wheel
            let dataArray = Array(database.database.keys)
            let uuid = dataArray[indexPath.row]
            let wheel = database.getWheelFromUUID(uuid: uuid)!

            database.removeWheel(wheel: wheel)
            
            
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
