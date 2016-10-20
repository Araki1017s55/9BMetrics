//
//  BLEDeviceSelector.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 13/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//( at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.


import UIKit
import CoreBluetooth

class BLEDeviceSelector: UIViewController {
    
    @IBOutlet weak var tableView : UITableView?
    
    var devices : [CBPeripheral] = [CBPeripheral] ()
    var delegate : BLEDeviceSelectorDelegate?
    
    
    
    
    func clearDevices(){
        self.devices.removeAll()
    }
    
    func addDevices(_ devices: [CBPeripheral]){
        
        for d in devices {
            
            if getDevice(d.identifier.uuidString) == nil {
                self.devices.append(d)
            }
        }
        
        if let table = self.tableView{
            table.reloadData()
        }
    }
    
    func deviceSelected(_ peripheral:CBPeripheral){
        
        if let dele = self.delegate {
            dele.connectToPeripheral(peripheral)
        }
         
    }
    
    func getDevice(_ uuid : String) -> CBPeripheral?{
        
        for d in self.devices {
            
            if d.identifier.uuidString == uuid {
                return d
            }
            
        }
        
        return nil
    }
}

extension BLEDeviceSelector : UITableViewDataSource{
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.devices.count
        }else{
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "peripheralCellIdentifier", for: indexPath)
        
        let name = self.devices[indexPath.row].name
        let uuid = self.devices[indexPath.row].identifier.uuidString
    
        if let nam = name {
            
             cell.textLabel!.text = nam
        }else {
            cell.textLabel!.text = "No Name"
        }
       
        cell.detailTextLabel!.text = uuid
        
        return cell
    }
}

extension BLEDeviceSelector : UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
    
        let peripheral = self.devices[(indexPath as NSIndexPath).row]
        self.deviceSelected(peripheral)
    }

}
