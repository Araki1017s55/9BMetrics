//
//  AppDelegate.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 2/2/16.
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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static var debugging = true
    
    static let applicationShortcutUserInfoIconKey = "applicationShortcutUserInfoIconKey"
    
    /// Saved shortcut item used as a result of an app launch, used later when app is activated.
    var launchedShortcutItem: UIApplicationShortcutItem?
    
    var window: UIWindow?
    var genericAlert : UIAlertController?
    
    var ubiquityUrl : URL?
    
    var datos : WheelTrack = WheelTrack()
    var client : BLESimulatedClient?
    
    
    
    weak var mainController : ViewController?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        var shouldPerformAdditionalDelegateHandling = true
        
        
        buildAdapterList()
        if self.client == nil {
            self.client = BLESimulatedClient()
            if let cli = self.client {
                cli.datos = self.datos
            }
        }
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            
            launchedShortcutItem = shortcutItem
            
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }
        
        self.setShortcutItems(false)
        
        return shouldPerformAdditionalDelegateHandling
    }
    
    
    func setShortcutItems(_ recording : Bool){
        
        var item : UIMutableApplicationShortcutItem?
        
        if recording {
            item = UIMutableApplicationShortcutItem(type: "es.gorina.9BMetrics.Stop", localizedTitle: "Stop".localized(comment:"Stop Shortcut Item Title"), localizedSubtitle: "Stop recording data".localized(comment:"Stop Shortcut Item Subtitle"), icon: UIApplicationShortcutIcon(type: .pause), userInfo: [
                AppDelegate.applicationShortcutUserInfoIconKey: UIApplicationShortcutIconType.pause.rawValue
                ]
            )
        }
        else{
            item = UIMutableApplicationShortcutItem(type: "es.gorina.9BMetrics.Record", localizedTitle: "Record".localized(comment:"Record Shortcut Item Title"), localizedSubtitle: "Start recording data".localized(comment:"Start Shortcut Item Subtitle"), icon: UIApplicationShortcutIcon(type: .play), userInfo: [
                AppDelegate.applicationShortcutUserInfoIconKey: UIApplicationShortcutIconType.play.rawValue
                ]
            )
        }
        
        
        if let it = item {
            UIApplication.shared.shortcutItems = [it]
        }
        
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        if url.isFileURL{
            
            
            let name = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            
            var newExt = ext
            if ext == "9bz" {   // Will unpack
                newExt = "9bm"
            }
            
            
            guard var newUrl =  self.applicationDocumentsDirectory()?.appendingPathComponent(name).appendingPathExtension(newExt) else {return false}
            
            let mgr = FileManager.default
            
            // Check if file exists
            
            var ct = 1
            var path = newUrl.path
            
            while mgr.fileExists(atPath: path){
                
                let newName = String(format: "%@(%d)", name, ct)
                let aUrl = self.applicationDocumentsDirectory()?.appendingPathComponent(newName).appendingPathExtension(newExt)
                if let url = aUrl{
                    path = url.path
                    newUrl = url
                    ct += 1
                }
                else{
                    return false
                    
                }
            }
            
            do {
                if ext == "9bz" {
                    
                    try Zip.unzipFile(url, destination: newUrl, overwrite: false, password: nil, progress: { (progress) in
                        AppDelegate.debugLog("Unzipping %f".localized(comment: "Unzipping progress"), progress)
                    })
                }else {
                    
                    try mgr.moveItem(at: url, to: newUrl)
                }
                
                if let wc = self.mainController{
                    wc.reloadFiles()
                    wc.openUrl(newUrl)
                }
                
            }catch {
                
                self.displayMessageWithTitle("Error".localized(comment: "Standard ERROR message"),format:"ERROR al copiar url %@ a %@".localized(), url as CVarArg, newUrl as CVarArg)
                AppDelegate.debugLog("ERROR al copiar url %@ a %@", url as CVarArg, newUrl as CVarArg)
                return false
            }
            
            return true
            
        }
        return false
    }
    
    func buildAdapterList(){
        
        let wheelSelector = BLEWheelSelector.sharedInstance
        //wheelSelector.registerAdapter(BLENinebotOneAdapter())
        
        wheelSelector.registerAdapter(BLEInMotionAdapter())
        wheelSelector.registerAdapter(KingSongAdapter())
        wheelSelector.registerAdapter(GotawayAdapter())
        wheelSelector.registerAdapter(NinebotS12Adapter())
        wheelSelector.registerAdapter(BLENinebotOneAdapter())

    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        AppDelegate.debugLog("Foreground")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        AppDelegate.debugLog("Activating")
        
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        if let cli = self.client {
            cli.stop()    // In theory must save track
            
            let conn = cli.connection  //** Això no es necessari si desfem la connexio pero no esta de mes
            
            if let peri = conn.discoveredPeripheral {
                if let central = conn.centralManager{
                    central.cancelPeripheralConnection(peri)
                }
            }
        }
        
        
        
    }
    
    //MARK : Shortcuts
    
    
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShortCutItem = handleShortCutItem(shortcutItem)
        
        completionHandler(handledShortCutItem)
    }
    
    func handleShortCutItem(_ shortcut : UIApplicationShortcutItem) -> Bool{
        
        AppDelegate.debugLog("Handle Sort Cut Item")
        launchedShortcutItem = nil // Clear it
        
        if shortcut.type == "es.gorina.9BMetrics.Record"{
            
            guard  let nav : UINavigationController = window?.rootViewController  as? UINavigationController else {return false}
            
            guard let wc = nav.topViewController as? ViewController   else {return false}
            wc.openRunningDashboard(wc)
            self.setShortcutItems(true)
            
            
        }else if shortcut.type == "es.gorina.9BMetrics.Stop"{
            
            guard let cli = self.client   else {return false}
            
            cli.stop()
            self.setShortcutItems(false)
            
            //guard let ds = wc.dashboard else {return false}
        }
        
        
        return true
    }
    
    //MARK: Connect and disconnect from Watch and ninebot
    
    func connect(){
        
        // self.titleField.title = "Connecting..."
        
        //self.client = BLESimulatedClient()
        
        if let cli = self.client{
            if let dele = mainController {
                cli.timerStep = dele.timerStep
            }
            else{
                cli.timerStep = 0.01
            }
            
            cli.start()
        }
    }
    
    @IBAction func stop(_ src: AnyObject){
        
        
        if let cli = self.client{
            cli.stop()
        }
        self.setShortcutItems(false)
    }
    
    //TODO: Clear stop button
    
    
    // Missatges de Debug
    
    static func debugLog(_ format: String, _ args: CVarArg...) {
        
        if AppDelegate.debugging {
            withVaList(args){
                NSLogv(format, $0)
            }
        }
        
    }
    
    //MARK : Directory Management
    
    func localApplicationDocumentsDirectory() -> URL?
    {
        let docx = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        
        return docx.last
        
    }
    
    
    func applicationDocumentsDirectory() -> URL?{
        
        if let url = self.ubiquityUrl{
            return url.appendingPathComponent("Documents")
        }
        else{
            return self.localApplicationDocumentsDirectory()
        }
    }
    
    //MARK: Message
    //MARK: - Utilities
    
    static func alert(_ title: String, format: String, _ args: CVarArg...){
        
        let app = UIApplication.shared
        if let dele = app.delegate as? AppDelegate {
            
            dele.displayMessageWithTitle(title, format: format, args)
            
        }
        
    }

    func displayMessageWithTitle(_ title: String, format: String, _ args: CVarArg...)
    {
        var  msg  = ""
        
        withVaList(args){_ in
            msg = String(format: format, args)
        }
        
        genericAlert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "Close".localized(comment: "Tancar button title"), style: UIAlertActionStyle.cancel) { (action: UIAlertAction) -> Void in
            
            
        }
        
        if let alert = genericAlert, let controller = mainController {
            alert.addAction(action)
            controller.present(alert, animated: true) { () -> Void in
                
            }
        }
        
        
    }
    
    
    
}

