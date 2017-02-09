//
//  WheelTrackDatabase.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 2/2/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import Foundation
import Foundation
import UIKit

class WheelTrackDatabase  : SimpleObjectDatabase<String, WheelTrackSummary>{
    
    static let sharedInstance = WheelTrackDatabase()
    
    override init(){
        
        // Load archive
        if let dele =  UIApplication.shared.delegate as? AppDelegate{
            if let docs = dele.applicationDocumentsDirectory(){
                let url = docs.appendingPathComponent("tracks")

                super.init(url: url)
                
                // Now it has been read. If count == 0 -> Rebuild
                
                if count() == 0{
                    rebuild(docs)
                }
            } else {
                super.init()
            }
        } else {
            super.init()
        }
        
    }
    
    func rebuild(){
        if let dele =  UIApplication.shared.delegate as? AppDelegate{
            if let docs = dele.applicationDocumentsDirectory(){
                    rebuild(docs)

            }
        }        
    }
   
    func rebuild(_ dir : URL){
        
        removeAll()
        
        var files = [URL]()
        
        
            
        let mgr = FileManager()
            
        let enumerator = mgr.enumerator(at: dir, includingPropertiesForKeys: nil, options: [FileManager.DirectoryEnumerationOptions.skipsHiddenFiles, FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants]) { (URL, Error) -> Bool in
                
            let err = Error as NSError
                AppDelegate.debugLog("Error enumerating files %@", err.localizedDescription)
                return true
        }
            
        if let arch = enumerator{
                
            for item in arch  {
                    
                if let url = item as? URL , !self.isDirectory(url)  || url.pathExtension == "9bm"{
                    if url.pathExtension  != "gpx" && url.lastPathComponent != "wheels" && url.lastPathComponent != "tracks"{
                        files.append(url)
                    }
                }
                    
            }
        }
            
            // OK ara Obtenim les dades de cada document  
        
        for url in files {
            
            let (dt, dist, nom, dat, adp) = WheelTrack.loadSummaryDistanceFromURL(url)
            
            let ts = WheelTrackSummary()
            ts.name = nom
            ts.duration = dt
            ts.distance = dist
            ts.date = dat
            ts.pathname = url.lastPathComponent
            ts.adapter = adp
            
            addObjectWithoutSaving(ts)
        }
        
        save()
        
    }
    
    override func read(){
        do {
             try super.read()
        }catch {
            self.rebuild()
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
    

}
