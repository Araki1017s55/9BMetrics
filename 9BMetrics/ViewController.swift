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

/**
 Main Class shows a list of runs ordered by date.
 Allows to share/export tracks, visualize data and access general settinfs
 */
 class ViewController: UIViewController , UITableViewDataSource, UITableViewDelegate{
    
    enum stateValues {
        case Waiting
        case MiM
        case Client
        case Server
    }
    
    /// Describes a file date section : Today, Yesterday, last week, last month ...
    struct fileSection {
        
        var section : Int
        var description : String
        var files : [NSURL]
    }
    
    let kTestMode = "enabled_test"
    let kDashboardMode = "dashboard_mode"
    
   
    
    // weak var ninebot : BLENinebot?
    var server : BLESimulatedServer?
    //var client : BLESimulatedClient?
    
    var state : stateValues = .Waiting
    
    var firstField = 185      // Primer camp a llegir
    var nFields = 10         // Numero de camps a llegir
    var timerStep = 0.01   // Segons per repetir el enviar
    
    var dashboard : BLENinebotDashboard?
    
    var files = [NSURL]()
    var sections = [fileSection]()
    var actualDir : NSURL?
    var currentFile : NSURL?
    
    @IBOutlet weak var tableView : UITableView!
    
    var docc : UIDocumentInteractionController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForPreviewingWithDelegate(self, sourceView: tableView)
        
        // Do any additional setup after loading the view, typically from a nib.
        let editButton = self.editButtonItem();
        editButton.target = self
        editButton.action = #selector(ViewController.editFiles(_:))
        self.navigationItem.leftBarButtonItem = editButton;
        // Lookup files
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        appDelegate?.mainController = self
        self.reloadFiles()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Called when the actual run has stopped to update runs list
    func hasStopped(not : NSNotification){
        self.reloadFiles()
    }
    
    /// Legacy...
    func connectionStarted(not : NSNotification){
        
        if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
            
            if  dele.client != nil{
                
                //self.performSegueWithIdentifier("runningDashboardSegue", sender: self)
            }
        }
    }
    
    /// Loads current document directory data into array
    func reloadFiles(){
        guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate else {return}
        guard let docsUrl = appDelegate.applicationDocumentsDirectory() else {return}
        
        loadLocalDirectoryData(docsUrl)
        
    }
    
    
    /// Returns creation date of a file
    ///
    /// - parameter url:  url of the file
    /// - returns: The creation date of the file
    func creationDate(url : NSURL) -> NSDate?{
        var rsrc : AnyObject? = nil
        
        do{
            try url.getResourceValue(&rsrc, forKey: NSURLCreationDateKey)
        }
        catch{
            AppDelegate.debugLog("Error reading creation date of file %", url)
        }
        
        let date = rsrc as? NSDate
        
        return date
        
    }
    
    /// Converts a date to a section number
    /// - Parameter dat: The date
    /// - Returns : The section number
    func dateToSection(dat : NSDate) -> Int{
        
        let today = NSDate()
        
        let calendar = NSCalendar.currentCalendar()
        
        if calendar.isDateInToday(dat){
            return 0
        }
            
        else if calendar.isDateInYesterday(dat){
            return 1
        }
            
        else if calendar.isDate(today, equalToDate: dat, toUnitGranularity: NSCalendarUnit.WeekOfYear){
            return 2
        }
        else if calendar.isDate(today, equalToDate: dat, toUnitGranularity: NSCalendarUnit.Month){
            return 3
        }
        
        // OK, here we have the normal ones. Now for older in same year we return the
        // month of the year
        
        
        let todayComponents = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month,NSCalendarUnit.Day], fromDate: today)
        
        let dateComponents = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month,NSCalendarUnit.Day], fromDate: today)
        
        if dateComponents.year == todayComponents.year {
            return 3 + todayComponents.month - dateComponents.month
        }
        
        // OK now we return just the difference in years. January of this year was
        
        return 2 + todayComponents.month + todayComponents.year - dateComponents.year
        
        
        
    }
    
    /// Converts a section number to a string label
    /// - Parameter section: The section number
    /// - Returns: The corresponding string label
    func sectionLabel(section : Int) -> String{
        
        let today = NSDate()
        
        let todayComponents = NSCalendar.currentCalendar().components(NSCalendarUnit.Day, fromDate: today)
        
        
        switch section {
            
        case 0 : return "Today"
            
        case 1:
            return "Yesterday"
            
        case 2:
            return "This Week"
            
        case 3:
            return "This Month"
            
        case 4..<(3 + todayComponents.month) :
            
            let month =  todayComponents.month + 2 - section // Indexed at 0
            let df = NSDateFormatter()
            return df.standaloneMonthSymbols[month]
            
        default :
            return String(todayComponents.year - (section - 2 - todayComponents.month))
            
            
        }
        
    }
    
    /// Processes an array of files and sort them into sections in self.sections
    /// according its *creation date*
    ///
    /// - Parameter files: The array of files
    ///
    func sortFilesIntoSections(files:[NSURL]){
        
        
        self.sections.removeAll()   // Clear all section
        
        for f in files {
            
            let date = self.creationDate(f)
            
            if let d = date{
                
                let s = self.dateToSection(d)
                
                
                while self.sections.count - 1 < s{
                    
                    let newSection = self.sections.count
                    self.sections.append(fileSection(section: newSection, description: self.sectionLabel(newSection), files: [NSURL]()))
                    
                }
                
                self.sections[s].files.append(f)
            }
        }
        
        var i = 0
        
        while i < self.sections.count {
            
            if self.sections[i].files.count == 0{
                self.sections.removeAtIndex(i)
            }else{
                i += 1
            }
        }
    }
    
    /// Checks if a file is a directory
    /// 
    /// - Parameter url : The url of the file
    /// - Returns : true or false depending if the url corresponds ot not to a directory
    func isDirectory(url : NSURL) -> Bool{
        
        var isDirectory: ObjCBool = ObjCBool(false)
        guard let path = url.path else {return false}
        
        if NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDirectory) {
            return Bool(isDirectory)
            
        }
        return false
    }
    
    /// Does the actual load of a local directory data.
    ///
    /// Updates self.actualDir, files and self.sections
    ///
    /// - Parameter dir: The URL of the directory
    ///
    func loadLocalDirectoryData(dir : NSURL){
        
        self.actualDir = dir
        
        files.removeAll()
        
        let mgr = NSFileManager()
        
        
        let enumerator = mgr.enumeratorAtURL(dir, includingPropertiesForKeys: nil, options: [NSDirectoryEnumerationOptions.SkipsHiddenFiles, NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants]) { (url:NSURL, err:NSError) -> Bool in
            AppDelegate.debugLog("Error enumerating files %@", err)
            return true
        }
        
        if let arch = enumerator{
            
            for item in arch  {
                
                if let url = item as? NSURL where !self.isDirectory(url)  || url.pathExtension == "9bm"{
                    if let ext = url.pathExtension where ext != "gpx"{
                        files.append(url)
                    }
                }
                
            }
        }
        
        // OK ara hauriem de ordenar els documents
        
        files.sortInPlace { (url1: NSURL, url2: NSURL) -> Bool in
            
            let date1 = self.creationDate(url1)
            let date2 = self.creationDate(url2)
            
            if let dat1 = date1, dat2 = date2 {
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
    func urlForIndexPath(indexPath: NSIndexPath) -> NSURL?{
        
        if indexPath.section < self.sections.count {
            let section = self.sections[indexPath.section]
            if indexPath.row < section.files.count{
                let url = section.files[indexPath.row]
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
    
    /**
        opens the running dashboard according preferences
        - Parameter src : Source of command
    */
    @IBAction func startRun(src : AnyObject){
        openRunningDashboard(self)
    }
    func openRunningDashboard(src : AnyObject?){
        let store = NSUserDefaults.standardUserDefaults()
        let graphMode = store.boolForKey(kDashboardMode)
        
        if graphMode {
            performSegueWithIdentifier("GraphicRunningDashboardSegue", sender: self)
        }else{
            performSegueWithIdentifier("runningDashboardSegue", sender: self)
        }
    }

    /**
        Builds and opens the general settings dialog
 
        - Parameter src : The origin of the event
    */
    @IBAction func openSettings(src : AnyObject){
        
        let but = src as? UIButton
        
        let store = NSUserDefaults.standardUserDefaults()
        let testMode = store.boolForKey(kTestMode)
        
        
        let alert = UIAlertController(title: "Options", message: "Select an option", preferredStyle: UIAlertControllerStyle.ActionSheet);
        
        alert.popoverPresentationController?.sourceView = but
        
        var action = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel) { (action: UIAlertAction) -> Void in
            
            
        }
        alert.addAction(action)
        
        action = UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler: { (action : UIAlertAction) -> Void in
            self.performSegueWithIdentifier("settingsSegue", sender: self)
        })
        
        alert.addAction(action)
        
        if testMode {
            
            
            action = UIAlertAction(title: "Debug Server", style: UIAlertActionStyle.Default, handler: { (action : UIAlertAction) -> Void in
                
                self.performSegueWithIdentifier("mimSegue", sender: self)
            })
            
            alert.addAction(action)
            
            action = UIAlertAction(title: "Ninebot Server", style: UIAlertActionStyle.Default, handler: { (action : UIAlertAction) -> Void in
                
                self.performSegueWithIdentifier("simulatedNinebotSegue", sender: self)
            })
            
            alert.addAction(action)
            
            
            
        }
        
        
        
        action = UIAlertAction(title: "About 9B Metrics", style: UIAlertActionStyle.Default, handler: { (action : UIAlertAction) -> Void in
            self.performSegueWithIdentifier("docSegue", sender: self)
        })
        
        alert.addAction(action)
        
        
        
        self.presentViewController(alert, animated: true) { () -> Void in
            
            
        }
        
    }
    
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return self.sections.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        if section < self.sections.count{
            return self.sections[section].description
        }else{
            return "Unknown"
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section < self.sections.count{
            return self.sections[section].files.count
        }else{
            return 0
        }
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("fileCellIdentifier", forIndexPath: indexPath)
        
        let urls = urlForIndexPath(indexPath)
        
        if let url = urls {
            
            let name = NSFileManager.defaultManager().displayNameAtPath(url.path!)
            let date = self.creationDate(url)
            
            cell.textLabel!.text = name
            
            if let dat = date {
                
                let fmt = NSDateFormatter()
                fmt.dateStyle = NSDateFormatterStyle.ShortStyle
                fmt.timeStyle = NSDateFormatterStyle.ShortStyle
                
                let s = fmt.stringFromDate(dat)
                
                cell.detailTextLabel!.text = s
            }
            
            
            var obj : AnyObject?
            var icon : UIImage?
            
            do{
                try url.getPromisedItemResourceValue(&obj, forKey: NSURLThumbnailDictionaryKey)
                
                if let dict = obj as? NSDictionary {
                    
                    icon = dict[NSThumbnail1024x1024SizeKey] as? UIImage
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
    
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 28
    }
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    // MARK: UITableViewDelegate
    
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            
            let url = self.sections[indexPath.section].files[indexPath.row]
            
            let mgr = NSFileManager.defaultManager()
            do {
                try mgr.removeItemAtURL(url)
                
                self.sections[indexPath.section].files.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                
                if self.sections[indexPath.section].files.count == 0{
                    self.sections.removeAtIndex(indexPath.section)
                    tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }catch{
                AppDelegate.debugLog("Error removing %@", url)
            }
            // Delete the row from the data source
            
            
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
        let urls = urlForIndexPath(indexPath)
        
        if let url = urls {
            
            self.currentFile = url
            
            var srcView : UIView = tableView
            
            let cellView = tableView.cellForRowAtIndexPath(indexPath)
            
            if let cv = cellView   {
                
                srcView = cv
                
                for v in cv.subviews{
                    if v.isKindOfClass(UIButton){
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
    
    func openUrl(url : NSURL){
        self.currentFile = url
        if let file = self.currentFile{
            if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
                if url.pathExtension! == "9bm"{
                    dele.datos.loadPackage(file)
                }
                else{
                    dele.datos.loadTextFile(file)
                }
            }
        }
        //self.performSegueWithIdentifier("openFileSegue", sender: self)
        
        self.performSegueWithIdentifier("openDataSegue", sender: self)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let urls = urlForIndexPath(indexPath)
        
        if let url = urls {
            self.openUrl(url)
        }
    }
    
    
    
    // MARK : Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "runningDashboardSegue" {
            if let dash = segue.destinationViewController as? BLERunningDashboard{
                
                if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
                    dash.client = dele.client
                    if let cli = dele.client{
                        
                        if !cli.connection.subscribed && !cli.connection.connecting {
                            cli.connect()
                        }
                    }
                }
                
            }
        }else if segue.identifier == "GraphicRunningDashboardSegue" {
            if let dash = segue.destinationViewController as? BLEGraphicRunningDashboard{
                
                if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
                    dash.client = dele.client
                    if let cli = dele.client{
                        
                        if !cli.connection.subscribed && !cli.connection.connecting {
                            cli.connect()
                        }
                    }
                }
                
            }
        }else if segue.identifier == "openFileSegue"{
            if let dash = segue.destinationViewController as? BLENinebotDashboard{
                if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
                    
                    dash.delegate = self
                    dash.ninebot = dele.datos
                    self.dashboard = dash
                    dash.file = self.currentFile
                }
                
                //self.startClient() // Tan sols en algun cas potser depenent del sender?
                
            }
        }else if segue.identifier == "openDataSegue"{
            if let dash = segue.destinationViewController as? BLEHistoDashboard{
                if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
                    dash.ninebot = dele.datos
                }
                
                //self.startClient() // Tan sols en algun cas potser depenent del sender?
                
            }
        }
        else if segue.identifier == "settingsSegue"{
            
            if let settings = segue.destinationViewController as? SettingsViewController{
                
                settings.delegate = self
            }
        }else if segue.identifier == "testBLESegue"{
            if let testC = segue.destinationViewController as? BLEHistoDashboard{
                if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
                    
                    testC.ninebot = dele.datos
                    
                    if let url = self.currentFile{
                        if let name = url.lastPathComponent{
                            testC.titulo = name
                        }
                    }
                }
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
    
    @IBAction func  editFiles(src: AnyObject){
        if self.tableView.editing{
            self.tableView.editing = false
            self.navigationItem.leftBarButtonItem!.title  = "Edit"
            self.navigationItem.leftBarButtonItem!.style = UIBarButtonItemStyle.Plain
        }
        else{
            self.tableView.editing = true
            self.navigationItem.leftBarButtonItem!.title = "Done"
            self.navigationItem.leftBarButtonItem!.style = UIBarButtonItemStyle.Done
        }
        
    }
    
    // Create a file with actual data and share it. Delete is useless here. It always deletes the zip file
    
    /**
        Creates a zip file (.9bz) from a package and shares it with the usual share dialog
 
        - Parameter file : The url of the package
        - Parameter src : The object to which anchor the dialog
        - Parameter delete : If the .9bz file shoud be deleted of not, Not used and always true
 
    */
 
    func shareData(file: NSURL?, src:AnyObject, delete: Bool){
        
        
        if let aFile = file {
            if aFile.lastPathComponent == "9bm"{
                let url = WheelTrack.createZipFile(aFile)
                shareFile(url, src: src, delete: true)
            }else {
                shareFile(aFile, src: src, delete: true)
            }
        }
    }
    
    /**
     Shares a file with the usual share dialog. Appends PickerActivity to access iCloud Server
     
     - Parameter file : The url of the package
     - Parameter src : The object to which anchor the dialog
     - Parameter delete : If file shoud be deleted of not once shared
     
     */
    
    func shareFile(file: NSURL?, src:AnyObject, delete: Bool){
        
        
        var activityItems : [NSURL] = []
        
        if let f = file {
            activityItems = [f]
            
            let activityViewController = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: [PickerActivity()])
            
            
            activityViewController.completionWithItemsHandler = {(a : String?, completed:Bool, objects:[AnyObject]?, error:NSError?) in
                
                
                do{
                    if activityItems.count >= 0 && delete{
                        for item in activityItems {
                            try NSFileManager.defaultManager().removeItemAtURL(item)
                        }
                        
                    }
                }catch{
                    AppDelegate.debugLog("Error al esborrar %@", f)
                }
                
            }
            
            activityViewController.popoverPresentationController?.sourceView = src as? UIView
            
            activityViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            
            self.presentViewController(activityViewController,
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
    func openFileIn(file: NSURL, src:AnyObject, delete: Bool){
        self.docc = UIDocumentInteractionController(URL: file)
        if let doc = docc{
            doc.delegate = self
            if let uv = src as? UIViewController{
                doc.presentOpenInMenuFromRect(uv.view.bounds, inView: uv.view, animated: true)
            }
        }
        
        
    }
    
    // MARK: Other functions
    
    func appendToLog(s : String){
        //
        //self.tview.text = self.tview.text + "\n" + s
    }
    
    
    
    
    //MARK: View management
    
    override func viewWillAppear(animated: Bool) {
        
        AppDelegate.debugLog("View Controller will appear")
        
        // Listen to stop notification. Must reload files
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.hasStopped(_:)), name: BLESimulatedClient.kStoppedRecording, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.connectionStarted(_:)), name: BLESimulatedClient.kStartConnection, object: nil)
        
        self.navigationController?.navigationBar.hidden = false
        
        
        if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
            
            if let docs = dele.applicationDocumentsDirectory(){
                loadLocalDirectoryData(docs)
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
                    
                    if cli.connection.subscribed {  // We are connected!! Load running
                        
                        //self.performSegueWithIdentifier("runningDashboardSegue", sender: self)
                    }
                }
                
            }
            
        }
        self.dashboard = nil // Released dashboard
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        super.viewWillDisappear(true)
    }
}

extension ViewController : UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerDidDismissOpenInMenu(controller: UIDocumentInteractionController) {
        docc = nil
    }
}

extension ViewController : UIViewControllerPreviewingDelegate{
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = tableView.indexPathForRowAtPoint(location) {
            //This will show the cell clearly and blur the rest of the screen for our peek.
            previewingContext.sourceRect = tableView.rectForRowAtIndexPath(indexPath)
            let urls = urlForIndexPath(indexPath)
            self.currentFile = urls
            if let file = self.currentFile{
                if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
                    if file.pathExtension! == "9bm"{
                        dele.datos.loadPackage(file)
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        if let  dash = storyboard.instantiateViewControllerWithIdentifier("BLEHistoDashboardIdentifier") as? BLEHistoDashboard{
                            dash.ninebot = dele.datos
                            
                            return dash
                        }
                        
                    }
                }
            }
            
        }
        return nil
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {

        showViewController(viewControllerToCommit, sender: self)
        
        
    }
    
}
