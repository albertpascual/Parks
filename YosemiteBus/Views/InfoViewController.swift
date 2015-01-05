//
//  InfoViewController.swift
//  YosemiteBus
//
//  Created by Albert Pascual on 12/22/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit
import iAd
import StoreKit

 var iAdYosemite : String = "iAdYosemite"

class InfoViewController: ViewController, ADBannerViewDelegate, SKProductsRequestDelegate, SKRequestDelegate,SKPaymentTransactionObserver {

    @IBOutlet var iAdLabel: UILabel!
    @IBOutlet var iAdsSwitch: UISwitch!
    @IBOutlet var pushNotification: UISwitch!
    @IBOutlet weak var adBanner: ADBannerView!
    var request:SKProductsRequest!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Check if they purchased the way to remove Ads
        if  AdUtils.isAdHidden(adBanner) == true {
            iAdsSwitch.setOn(true, animated: false)
        }
        
       adBanner.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!)
    {
        self.adBanner.hidden = true
        self.iAdsSwitch.hidden = true
        self.iAdLabel.hidden = true
    }

    @IBAction func restorePreviousPurchases(sender: AnyObject)
    {
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    @IBAction func pushNotificationChanged(sender: AnyObject) {
        // Save it into the user defaults TODO
    }
    @IBAction func removeAdsChanged(sender: AnyObject) {
        
        
        let alert = UIAlertView(title: "Purchase", message: "You are about to purchase this bonus feature to remove all Ads", delegate: nil, cancelButtonTitle: "Cancel", otherButtonTitles: "Ok")
        alert.show()
        
        var purchase = NSSet(object: iAdYosemite)
        request = SKProductsRequest(productIdentifiers: purchase)
        request.delegate = self
        request.start()
    }

    
    func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!)
    {
        var myProducts = response.products
        println("product count \(myProducts.count)")
        
        var product1: SKProduct!
        if myProducts.count > 0 {
            product1 = myProducts[0] as SKProduct
        }
        
        if ( product1 != nil) {
            SKPaymentQueue.defaultQueue().addTransactionObserver(self)
            var payment = SKPayment(product: product1)
            SKPaymentQueue.defaultQueue().addPayment(payment)
        }
    }


    func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!)
    {
        for transaction in transactions {
            if transaction.transactionState == SKPaymentTransactionState.Purchased {
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setObject("1", forKey: iAdYosemite)
                defaults.synchronize()
            }
            else if transaction.transactionState == SKPaymentTransactionState.Failed {
                let alert = UIAlertView(title: "Purchase Error", message: transaction.error.debugDescription, delegate: nil, cancelButtonTitle: "Ok")
                alert.show()
            }
        }
    }


}
