//
//  AdUtils.swift
//  YosemiteBus
//
//  Created by Al Pascual on 12/26/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit
import iAd

class AdUtils
{
 
    class func isAdHidden(iAd: ADBannerView?) -> Bool
    {
        //iAd!.hidden = true
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.objectForKey("iAdYosemite") != nil {
            if iAd != nil {
                iAd!.hidden = true
            }
            return true
        }
        
        return false
        //return true
    }
    
}
