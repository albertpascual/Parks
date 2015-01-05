//
//  StopPositionsViewController.swift
//  YosemiteBus
//
//  Created by Al Pascual on 12/18/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit
import CloudKit

class StopPositionsViewController: ViewController, UITableViewDataSource, UITableViewDelegate, CloudManagerDelegate {

    @IBOutlet var tableView: UITableView!
    let cloudManager = CloudManager()
    var results : [AnyObject]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cloudManager.delegate = self
       
        tableView.addPullToRefreshWithAction({
            NSOperationQueue().addOperationWithBlock {
                sleep(2)
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.tableView.stopPullToRefresh()
                    self.cloudManager.queryStopsPositionsTable()
                }
            }
            }, withAnimator: PacmanAnimator())
    }

    
    override func viewDidAppear(animated: Bool) {
        cloudManager.cleanUpStopPositions()
        cloudManager.queryStopsPositionsTable()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func queryFinishedForStops(results : [AnyObject])
    {
        self.results = results
        tableView.reloadData()
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
        var position : CLLocation = record.valueForKey("Position") as CLLocation
        var myTime : NSDate = record.valueForKey("Time") as NSDate
        cell.textLabel?.text = "Stop # \(stopNumber)"
        cell.detailTextLabel?.text = differenceInTime(myTime)
        cell.imageView?.image = UIImage(named: "stop")
        // }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 70
    }
    

}
