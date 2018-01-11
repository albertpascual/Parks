//
//  ViewController.swift
//  CustomStuff
//
//  Created by Evan Dekhayser on 7/9/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	@IBAction func onBurger() {
        (tabBarController as! TabBarController).sidebar.showInViewController(viewController: self, animated: true)
    }
    
    func differenceInTime(oldTime: NSDate) -> String
    {
       // method that returns an string on the time difference
        let elapsedTime = NSDate().timeIntervalSince(oldTime as Date)
        let duration = Int(elapsedTime)
        
        let seconds = duration % 60
        let minutes = (duration / 60) % 60
        let hours = (duration / 3600)
        
        if ( hours == 0 && minutes == 0) {
            return "seen \(seconds) seconds ago"
        }
        if ( hours == 0 ) {
            return "seen \(minutes) min. \(seconds) secs ago"
        }
        
        return "seen \(hours) hours \(minutes) min. \(seconds) secs ago"
        
//        NSInteger ti = (NSInteger)interval;
//        NSInteger seconds = ti % 60;
//        NSInteger minutes = (ti / 60) % 60;
//        NSInteger hours = (ti / 3600);
//        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
    }
}

