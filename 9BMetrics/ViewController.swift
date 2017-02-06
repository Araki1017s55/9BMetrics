//
//  ViewController.swift
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
import UserNotifications
import CoreMotion
import MapKit

/**
 Main Class shows a list of runs ordered by date.
 Allows to share/export tracks, visualize data and access general settinfs
 */
 class ViewController: UIViewController , UITableViewDataSource, UITableViewDelegate{
    
    enum stateValues {
        case waiting
        case miM
        case client
        case server
    }
    
    /// Describes a file date section : Today, Yesterday, last week, last month ...
    struct fileSection {
        
        var section : Int
        var description : String
        var files : [URL]
    }
    
    let kTestMode = "enabled_test"
    let kDashboardMode = "dashboard_mode"
    let kBlockSleepMode = "block_sleep"
   
    
    // weak var ninebot : BLENinebot?
    var server : BLESimulatedServer?
    //var client : BLESimulatedClient?
    
    var state : stateValues = .waiting
    
    var firstField = 185      // Primer camp a llegir
    var nFields = 10         // Numero de camps a llegir
    var timerStep = 0.01   // Segons per repetir el enviar
    
    
    var files = [URL]()
    var sections = [fileSection]()
    var actualDir : URL?
    var currentFile : URL?
    
    @IBOutlet weak var tableView : UITableView!
    
    var docc : UIDocumentInteractionController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 10.0, *) {  // Send User notifications for speed, and battery
                            
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                // Enable or disable features based on authorization
            }
        } else {
            // Fallback on earlier versions
        }
        
        
        registerForPreviewing(with: self, sourceView: tableView)
        
        // Do any additional setup after loading the view, typically from a nib.
        let editButton = self.editButtonItem;
        editButton.target = self
        editButton.action = #selector(ViewController.editFiles(_:))
        self.navigationItem.leftBarButtonItem = editButton;
        // Lookup files
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.mainController = self
        self.reloadFiles()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Called when the actual run has stopped to update runs list
    func hasStopped(_ not : Notification){
        self.reloadFiles()
    }
    
    /// Legacy...
    func connectionStarted(_ not : Notification){
        
        if let dele = UIApplication.shared.delegate as? AppDelegate{
            
            if  dele.client != nil{
                
                //self.performSegueWithIdentifier("runningDashboardSegue", sender: self)
            }
        }
    }
    
    /// Loads current document directory data into array
    func reloadFiles(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {return}
        guard let docsUrl = appDelegate.applicationDocumentsDirectory() else {return}
        
        loadLocalDirectoryData(docsUrl as URL)
        
    }
    
    
    /// Returns creation date of a file
    ///
    /// - parameter url:  url of the file
    /// - returns: The creation date of the file
    func creationDate(_ url : URL) -> Date?{
        var rsrc : AnyObject? = nil
        
        do{
            try (url as NSURL).getResourceValue(&rsrc, forKey: URLResourceKey.creationDateKey)
        }
        catch{
            AppDelegate.debugLog("Error reading creation date of file %", url as CVarArg)
        }
        
        let date = rsrc as? Date
        
        return date
        
    }
    
    /// Converts a date to a section number
    /// - Parameter dat: The date
    /// - Returns : The section number
    func dateToSection(_ dat : Date) -> Int{
        
        let today = Date()
        
        let calendar = Calendar.current
        
        if calendar.isDateInToday(dat){
            return 0
        }
            
        else if calendar.isDateInYesterday(dat){
            return 1
        }
            
        else if calendar.compare(today, to: dat, toGranularity: .weekOfYear) == .orderedSame {
            return 2
        }
        else if calendar.compare(today, to: dat, toGranularity: .month) == .orderedSame{
            return 3
        }
        
        // OK, here we have the normal ones. Now for older in same year we return the
        // month of the year
        
        
        let ty = calendar.component(.year, from: today)
        let dy = calendar.component(.year, from: dat)
        let tm = calendar.component(.month, from: today)
        let dm = calendar.component(.month, from: dat)
        
        if ty == dy {
            return 3 + tm - dm
        }
        
        // OK now we return just the difference in years. January of this year was
        
        return 2 + tm + ty - dy
        
        
        
    }
    
    /// Converts a section number to a string label
    /// - Parameter section: The section number
    /// - Returns: The corresponding string label
    func sectionLabel(_ section : Int) -> String{
        
        let today = Date()
        let calendar = Calendar.current
        
        let month = calendar.component(.month, from: today)
        let year = calendar.component(.year, from:today)
        
        
        
        switch section {
            
        case 0 : return "Today".localized()
            
        case 1:
            return "Yesterday".localized()
            
        case 2:
            return "This Week".localized()
            
        case 3:
            return "This Month".localized()
            
        case 4..<(3 + month) :
            
            let month =  month + 2 - section // Indexed at 0
            let df = DateFormatter()
            return df.standaloneMonthSymbols[month]
            
        default :
            return String(year - (section - 2 - month))
            
            
        }
        
    }
    
    /// Processes an array of files and sort them into sections in self.sections
    /// according its *creation date*
    ///
    /// - Parameter files: The array of files
    ///
    func sortFilesIntoSections(_ files:[URL]){
        
        
        self.sections.removeAll()   // Clear all section
        
        for f in files {
            
            let date = self.creationDate(f)
            
            if let d = date{
                
                let s = self.dateToSection(d)
                
                
                while self.sections.count - 1 < s{
                    
                    let newSection = self.sections.count
                    self.sections.append(fileSection(section: newSection, description: self.sectionLabel(newSection), files: [URL]()))
                    
                }
                
                self.sections[s].files.append(f)
            }
        }
        
        var i = 0
        
        while i < self.sections.count {
            
            if self.sections[i].files.count == 0{
                self.sections.remove(at: i)
            }else{
                i += 1
            }
        }
    }
    
    /// Checks if a file is a directory
    /// 
    /// - Parameter url : The url of the file
    /// - Returns : true or false depending if the url corresponds ot not to a directory
    func isDirectory(_ url : URL) -> Bool{
        
        var isDirectory: ObjCBool = ObjCBool(false)
        let path = url.path
        
  
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
            return isDirectory.boolValue
            
        }
        return false
    }
    
    /// Does the actual load of a local directory data.
    ///
    /// Updates self.actualDir, files and self.sections
    ///
    /// - Parameter dir: The URL of the directory
    ///
    func loadLocalDirectoryData(_ dir : URL){
        
        self.actualDir = dir
        
        files.removeAll()
        
        let mgr = FileManager()
        
        let enumerator = mgr.enumerator(at: dir, includingPropertiesForKeys: nil, options: [FileManager.DirectoryEnumerationOptions.skipsHiddenFiles, FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants]) { (URL, Error) -> Bool in
            
            let err = Error as NSError
            AppDelegate.debugLog("Error enumerating files %@", err.localizedDescription)
            return true
        }
        
        
        
        
        
        if let arch = enumerator{
            
            for item in arch  {
                
                if let url = item as? URL , !self.isDirectory(url)  || url.pathExtension == "9bm"{
                    if url.pathExtension  != "gpx" && url.lastPathComponent != "wheels"{
                        files.append(url)
                    }
                }
                
            }
        }
        
        // OK ara hauriem de ordenar els documents
        
        files.sort { (url1: URL, url2: URL) -> Bool in
            
            let date1 = self.creationDate(url1)
            let date2 = self.creationDate(url2)
            
            if let dat1 = date1, let dat2 = date2 {
                return dat1.timeIntervalSince1970 > dat2.timeIntervalSince1970
            }
            else{
                return true
            }
            
        }
        
        self.sortFilesIntoSections(self.files)
        
        
    }
    
    /// Returns the url which correspond to an indexpath int the table
    /// - Parameter indexPath : The indexPath (section, row)
    /// - Returns : The URL from the sections table corresponding to the indexPath
    func urlForIndexPath(_ indexPath: IndexPath) -> URL?{
        
        if (indexPath as NSIndexPath).section < self.sections.count {
            let section = self.sections[(indexPath as NSIndexPath).section]
            if (indexPath as NSIndexPath).row < section.files.count{
                let url = section.files[(indexPath as NSIndexPath).row]
                return url
            }
        }
        return nil
        
    }
    
    @IBAction func MiM(){
        
    }
    
    
    @IBAction func Server(){
    }
    
    @IBAction func Client(){
    }
    
    
    func startClient (){
    }
    
    func stopClient(){
        
    }
    
    func sendTestNotification(){
        
        if let dele = UIApplication.shared.delegate as? AppDelegate{
            if let client = dele.client{
                client.sendBatteryLevelNotification(level: 10.0)
                client.sendBatteryLevelNotification(level: 30.0)
                client.sendSpeedAlertNotification(speed: 30.0 / 3.6)
            }
        }
        
    }
    
    func printScheduledNotifications() {
        if #available(iOS 10.0, *) {
            print("printing scheduled notifications >=iOS10")
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (notifications) in
                print("count", notifications.count)
                for notification in notifications{
                    
                    print(notification.description)
                }
            })
        }
    }

    
    /**
        opens the running dashboard according preferences
        - Parameter src : Source of command
    */
    @IBAction func startRun(_ src : AnyObject){
        
        let db = WheelDatabase.sharedInstance
        
        if db.database.count > 1 {
            
            performSegue(withIdentifier: "selectWheelIdentifier", sender: self)
            
        } else {
        
            openRunningDashboard(self)
        }
    }
    
    func openRunningDashboard(_ src : AnyObject?){
        let store = UserDefaults.standard
        let graphMode = store.bool(forKey: kDashboardMode)
        
        if graphMode {
            performSegue(withIdentifier: "GraphicRunningDashboardSegue", sender: self)
        }else{
            performSegue(withIdentifier: "runningDashboardSegue", sender: self)
        }
    }
    
    

    /**
        Builds and opens the general settings dialog
 
        - Parameter src : The origin of the event
    */
    @IBAction func openSettings(_ src : AnyObject){
        
        let but = src as? UIButton
        
        let store = UserDefaults.standard
        let testMode = store.bool(forKey: kTestMode)
        
        
        let alert = UIAlertController(title: "Options".localized(comment: "Options menu item"), message: "Select an option".localized(comment: "Action Sheet message"), preferredStyle: UIAlertControllerStyle.actionSheet);
        
        alert.popoverPresentationController?.sourceView = but
        
        var action = UIAlertAction(title: "Close".localized(), style: UIAlertActionStyle.cancel) { (action: UIAlertAction) -> Void in
            
            
        }
        alert.addAction(action)
        
        action = UIAlertAction(title: "Settings".localized(comment: "Settings menu item"), style: UIAlertActionStyle.default, handler: { (action : UIAlertAction) -> Void in
            self.performSegue(withIdentifier: "settingsSegue", sender: self)
        })
        
        alert.addAction(action)
        
        if testMode {
            
            action = UIAlertAction(title: "Show Local Normative".localized(comment: "Show local normative and uses"), style: UIAlertActionStyle.default, handler: { (action : UIAlertAction) -> Void in
                
                self.performSegue(withIdentifier: "localUsesSegue", sender: self)
            })
            
            alert.addAction(action)

            
            action = UIAlertAction(title: "Debug Server".localized(comment: "Debug server item"), style: UIAlertActionStyle.default, handler: { (action : UIAlertAction) -> Void in
                
                self.performSegue(withIdentifier: "mimSegue", sender: self)
            })
            
            alert.addAction(action)
            
            action = UIAlertAction(title: "Ninebot Server".localized(comment: "ninebot server item"), style: UIAlertActionStyle.default, handler: { (action : UIAlertAction) -> Void in
                
                self.performSegue(withIdentifier: "simulatedNinebotSegue", sender: self)
            })
            
            alert.addAction(action)
            
            
            action = UIAlertAction(title: "Send Notification".localized(comment: "send notification item"), style: UIAlertActionStyle.default, handler: { (action : UIAlertAction) -> Void in
                
                self.sendTestNotification()
            })
            
            alert.addAction(action)
            
            
        }
        
        
        
        action = UIAlertAction(title: "About Gyrometrics".localized(comment: "About item"), style: UIAlertActionStyle.default, handler: { (action : UIAlertAction) -> Void in
            self.performSegue(withIdentifier: "docSegue", sender: self)
        })
        
        alert.addAction(action)
        
        
        
        self.present(alert, animated: true) { () -> Void in
            
            
        }
        
    }
    
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        if section < self.sections.count{
            return self.sections[section].description
        }else{
            return "Unknown"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section < self.sections.count{
            return self.sections[section].files.count
        }else{
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCellIdentifier", for: indexPath)
        
        let urls = urlForIndexPath(indexPath)
        
        if let url = urls {
            
            let name = FileManager.default.displayName(atPath: url.path)
            let date = self.creationDate(url)
            
            
            let (dt, dis, wname) = WheelTrack.loadSummaryDistanceFromURL(url)
            
            let dh = floor(dt / 3600.0)
            var dm = ((dt - dh * 3600) / 60.0)
            dm.round()
            
            //let ds = Int(dt) % 60
            
            let sd = String(format: "%02.0f:%02.0f %@ %@",  dh, dm, UnitManager.sharedInstance.formatDistance(dis), wname)
            
            
 
            //let sd = ""
            
            // Try to get summary data
            
            cell.textLabel!.text = name
            
            if let dat = date {
                
                let fmt = DateFormatter()
                fmt.dateStyle = DateFormatter.Style.short
                fmt.timeStyle = DateFormatter.Style.short
                
                let s = fmt.string(from: dat)
                
                cell.detailTextLabel!.text = s + "  " + sd
            }
            
            
            var obj : AnyObject?
            var icon : UIImage?
            
            do{
                try (url as NSURL).getPromisedItemResourceValue(&obj, forKey: URLResourceKey.thumbnailDictionaryKey)
                
                if let dict = obj as? NSDictionary {
                    
                    icon = dict[URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey] as? UIImage
                }
                else {
                    icon = UIImage(named:"9b")
                }
            }
            catch {
                
            }
            if let img = icon {
                if let imv = cell.imageView {
                    imv.image = img
                }
            }
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 28
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    // MARK: UITableViewDelegate
    
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let url = self.sections[(indexPath as NSIndexPath).section].files[(indexPath as NSIndexPath).row]
            
            let mgr = FileManager.default
            do {
                try mgr.removeItem(at: url)
                
                self.sections[(indexPath as NSIndexPath).section].files.remove(at: (indexPath as NSIndexPath).row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                if self.sections[(indexPath as NSIndexPath).section].files.count == 0{
                    self.sections.remove(at: (indexPath as NSIndexPath).section)
                    tableView.deleteSections(IndexSet(integer: (indexPath as NSIndexPath).section), with: UITableViewRowAnimation.automatic)
                }
            }catch{
                AppDelegate.debugLog("Error removing %@", url as CVarArg)
            }
            // Delete the row from the data source
            
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        let urls = urlForIndexPath(indexPath)
        
        if let url = urls {
            
            self.currentFile = url
            
            var srcView : UIView = tableView
            
            let cellView = tableView.cellForRow(at: indexPath)
            
            if let cv = cellView   {
                
                srcView = cv
                
                for v in cv.subviews{
                    if v.isKind(of: UIButton.self){
                        srcView = v
                    }
                }
            }
            
            self.shareData(self.currentFile, src: srcView, delete: false)
        }
    }
    
    /**
        Loads the contents of an url in the datos variable in the delegate
        calling loadPackage() or loadTextFile() depending on the extension of the file (.9bm or .txt)
    
        - Parameter url : The url of the file
 
    */
    
    func openUrl(_ url : URL){
        self.currentFile = url
        if let file = self.currentFile{
            if let dele = UIApplication.shared.delegate as? AppDelegate{
                if url.pathExtension == "9bm"{
                    dele.datos.loadPackage(file)
                }
                else{
                    dele.datos.loadTextFile(file)
                }
            }
        }
        
        self.performSegue(withIdentifier: "openDataSegue", sender: self)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        let urls = urlForIndexPath(indexPath)
        
        if let url = urls {
            self.openUrl(url)
        }
    }
    
    
    
    // MARK : Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "runningDashboardSegue" {
            if let dash = segue.destination as? BLERunningDashboard{
                
                if let dele = UIApplication.shared.delegate as? AppDelegate{
                    dash.client = dele.client
                    if let cli = dele.client{
                        
                        if !cli.isRecording(){
                            cli.start()
                        }
                    }
                }
                
            }
        }else if segue.identifier == "GraphicRunningDashboardSegue" {
            if let dash = segue.destination as? BLEGraphicRunningDashboard{
                
                if let dele = UIApplication.shared.delegate as? AppDelegate{
                    dash.client = dele.client
                    
                    let store = UserDefaults.standard           // Get speedAlarm
            
                    let sa = store.double(forKey: kSpeedAlarm) * 3.6    // Speed in km/h
                    let ba = store.double(forKey: kBatteryAlarm) / 100.0    // Battery from 0 to 1
                    
                    if sa > 0.0 {
                        
                        dash.speedOK = sa
                    }
                    
                    if dash.speedTop <= dash.speedOK {
                        dash.speedTop = dash.speedOK * 1.5
                    }
                    
                    if ba > 0.0 {
                        dash.batOk = ba
                    }
                    
                    if let cli = dele.client{
                        
                       if !cli.isRecording() {
                            cli.start()
                        }
                    }
                }
                
            }
        }else if segue.identifier == "openDataSegue"{
            if let dash = segue.destination as? BLEHistoDashboard{
                if let dele = UIApplication.shared.delegate as? AppDelegate{
                    dash.ninebot = dele.datos
                }
                
                //self.startClient() // Tan sols en algun cas potser depenent del sender?
                
            }
        }
        else if segue.identifier == "settingsSegue"{
            
            if let settings = segue.destination as? SettingsViewController{
                
                settings.delegate = self
            }
        }else if segue.identifier == "testBLESegue"{
            if let testC = segue.destination as? BLEHistoDashboard{
                if let dele = UIApplication.shared.delegate as? AppDelegate{
                    
                    testC.ninebot = dele.datos
                    
                    if let url = self.currentFile{
                       
                            testC.titulo = url.lastPathComponent
                        
                    }
                }
            }
        }else if segue.identifier == "selectWheelIdentifier"{
            
            if let selector = segue.destination as? WheelSelectorTableViewController{
                selector.delegate = self
            }
        }else if segue.identifier == "localUsesSegue" {
            
            // Check here where we are. That means starting CLLocationManager and then reverse geocoding rh
            
            let url = URL(string: "http://www.gorina.es/9BMetrics/locations/barcelona.html")
            
            if let dc = segue.destination as? DocController {
                dc.url = url
            }
        }
    }
    
    // MARK: Feedback
    
    func serverStarted(){
        
    }
    
    
    func serverStopped(){
        
    }
    
    func clientStarted(){
    }
    
    func clientStopped(){
        
        
    }
    
    @IBAction func  editFiles(_ src: AnyObject){
        if self.tableView.isEditing{
            self.tableView.isEditing = false
            self.navigationItem.leftBarButtonItem!.title  = "Edit".localized()
            self.navigationItem.leftBarButtonItem!.style = UIBarButtonItemStyle.plain
        }
        else{
            self.tableView.isEditing = true
            self.navigationItem.leftBarButtonItem!.title = "Done".localized()
            self.navigationItem.leftBarButtonItem!.style = UIBarButtonItemStyle.done
        }
        
    }
    
    // Create a file with actual data and share it. Delete is useless here. It always deletes the zip file
    
    /**
        Creates a zip file (.9bz) from a package and shares it with the usual share dialog
 
        - Parameter file : The url of the package
        - Parameter src : The object to which anchor the dialog
        - Parameter delete : If the .9bz file shoud be deleted of not, Not used and always true
 
    */
 
    func shareData(_ file: URL?, src:AnyObject, delete: Bool){
        
        
        if let aFile = file {
            if aFile.pathExtension == "9bm"{
                let url = WheelTrack.createZipFile(aFile)
                shareFile(url, src: src, delete: true)
            }else {
                shareFile(aFile, src: src, delete: false)
            }
        }
    }
    
    /**
     Shares a file with the usual share dialog. Appends PickerActivity to access iCloud Server
     
     - Parameter file : The url of the package
     - Parameter src : The object to which anchor the dialog
     - Parameter delete : If file shoud be deleted of not once shared
     
     */
    
    func shareFile(_ file: URL?, src:AnyObject, delete: Bool){
        
        
        var activityItems : [URL] = []
        
        if let f = file {
            activityItems = [f]
            
            let activityViewController = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: [PickerActivity()])
            
            
            activityViewController.completionWithItemsHandler = {(a : UIActivityType?, completed:Bool, objects:[Any]?, error:Error?) in
                
                
                do{
                    if activityItems.count >= 0 && delete{
                        for item in activityItems {
                            try FileManager.default.removeItem(at: item)
                        }
                        
                    }
                }catch{
                    AppDelegate.debugLog("Error al esborrar %@", f as CVarArg)
                }
                
            }
            
            activityViewController.popoverPresentationController?.sourceView = src as? UIView
            
            activityViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            
            self.present(activityViewController,
                                       animated: true,
                                       completion: nil)
            
            
            
            
        }else {
            AppDelegate.debugLog("Error creating Zip file")
        }
        
    }
    
    /**
     Opens a file in another application
     
     - Parameter file : The url of the package
     - Parameter src : The object to which anchor the dialog
     - Parameter delete : If file shoud be deleted of not once shared. Not used
     
     */
    func openFileIn(_ file: URL, src:AnyObject, delete: Bool){
        self.docc = UIDocumentInteractionController(url: file)
        if let doc = docc{
            doc.delegate = self
            if let uv = src as? UIViewController{
                doc.presentOpenInMenu(from: uv.view.bounds, in: uv.view, animated: true)
            }
        }
        
        
    }
    
    // MARK: Other functions
    
    func appendToLog(_ s : String){
        //
        //self.tview.text = self.tview.text + "\n" + s
    }
    
    
    
    
    //MARK: View management
    
    override func viewWillAppear(_ animated: Bool) {
        
        AppDelegate.debugLog("View Controller will appear")
        
        // Listen to stop notification. Must reload files
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.hasStopped(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kStoppedRecording), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.connectionStarted(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kStartConnection), object: nil)
        
        self.navigationController?.navigationBar.isHidden = false
        
        
        if let dele = UIApplication.shared.delegate as? AppDelegate{
            
            if let docs = dele.applicationDocumentsDirectory(){
                loadLocalDirectoryData(docs as URL)
                self.tableView.reloadData()
            }
            
            if  let shortcut = dele.launchedShortcutItem {
                
                if shortcut.type == "es.gorina.9BMetrics.Record"{
                    
                    dele.launchedShortcutItem  = nil
                    AppDelegate.debugLog("Following dashboardSegue")
                    
                    openRunningDashboard(self)
                    
                    //self.performSegueWithIdentifier("runningDashboardSegue", sender: self)
                    
                }else if shortcut.type == "es.gorina.9BMetrics.Stop"{
                    dele.launchedShortcutItem  = nil
                    
                    AppDelegate.debugLog("Stopping xxx")
                    
                    if let cli = dele.client{
                        cli.stop()
                    }
                    
                }
            } else {
                
                // check if we are connected
                
                if let cli = dele.client {
                    
                    if cli.isRecording() {  // We are connected!! Load running
                        
                        //self.performSegueWithIdentifier("runningDashboardSegue", sender: self)
                    }
                }
                
            }
            
        }
        reloadFiles()
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(true)
    }
}

extension ViewController : UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
        docc = nil
    }
}

extension ViewController : UIViewControllerPreviewingDelegate{
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = tableView.indexPathForRow(at: location) {
            //This will show the cell clearly and blur the rest of the screen for our peek.
            previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
            let urls = urlForIndexPath(indexPath)
            self.currentFile = urls
            if let file = self.currentFile{
                if let dele = UIApplication.shared.delegate as? AppDelegate{
                    if file.pathExtension == "9bm"{
                        dele.datos.loadPackage(file)
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        if let  dash = storyboard.instantiateViewController(withIdentifier: "BLEHistoDashboardIdentifier") as? BLEHistoDashboard{
                            dash.ninebot = dele.datos
                            
                            return dash
                        }
                        
                    }
                }
            }
            
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {

        show(viewControllerToCommit, sender: self)
        
        
    }
    
}

extension ViewController : WheelSelectorDelegate {
    
    func selectedWheel(_ wheel: Wheel?) {
        
        // Just call run
        if let nav = self.navigationController{
            nav.popViewController(animated: false)
        }
        
        self.openRunningDashboard(self)
        
    }
}
