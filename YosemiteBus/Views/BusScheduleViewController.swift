//
//  BusScheduleViewController.swift
//  YosemiteBus
//
//  Created by Al Pascual on 12/17/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit
import CloudKit

class BusScheduleViewController: ViewController, UITableViewDataSource, UITableViewDelegate, CloudManagerDelegate {

    @IBOutlet var tableView: UITableView!
    let cloudManager = CloudManager()
    var results : [AnyObject]!
    @IBOutlet var backgroundImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cloudManager.delegate = self
        
        tableView.addPullToRefreshWithAction({
            NSOperationQueue().addOperationWithBlock {
                sleep(2)
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.tableView.stopPullToRefresh()
                    self.cloudManager.queryBusPositionsTable()
                }
            }
            }, withAnimator: PacmanAnimator())
        
//        let image = UIImage(gradientColors: [UIColor(red: 0.808, green: 0.863, blue: 0.902, alpha: 1.0), UIColor(red: 0.349, green: 0.412, blue: 0.443, alpha: 1.0)], size: CGSize(width: backgroundImage.frame.width, height: backgroundImage.frame.height))
//        backgroundImage.image = image
    }
    
    override func viewDidAppear(animated: Bool) {        
        cloudManager.queryBusPositionsTable()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func queryFinishedForBusses(results : [AnyObject])
    {
        self.results = results
        self.tableView.reloadData()
    }
    
    
    func queryWithError(error : String)
    {
        println("Error \(error)")
        HUDController.sharedController.contentView = HUDContentView.TextView(text: "Cannot access the server or there is no bus info yet. This app requires an iCloud account")
        HUDController.sharedController.show()
        HUDController.sharedController.hide(afterDelay: 2.0)
    }
    
    //Table
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if self.results != nil {
            return self.results.count
        }
        return 0
    }
        
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "Cell")
        var record : CKRecord  = self.results[indexPath.row] as CKRecord
        //if record != nil {
            var stopNumber = record.valueForKey("StopNumber") as String
        
            cell.textLabel?.text = "Bus found last at # \(stopNumber)"
        
//            var position : CLLocation? = record.valueForKey("Position") as? CLLocation
//            if ( position != nil ) {
//                cell.detailTextLabel?.text = "\(position!)"
//            }
//            else {
//                cell.detailTextLabel?.text = "No found"
//            }
            var myTime : NSDate = record.valueForKey("Time") as NSDate
            //cell.detailTextLabel?.text = "\(myTime)"
            cell.detailTextLabel?.text = differenceInTime(myTime)
            cell.imageView?.image = UIImage(named: "bus.png")
       // }
        return cell
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 80
    }
    
}
