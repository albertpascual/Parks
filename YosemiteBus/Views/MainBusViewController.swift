//
//  MainBusViewController.swift
//  YosemiteBus
//
//  Created by Al Pascual on 12/16/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit
import CoreLocation
import iAd
import CloudKit

class MainBusViewController: ViewController, CLLocationManagerDelegate, ADBannerViewDelegate, CloudManagerDelegate {

    @IBOutlet weak var adBanner: ADBannerView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet var firstRow: UISegmentedControl!
    @IBOutlet var secondRow: UISegmentedControl!
    @IBOutlet var thirdRow: UISegmentedControl!
    @IBOutlet var radar: CCMRadarView!
    @IBOutlet var estimatedLabel: UILabel!
    
    var busArrivedButton: SFlatButton!
    var activityLocator = HGWActivityButton(frame: CGRectMake(80, 80, 70, 70))
    var activityCalculator = HGWActivityButton(frame: CGRectMake(165, 80, 70, 70))
    var locationManager : CLLocationManager!
    var lastBusNumber : String = "0"
    var bestLocation : CLLocation!
    var bestAccuracy : Double!
    let cloudManager = CloudManager()
    var timer : NSTimer!
    var messageDisplayed = false
    var busSelected = false
    let pageViewController: PagingNavController = PagingNavController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if Wizard.runWizardIfNeeded() == true {
//            self.view.addSubview(pageViewController.view)
//            return;
//        }
        
        
        // Check if they purchased the way to remove Ads
        AdUtils.isAdHidden(adBanner)
        
        // Only for iPhone 4 and 4S
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenHeight = screenSize.height
        println("Screen size \(screenHeight)")
        if ( screenHeight == 480) {
            // iPhone 4 4s
            activityLocator = HGWActivityButton(frame: CGRectMake(80, 120, 70, 70))
            activityCalculator = HGWActivityButton(frame: CGRectMake(165, 120, 70, 70))
        }
        
        adBanner.delegate = self
        
        // Fetch the available busses
        cloudManager.delegate = self
        cloudManager.queryBusPositionsTable()
        cloudManager.queryStopsPositionsTable()
        
        // Start GPS
        self.locationManager = CLLocationManager()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.delegate = self
        if (!CLLocationManager.locationServicesEnabled()) {
            println("Location services are not enabled")
            HUDController.sharedController.contentView = HUDContentView.TextView(text: "Location services are not enabled")
            HUDController.sharedController.show()
            HUDController.sharedController.hide(afterDelay: 3.0)
        }
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
        
        // Set up rows to not be nothing selected
        self.firstRow.selectedSegmentIndex = -1
        self.secondRow.selectedSegmentIndex = -1
        self.thirdRow.selectedSegmentIndex = -1

        activityLocator.backgroundColor = UIColor.orangeColor()
        activityLocator.titleLabel.text = "Located"
        activityLocator.activityTitle = "Locating"
        activityLocator.rotatorColor = UIColor.darkGrayColor()
        activityLocator.rotatorSize = 8.0
        activityLocator.rotatorSpeed = 10.0
        activityLocator.rotatorPadding = 8.0
        activityLocator.startActivity()
        self.view.addSubview(activityLocator)
        
        activityCalculator.backgroundColor = UIColor.blueColor()
        activityCalculator.activityTitle = "Bus"
        activityCalculator.rotatorColor = UIColor.greenColor()
        activityCalculator.rotatorSize = 8.0
        activityCalculator.rotatorSpeed = 10.0
        activityCalculator.rotatorPadding = 8.0
        activityCalculator.startActivity()
        self.view.addSubview(activityCalculator)

        
        busArrivedButton = SFlatButton(frame: CGRectMake(110, 440, 110, 40), sfButtonType: SFlatButton.SFlatButtonType.SFBDanger)
        busArrivedButton.setTitle("Bus Arrived!", forState: UIControlState.Normal)
        self.view.addSubview(busArrivedButton)
        self.busArrivedButton.enabled = false
       
        busArrivedButton.addTarget(self, action: "busArrivedPressed", forControlEvents: UIControlEvents.TouchDown)
        
        self.timer =  NSTimer.scheduledTimerWithTimeInterval(20.0, target: self, selector: Selector("refresh"), userInfo: nil, repeats: true)
        
        var rate = RateMyApp.sharedInstance
        rate.appID = "954918018"
        rate.trackAppUsage()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if Reachability.isConnectedToNetwork()  {
            radar.hidden = false
            radar.startAnimation()            
        }
        else {
            HUDController.sharedController.contentView = HUDContentView.TextView(text: "No Internet connection found.")
            HUDController.sharedController.show()
            HUDController.sharedController.hide(afterDelay: 2.0)
            radar.stopAnimation()
            radar.hidden = true
        }
        
    }
    
    
    // Button pressed
    func busArrivedPressed()
    {
        if self.bestLocation == nil {
            HUDController.sharedController.contentView = HUDContentView.TextView(text: "Location required first to know where the bus is")
            HUDController.sharedController.show()
            HUDController.sharedController.hide(afterDelay: 2.0)
            return
        }
        
        var location = CLLocation()
        cloudManager.addRecord(self.lastBusNumber, time: NSDate(), postion: self.bestLocation, name: "test \(NSDate())", accuracy: self.bestAccuracy)
        
        HUDController.sharedController.contentView = HUDContentView.TextView(text: "Bus recorded, thanks!")
        HUDController.sharedController.show()
        HUDController.sharedController.hide(afterDelay: 1.0)

        
    }
    
    
    @IBAction func firstRowChanged(sender: AnyObject) {
        self.secondRow.selectedSegmentIndex = -1
        self.thirdRow.selectedSegmentIndex = -1
        setBusNumber(self.firstRow, rowNumber: 1)
    }
    
    @IBAction func secondRowChanged(sender: AnyObject) {
        self.firstRow.selectedSegmentIndex = -1
        self.thirdRow.selectedSegmentIndex = -1
        setBusNumber(self.secondRow, rowNumber: 2)
    }
    
    @IBAction func thirdRowChanged(sender: AnyObject) {
        self.firstRow.selectedSegmentIndex = -1
        self.secondRow.selectedSegmentIndex = -1
        setBusNumber(self.thirdRow, rowNumber: 3)
    }
    
    
    func setBusNumber(control : UISegmentedControl, rowNumber : Int)
    {
        // A bus was selected flag
        self.busSelected = true
        
        var valueTag = control.selectedSegmentIndex
        if ( rowNumber == 1) {
            switch(valueTag)
            {
            case 0:
               self.lastBusNumber = "1"
                break
            case 1:
                self.lastBusNumber = "2"
                break
            case 2:
                self.lastBusNumber = "3"
                break
            case 3:
                self.lastBusNumber = "4"
                break
            case 4:
                self.lastBusNumber = "5"
                break
            case 5:
                self.lastBusNumber = "6"
                break
            case 6:
                self.lastBusNumber = "7"
                break
            case 7:
                self.lastBusNumber = "8"
                break
            default:
                break
                
            }
        }
        else if rowNumber == 2 {
            switch(valueTag)
            {
            case 0:
                self.lastBusNumber = "9"
                break
            case 1:
                self.lastBusNumber = "10"
                break
            case 2:
                self.lastBusNumber = "11"
                break
            case 3:
                self.lastBusNumber = "12"
                break
            case 4:
                self.lastBusNumber = "13a"
                break
            case 5:
                self.lastBusNumber = "13b"
                break
            case 6:
                self.lastBusNumber = "14"
                break
            case 7:
                self.lastBusNumber = "15"
                break
            default:
                break
                
            }
        }
        else if rowNumber == 3 {
            switch(valueTag)
            {
            case 0:
                self.lastBusNumber = "16"
                break
            case 1:
                self.lastBusNumber = "17"
                break
            case 2:
                self.lastBusNumber = "18"
                break
            case 3:
                self.lastBusNumber = "19"
                break
            case 4:
                self.lastBusNumber = "20"
                break
            case 5:
                self.lastBusNumber = "21"
                break
            default:
                break
                
            }
        }
        
        self.estimatedLabel.text = ""
        calculateNextBus(self.lastBusNumber)
    }
    
    func refresh() {
        
        if self.lastBusNumber != "0" {
            calculateNextBus(self.lastBusNumber)
        }
        else
        {
//            HUDController.sharedController.contentView = HUDContentView.TextView(text: "No bus selected or found.")
//            HUDController.sharedController.show()
//            HUDController.sharedController.hide(afterDelay: 2.0)
            self.estimatedLabel.text = "No bus selected or found."
        }
    }
    
    func calculateNextBus(yourBusStop: String)
    {
        activityCalculator.titleLabel.text = self.lastBusNumber
        activityCalculator.stopActivity()
        
        if cloudManager.busPositionsArray != nil {
        
            // TODO, looks all the busses using the yourBusStop to Int
            var busStopNumber : Int = 0
            if yourBusStop == "13a" || yourBusStop == "13b" {
                busStopNumber = 13
            }
            else {
                busStopNumber = yourBusStop.toInt()!
            }
            
            // Grab the first bus and show it
            if ( cloudManager.busPositionsArray.count > 0) {
                var record: CKRecord = cloudManager.busPositionsArray[0] as CKRecord
                var valueStopNumber = record.objectForKey("StopNumber") as String
                var labelTime: NSDate = record.objectForKey("Time") as NSDate
                self.statusLabel.text = "The closest bus to you was seen last time at stop # \(valueStopNumber)  \(differenceInTime(labelTime))"
            }
            
            // Grab 2 different busses and calculate with the time.
            if cloudManager.busPositionsArray.count > 1 {
                var record: CKRecord = cloudManager.busPositionsArray[0] as CKRecord
                var valueStopNumber = record.objectForKey("StopNumber") as String
                for var i = 0; i<cloudManager.busPositionsArray.count; i++ {
                    var secondRecord: CKRecord = cloudManager.busPositionsArray[i] as CKRecord
                    var secondStopNumber = secondRecord.objectForKey("StopNumber") as String
                    if ( valueStopNumber != secondRecord ) {
                        // if the second bus stop is smaller and bigger than the first one
                        if ( yourBusStop.toInt() > secondStopNumber.toInt() && secondStopNumber.toInt() > valueStopNumber.toInt())
                        {
                            var labelTime: NSDate = record.objectForKey("Time") as NSDate
                            self.statusLabel.text = "Closest bus was seen at stop # \(secondStopNumber)  \(differenceInTime(labelTime)) and another bus at stop # \(valueStopNumber)"
                        }
                    }
                }
            }
            
            // TODO Grab 3 different busses and calculat with the time
            
//            //TODO
//            // If the bus postion array is sorted by time
//            var firstRecord : CKRecord!
//            var difference : Int!
//            for (var i=0; i<cloudManager.busPositionsArray.count; i++) {
//                var record: CKRecord = cloudManager.busPositionsArray[i] as CKRecord
//                var valueStopNumber = record.objectForKey("StopNumber") as String
//                if ( valueStopNumber.toInt() < busStopNumber) {
//                    firstRecord = record.copy() as CKRecord
//                    difference = busStopNumber - valueStopNumber.toInt()!
//                    break
//                }
//            }
//            
//            // The first record that is smaller
//            if firstRecord != nil {
//                var labelStopNumber = firstRecord.objectForKey("StopNumber") as String
//                println("labelstop \(labelStopNumber)")
//                var labelTime: NSDate = firstRecord.objectForKey("Time") as NSDate
//                println("time \(labelTime)")
//                self.statusLabel.text = "The closest bus to you was seen last time at stop number \(labelStopNumber) at \(labelTime)"
//                if ( difference > 0 ) {
//                    self.estimatedLabel.text = "Next estimated bus in \(difference*5) minutes"
//                }
//            }
//            // Check the numbers aren't at the end when has low numbers
//            else if (busStopNumber == 1 || busStopNumber == 2) {
//                
//                var biggest :CKRecord!
//                for (var i=0; i<cloudManager.busPositionsArray.count; i++) {
//                    var record: CKRecord = cloudManager.busPositionsArray[i] as CKRecord
//                    var valueStopNumber = record.objectForKey("StopNumber") as String
//                    if ( valueStopNumber.toInt() > 18) {
//                        
//                        if ( biggest == nil) {
//                        biggest = record.copy() as CKRecord
//                        }
//                        
//                        var tempValueNumber = record.objectForKey("StopNumber") as String
//                        var actualVAlueNumber = biggest.objectForKey("StopNumber") as String
//                        
//                        if ( tempValueNumber.toInt() > actualVAlueNumber.toInt()) {
//                            biggest = record
//                        }
//                    }
//                }
//                
//                if ( biggest != nil) {
//                    var labelStopNumber = biggest.objectForKey("StopNumber") as String
//                    println("labelstop \(labelStopNumber)")
//                    var labelTime: NSDate = biggest.objectForKey("Time") as NSDate
//                    println("time \(labelTime)")
//                    self.statusLabel.text = "Bus is very close to you at \(labelStopNumber) at \(labelTime)"
//                }
//            }
//            else {
//                if ( cloudManager.busPositionsArray.count > 0) {
//                    firstRecord = cloudManager.busPositionsArray[0] as CKRecord
//                    var labelStopNumber = firstRecord.objectForKey("StopNumber") as String
//                    println("labelstop \(labelStopNumber)")
//                    var labelTime: NSDate = firstRecord.objectForKey("Time") as NSDate
//                    println("time \(labelTime)")
//                    self.statusLabel.text = "Bad news, the closest bus is at \(labelStopNumber) at \(labelTime)"
//                }
//            }
        }
        else
        {
//            HUDController.sharedController.contentView = HUDContentView.TextView(text: "Looking for busses right now ...")
//            HUDController.sharedController.show()
//            HUDController.sharedController.hide(afterDelay: 2.0)
            
            //TODO add a timer to refresh
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // New location arrived
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
    {
        activityLocator.stopActivity()
        
        var lastLocation:CLLocation = locations[locations.count-1] as CLLocation
        self.bestAccuracy = Double(lastLocation.horizontalAccuracy)
        
        //println("Location \(lastLocation) and accuracy \(self.bestAccuracy)")
        
        // Get the best one instead of the last one
        self.bestLocation = lastLocation
        
        // Check if you are in Yosemite
        if self.busArrivedButton.enabled == false {
            
            // TODO make sure we do not enable this unless the device is in yosemite
            //self.busArrivedButton.enabled = true
            
            if ( self.bestLocation.coordinate.latitude < 36 || self.bestLocation.coordinate.latitude > 38) {
                // No in the latitude of yosemite
                if ( self.messageDisplayed == false) {
                    HUDController.sharedController.contentView = HUDContentView.TextView(text: "You are not in the Yosemite Valley")
                    HUDController.sharedController.show()
                    HUDController.sharedController.hide(afterDelay: 2.0)
                    self.messageDisplayed = true
                }
            }
            else
            {
                // TODO move the line to enable the button here
                self.busArrivedButton.enabled = true
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println(error)
        
        HUDController.sharedController.contentView = HUDContentView.TextView(text: error.description)
        HUDController.sharedController.show()
        HUDController.sharedController.hide(afterDelay: 2.0)
    }
    
    func queryWithError(error : String)
    {
        HUDController.sharedController.contentView = HUDContentView.TextView(text: "Looking for Busses failed with \(error)")
        HUDController.sharedController.show()
        HUDController.sharedController.hide(afterDelay: 2.0)
    }
    
    func queryFinishedForBusses(results : [AnyObject])
    {
        HUDController.sharedController.contentView = HUDContentView.TextView(text: "Busses found...")
        HUDController.sharedController.show()
        HUDController.sharedController.hide(afterDelay: 2.0)
        
        refresh()
    }
    
    func queryFinishedForStops(results: [AnyObject]) {
        //maybe to let the user know you got the stop
        if self.busSelected == false {
            // Let's try to find where you are 
            if ( self.bestLocation != nil ) {
                cloudManager.nearbyStopFromMe(self.bestLocation)
            }
        }
    }
    
    func stopFound(record : CKRecord)
    {
        var stopNumber = record.objectForKey("StopNumber") as String
        if ( stopNumber != "" ) {
            calculateNextBus(stopNumber)
        }
    }


    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        self.adBanner.hidden = true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
