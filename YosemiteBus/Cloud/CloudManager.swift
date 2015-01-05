//
//  CloudManager.swift
//  YosemiteBus
//
//  Created by Al Pascual on 12/16/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit
import CloudKit

@objc protocol CloudManagerDelegate
{
    optional func queryFinishedForBusses(results : [AnyObject])
    optional func queryFinishedForStops(results : [AnyObject])    
    optional func queryWithError(error : String)
    optional func stopFound(record : CKRecord)
}

class CloudManager: NSObject {
   
    var publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    var delegate : CloudManagerDelegate! = nil
    var serialQueue = dispatch_queue_create("iCloud.Serial.Thread", DISPATCH_QUEUE_SERIAL);
    var BusLocations = "BusLocations"
    var StopLocations = "StopLocations"
    var stopLocationsArray : [AnyObject]!
    var busPositionsArray : [AnyObject]!

    
    func addRecord(stopNumber: String, time : NSDate, postion : CLLocation, name : String, accuracy : Double)
    {
        addBusPosition(stopNumber, time: time, memo: name, postion: postion)
        addUserPosition(stopNumber, time: time, postion: postion, name: name)
        addStopPosition(stopNumber, postion: postion, accuracy: accuracy)
    }
    
    
    func addBusPosition(stopNumber: String, time : NSDate, memo: String, postion : CLLocation)
    {
        var record = CKRecord(recordType: BusLocations)
        record.setObject(stopNumber, forKey: "StopNumber")
        record.setObject(time, forKey: "Time")
        record.setObject(memo, forKey: "Memo")
        record.setObject(postion, forKey: "Position")
        
        saveRecord(record)
    }
    
    func addUserPosition(stopNumber: String, time : NSDate, postion : CLLocation, name : String)
    {
        var record = CKRecord(recordType: "UserLocations")
        record.setObject(stopNumber, forKey: "StopNumber")
        record.setObject(time, forKey: "Time")
        record.setObject(postion, forKey: "Position")
        record.setObject(name, forKey: "Name")
        
        saveRecord(record)
    }
    
    func addStopPosition(stopNumber:String, postion : CLLocation, accuracy : Double)
    {
        //This is not very good, yet I have a method to clean the issues
        if self.stopLocationsArray != nil {
            for (var i=0; i < self.stopLocationsArray.count; i++) {
                var record : CKRecord  = self.stopLocationsArray[i] as CKRecord
                if record.objectForKey("StopNumber") as NSString == stopNumber {
                    record.setObject(accuracy, forKey: "Accuracy")
                    record.setObject(postion, forKey: "Position")
                    record.setObject(NSDate(), forKey: "Time")
                    saveRecord(record)
                    return
                }
            }
        }
        var record = CKRecord(recordType: StopLocations)
        record.setObject(stopNumber, forKey: "StopNumber")
        record.setObject(accuracy, forKey: "Accuracy")
        record.setObject(postion, forKey: "Position")
        record.setObject(NSDate(), forKey: "Time")
        
        saveRecord(record)
    }
    
    func saveRecord(record : CKRecord)
    {
        dispatch_async(serialQueue) {
            
            self.publicDatabase.saveRecord(record, completionHandler: { (recordBack, error) -> Void in
                
                if (error != nil) {
                    print("Error saving \(error.description)")
                    
                }
                else {
                    var theRecord:CKRecord = record as CKRecord
                    println("Record saved \(theRecord.recordType) ID: \(theRecord.recordID)")
                }
            });
            
        }
    }
    
    func queryBusPositionsTable()
    {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let sort = NSSortDescriptor(key: "Time", ascending: true)
        let query = CKQuery(recordType: StopLocations,
            predicate:  predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "Time", ascending: false)]
        
        self.publicDatabase.performQuery(query, inZoneWithID: nil) { (results, error) -> Void in
            //query back
            dispatch_async(dispatch_get_main_queue()) {
                if (error != nil && self.delegate != nil) {
                    self.delegate.queryWithError!(error.description)
                }
            
                if self.delegate != nil {
                    self.delegate.queryFinishedForBusses!(results!)
                }
                self.busPositionsArray = results
            }
        }
    }
    
    
    func queryStopsPositionsTable()
    {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: BusLocations,
            predicate:  predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "Time", ascending: false)]
        
        self.publicDatabase.performQuery(query, inZoneWithID: nil) { (results, error) -> Void in
            //query back
            dispatch_async(dispatch_get_main_queue()) {
                if (error != nil && self.delegate != nil) {
                    self.delegate.queryWithError!(error.description)
                }
            
                if ( self.delegate != nil) {
                    self.delegate.queryFinishedForStops!(results!)
                }
                self.stopLocationsArray = results
            }
        }
    }
    
    func cleanUpStopPositions()
    {
        // Carefull not to call it very often
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: BusLocations,
            predicate:  predicate)
        query.sortDescriptors = [ NSSortDescriptor(key: "StopNumber", ascending: false),NSSortDescriptor(key: "Time", ascending: false)]
        
        self.publicDatabase.performQuery(query, inZoneWithID: nil) { (results, error) -> Void in
            //query back
            dispatch_async(dispatch_get_main_queue()) {
                if (error != nil) {
                    println(error.description)
                }
                
                for var i=0; i<results.count; i++ {
                    
                    if ( i+1 < results.count) {
                        var firstRecord = results[i] as? CKRecord
                        var secondRecord = results[i+1] as? CKRecord
                        if (firstRecord != nil && secondRecord != nil) {
                            var firstStopNumber = firstRecord!.objectForKey("StopNumber") as NSString
                            var secondStopNumber = secondRecord!.objectForKey("StopNumber") as NSString
                            if ( firstStopNumber == secondStopNumber ) {
                                self.publicDatabase.deleteRecordWithID(secondRecord!.recordID, completionHandler: { (recordID, error) -> Void in
                                    //Check if is deleted
                                    if ( error != nil) {
                                        println("Error deleting \(error)")
                                    }
                                    else
                                    {
                                        println("Deleting record \(recordID) worked!")
                                    }
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    func nearbyStopFromMe(location : CLLocation)
    {
        // TODO test well
        let radiusInMeters = 300
        
        let locationPredicate = NSPredicate(format: "distanceToLocation:fromLocation:(%K,%@) < %f",
            "Position",
            location,
            radiusInMeters)
        
        let query = CKQuery(recordType: StopLocations,
            predicate:  locationPredicate)
        
        self.publicDatabase.performQuery(query, inZoneWithID: nil) {
            results, error in
            if error != nil {
                println("Error finding the bus stop at your location \(error.description)")
            } else {
                
                if ( results.count > 0 ) {
                    var record = results[0] as CKRecord
                    if ( self.delegate != nil) {
                        self.delegate.stopFound!(record)
                    }
                }
                else
                {
                    println("No bus stop found at 200 meters")
                }
            }
        }
    }
    
    // Any created record for a bus will send a notification to the application.
    func subscribeToAllNotifications()
    {
        for( var i = 1; i<=21; i++) {
            createSubscription(String(i))
        }
        
    }
    
    func createSubscription(stopNumber:String)
    {
        let predicate = NSPredicate(format: "StopNumber = '\(stopNumber)'")
        let subscription = CKSubscription(recordType: BusLocations, predicate: predicate, options: .FiresOnRecordCreation)
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertActionLocalizationKey = "LOCAL_NOTIFICATION_KEY"
        notificationInfo.shouldBadge = true
        subscription.notificationInfo = notificationInfo
        self.publicDatabase.saveSubscription(subscription, completionHandler: { (ckSubscription, error) -> Void in
            if ( error != nil) {
                println("Subscription error \(error)")
            }
            else {
                println("Subscription created for \(ckSubscription)")
            }
        })
    }
    
    func cleanUpAllRecords()
    {   
        // Delete all bus locations older than a week
        var lastWeekValue:NSDate = yesterday() //lastWeek()
        println(lastWeekValue)
        let predicate = NSPredicate(format: "Time < '\(lastWeekValue)'")
        let query = CKQuery(recordType: BusLocations,
            predicate:  predicate)
        
        self.publicDatabase.performQuery(query, inZoneWithID: nil) { (results, error) -> Void in
            //query back
            dispatch_async(dispatch_get_main_queue()) {
                if (error != nil ) {
                    println("error deleting old \(error.description)")
                    if self.delegate != nil {
                        self.delegate.queryWithError!(error.description)
                    }
                }
                
                let toDelete = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: results!)
            }
        }
    }
    
//    func lastWeek() -> NSDate
//    {
//        let cal = NSCalendar.currentCalendar()
//        var todaysDate = NSDate()
//        println(todaysDate)
//        
//        var components:NSDateComponents = cal.components(
//            NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitMinute | NSCalendarUnit.CalendarUnitSecond | NSCalendarUnit.CalendarUnitYear, fromDate: todaysDate)
//        
//        //components.day = components.day - 7
//        
//        return cal.dateFromComponents(components)!
//
//    }
    
    func yesterday() -> NSDate {
        let twoDaysAgo = NSDate(timeIntervalSinceNow: -1*24*60*60)
        
        return twoDaysAgo
    }
}
