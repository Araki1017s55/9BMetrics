//
//  UIViewController+Instantiate.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 19/4/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//
// Extension to easilyninstantiate view controllers from Storiboards
//
//
// Storyboard name must be the same as the class and controller must be InitialController
//
// For example if class is BLEHistoDashboard you should:
//
//      - Create a BLEHistoDashboard.storyboard storyboard
//      - Build your controller in the Storyboard
//      - Make the controller a BLEHistoDashboard and check InitialController
//
//  To use it:
//
//      if let vc = BLEHistoDashboard.instantiate() as? BLEHistoDashboard{
//
//          -- DO whatever you want configuring
//
//          either present or push navigation controller
//            navigationController?.pushViewController(vc, animated: true)
//
//                  or
//
//            present(vc, animated: true, completion: {
//              })
//


import UIKit

extension UIViewController {
    
    static func instantiate() -> UIViewController? {
        
        if let className = String(NSStringFromClass(self).components(separatedBy: ".").last!){
            
            let storyboard = UIStoryboard(name: className, bundle: nil)
        
            return storyboard.instantiateInitialViewController()
            
        }
        
        return nil
        
    }
}
