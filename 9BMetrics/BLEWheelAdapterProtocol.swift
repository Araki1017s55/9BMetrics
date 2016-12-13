//
//  BLECWheelAdapterProtocol.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 4/5/16.
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
//
/// BLEWheelAdapterProtocol must be used to build adapters for different wheels
/// Esentially receives start/stop Recording calls for initializing and closing data
/// Connected/Disconnected calls when device connects or disonnects at the BLE level
/// charUpdated when data is received.
///
/// If the protocol has state it must be maintained in the adapter. The adapter is created
/// when the connection is done and is eliminated when the connection is closed
/// The adapter must generate a kHeaderDataReadyNotification when all header data
/// (name, Serial number, Version) is received or immediately if there is not this data (generate stubs)
///
/// Information received and analyzed must be given back from charUpdated in an array of ntuples
///
/// (WheelValue, Date, Value(Double) in SI Units (m, m/s, A, V, s, J, w)
/// Look at WheelTrack for definitions of WheelValues
///
/// All scaling, etc must be done from the adapter so all wheels seem similar
///
/// get functions give access to the name, version and serialNumber in string form
/// if the wheel gives them in another format (ex. as integers, etc.) transform them to
/// readable String form.
///
/// Date may be generated by the wheel tagging the values. If not use a NSDate() to generate it
///
/// Generate only wheel values, GPS, Altimeter and other posible values from the iPhone
/// are generated and mixed from the SimulatedClient
///
/// Also realise that the adapter ONLY contacts to the SimulatedClient and NO to the WheelTrack to factorize
/// better things and made everyting simpler.
//
//
import Foundation
import CoreBluetooth

// Types of known wheels

enum WheelType : String{
    
    case Unknown = "Unknown"
    case NinebotOne = "Ninebot One"
    case NinebotS2 = "Ninebot S2"
    case Gotaway = "Gotaway"
    case Kingsong = "Kingsong"
}



protocol BLEWheelAdapterProtocol {
    
    // Just init, reset State and let everything perfect for when first connection will be started
    
    func startRecording()
    
    // Just clear things etc.
    
    func stopRecording()
 
    // Called by connection when we got device characteristics

    func deviceConnected(_ connection: BLEMimConnection, peripheral : CBPeripheral )
    
    // Called when lost connection. perhaps should do something. If not forget it
    
    func deviceDisconnected(_ connection: BLEMimConnection, peripheral : CBPeripheral )
    
    // Data Received. Analyze, extract, convert and prosibly return a dictionary of characteristics and values
    
    func charUpdated(_ connection: BLEMimConnection,  char : CBCharacteristic, data: Data) -> [(WheelTrack.WheelValue, Date, Double)]?
    
    // Give Time. Uset to perform periodic tasks when GPS or Altimeter data is received
    
    func giveTime(_ connection: BLEMimConnection) 
  
    // name, version, sn may return empty
    
    func getName() -> String
    func getVersion() -> String
    func getSN() -> String
    func getRidingLevel() -> Int
    func getMaxSpeed() -> Double
    
    func setDefaultName(_ name : String)
    func setDrivingLevel(_ level: Int)
    func setLights(_ level: Int)    // 0->Off 1->On....
    func setLimitSpeed(_ speed : Double)   // Speed in km/h
    
    // Some commodities. For the moment only in Ninebot
    
    func enableLimitSpeed(_ enable : Bool)      // Enable or disable speedLimit
    func lockWheel(_ lock : Bool) // Lock or Unlock wheel

    // Returns a name for the wheel adapter (ex. Ninebot One E or Gotaway ....)
    func wheelName() -> String
    func isComptatible(services : [String : BLEService]) -> Bool
    
}
