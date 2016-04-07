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
    var genericAlert : UIAlertView?
    
    var ubiquityUrl : NSURL?

    var datos : BLENinebot = BLENinebot()
    var client : BLESimulatedClient?

    weak var mainController : ViewController?
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        var shouldPerformAdditionalDelegateHandling = true
 
        if self.client == nil {
            self.client = BLESimulatedClient()
            if let cli = self.client {
                cli.datos = self.datos
            }
        }
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
            
            launchedShortcutItem = shortcutItem
            
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }
        
        self.setShortcutItems(false)
        
        return shouldPerformAdditionalDelegateHandling
    }
    
    
    func setShortcutItems(recording : Bool){
        
        var item : UIMutableApplicationShortcutItem?
        
        if recording {
            item = UIMutableApplicationShortcutItem(type: "es.gorina.9BMetrics.Stop", localizedTitle: "Stop", localizedSubtitle: "Stop recording data", icon: UIApplicationShortcutIcon(type: .Pause), userInfo: [
                AppDelegate.applicationShortcutUserInfoIconKey: UIApplicationShortcutIconType.Pause.rawValue
                ]
            )
        }
        else{
            item = UIMutableApplicationShortcutItem(type: "es.gorina.9BMetrics.Record", localizedTitle: "Record", localizedSubtitle: "Start recording data", icon: UIApplicationShortcutIcon(type: .Play), userInfo: [
                AppDelegate.applicationShortcutUserInfoIconKey: UIApplicationShortcutIconType.Play.rawValue
            ]
            )
        }
        
        
        if let it = item {
            UIApplication.sharedApplication().shortcutItems = [it]
        }
        
        
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        if url.fileURL{
            
            
            guard let name = url.lastPathComponent else {return false}
            
            guard var newUrl =  self.applicationDocumentsDirectory()?.URLByAppendingPathComponent(name) else {return false}
            
            let mgr = NSFileManager.defaultManager()
            
            // Check if file exists
            
            var ct = 1
            guard var path = newUrl.path else {return false}
            
            while mgr.fileExistsAtPath(path){
                
                let newName = String(format: "%@(%d)", name, ct)
                let aUrl = self.applicationDocumentsDirectory()?.URLByAppendingPathComponent(newName)
                if let url = aUrl{
                    path = url.path!
                    newUrl = url
                    ct += 1
                }
                else{
                    return false
                    
                }
            }
            
            do {
                try mgr.moveItemAtURL(url, toURL: newUrl)
                
                if let wc = self.mainController{
                    wc.reloadFiles()
                    wc.openUrl(newUrl)
                }
                
            }catch {
                
                self.displayMessageWithTitle("Error",format:"ERROR al copiar url %@ a %@", url, newUrl)
                AppDelegate.debugLog("ERROR al copiar url %@ a %@", url, newUrl)
                return false
            }
            
            return true
            
        }
        return false
    }
    
  
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        NSLog("Foreground")
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        NSLog("Activating")
        
        
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK : Shortcuts
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        let handledShortCutItem = handleShortCutItem(shortcutItem)
        
        completionHandler(handledShortCutItem)
    }
    
    func handleShortCutItem(shortcut : UIApplicationShortcutItem) -> Bool{

        AppDelegate.debugLog("Handle Sort Cut Item")
        launchedShortcutItem = nil // Clear it
     
        if shortcut.type == "es.gorina.9BMetrics.Record"{
            
            guard  let nav : UINavigationController = window?.rootViewController  as? UINavigationController else {return false}
            
            guard let wc = nav.topViewController as? ViewController   else {return false}
            
            wc.performSegueWithIdentifier("runningDashboardSegue", sender: wc)
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
            
            cli.connect()
        }
    }
    
    @IBAction func stop(src: AnyObject){
        
        
        if let cli = self.client{
            cli.stop()
        }
         self.setShortcutItems(false)
    }
    
        //TODO: Clear stop button

    
    // Missatges de Debug
    
    static func debugLog(format: String, _ args: CVarArgType...) {
        
        if AppDelegate.debugging {
            withVaList(args){
                NSLogv(format, $0)
            }
        }
        
    }
    
    //MARK : Directory Management
    
    func localApplicationDocumentsDirectory() -> NSURL?
    {
        let docs = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last
        
        return docs
        
    }
    
    
    func applicationDocumentsDirectory() -> NSURL?{
        
        if let url = self.ubiquityUrl{
            return url.URLByAppendingPathComponent("Documents")
        }
        else{
            return self.localApplicationDocumentsDirectory()
        }
    }
    
    //MARK: Message
    //MARK: - Utilities
    
    
    func displayMessageWithTitle(title: String, format: String, _ args: CVarArgType...)
    {
        var  msg  = ""
            
        withVaList(args){
            msg = String(format, $0)
        }
        
        self.genericAlert =  UIAlertView(title: title, message: msg, delegate: self, cancelButtonTitle: "OK")
        
        if let alert = self.genericAlert{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                alert.show()
            })
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView == self.genericAlert
        {
            alertView.dismissWithClickedButtonIndex(buttonIndex, animated: true)
        }
    }

    
}

