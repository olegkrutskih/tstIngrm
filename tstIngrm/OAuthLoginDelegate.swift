//
//  OAuthLoginDelegate.swift
//  tstIngrm
//
//  Created by Круцких Олег on 28.06.16.
//  Copyright © 2016 Круцких Олег. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import CoreData
import SwiftyJSON

class OAuthLoginDelegate: NSObject, UIWebViewDelegate {
    
    var coreDataStack = (UIApplication.sharedApplication().delegate as! AppDelegate).coreDataStack
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        //debugPrint(request.URLString)
        let urlString = request.URLString
        if let range = urlString.rangeOfString(Instagram.Router.redirectURI + "?code=") {
            
            let location = range.endIndex
            let code = urlString.substringFromIndex(location)
            debugPrint(code)
            requestAccessToken(code)
            return false
        }
        return true
    }
    
    func requestAccessToken(code: String) {
        let request = Instagram.Router.requestAccessTokenURLStringAndParms(code)
        
        Alamofire.request(.POST, request.URLString, parameters: request.Params)
            .responseJSON {
                (response) in
                switch response.result {
                case .Success(let jsonObject):
                    debugPrint(jsonObject)
                    let json = JSON(jsonObject)
                    
                    if let accessToken = json["access_token"].string, userID = json["user"]["id"].string {
                        let user = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: self.coreDataStack.context) as! User
                        user.userID = userID
                        user.accessToken = accessToken
                        self.coreDataStack.saveContext()
                        //self.performSegueWithIdentifier("unwindToPhotoBrowser", sender: ["user": user])
                        
                    }
                case .Failure(let error):
                    print("Error requestAccessToken: \(error.localizedDescription)")
                    break;
                }
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        print("webViewDidFinishLoad")
        webView.hidden = false
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        print("didFailLoadWithError: \(error?.localizedDescription)")
    }
}