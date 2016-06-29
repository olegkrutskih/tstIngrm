//
//  OAuthLoginViewController.swift
//  tstIngrm
//
//  Created by Круцких Олег on 28.06.16.
//  Copyright © 2016 Круцких Олег. All rights reserved.
//

import UIKit
import Alamofire
import CoreData
import SwiftyJSON

class OAuthLoginViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    let notificationCenter = NSNotificationCenter.defaultCenter()
    
    var oAuthLoginDelegate = OAuthLoginDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.delegate = oAuthLoginDelegate
        
        notificationCenter.addObserver(self, selector: #selector(OAuthLoginViewController.loginEvent), name: "loginEvent", object: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert, categories: nil))
        //self.webView.scalesPageToFit = true
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(animated: Bool) {
        print("viewWillDisappear")
    }
    
    override func viewDidAppear(animated: Bool) {
        print("viewDidAppear")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        webView.hidden = true
        NSURLCache.sharedURLCache().removeAllCachedResponses()
        if let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies {
            for cookie in cookies {
                NSHTTPCookieStorage.sharedHTTPCookieStorage().deleteCookie(cookie)
            }
        }
        
        let request = NSURLRequest(URL: Instagram.Router.requestOauthCode.URLRequest.URL!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0)
        self.webView.loadRequest(request)
    }
    
    func loginEvent(notification: NSNotification) {
        if let params = notification.userInfo {
            if let _ = params["userID"], let _ = params["accessToken"] {
                self.performSegueWithIdentifier("ShowSearchDialog", sender: params)
            }
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowSearchDialog" && segue.destinationViewController.isKindOfClass(SearchViewController.classForCoder()) {
            let sViewController = segue.destinationViewController as! SearchViewController
            
            let userID = sender?.valueForKey("userID") as! String
            let accessToken = sender?.valueForKey("accessToken") as! String
            sViewController.userID = userID
            sViewController.accessToken = accessToken
        }
    }
}
