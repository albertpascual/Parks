//
//  Wizard.swift
//  YosemiteBus
//
//  Created by Al Pascual on 12/31/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit

class Wizard: NSObject {
   
    class func runWizardIfNeeded() -> Bool
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.objectForKey("wizard") == nil {
            
            // Run it
            defaults.setInteger(1, forKey: "wizard")
            defaults.synchronize()
            
            return true
        }
        
        return true
    }
}
