//
//  Common.swift
//  tstIngrm
//
//  Created by Круцких Олег on 28.06.16.
//  Copyright © 2016 Круцких Олег. All rights reserved.
//

import Foundation
import Alamofire
import UIKit
import CoreData

struct ParallaxLayoutConstants {
    struct Cell {
        /* non-featured cell */
        static let standardHeight: CGFloat = 100
        /* first visible cell */
        static let featuredHeight: CGFloat = 280
    }
}

struct Instagram {
    
    enum Router: URLRequestConvertible {
        static let baseURLString = "https://api.instagram.com"
        static let clientID = "f35f847705604853b22e652a0ac1adc0"
        static let redirectURI = "http://example.com/"
        static let clientSecret = "352c388272064b71858fd8d5c002bad9"
        
        case PopularPhotos(String, String)
        case SearchUsers(String, String)
        case requestOauthCode
        
        static func requestAccessTokenURLStringAndParms(code: String) -> (URLString: String, Params: [String: AnyObject]) {
            let params = ["client_id": Router.clientID, "client_secret": Router.clientSecret, "grant_type": "authorization_code", "redirect_uri": Router.redirectURI, "code": code]
            let pathString = "/oauth/access_token"
            let urlString = Instagram.Router.baseURLString + pathString
            return (urlString, params)
        }
        
        // MARK: URLRequestConvertible
        
        var URLRequest: NSMutableURLRequest {
            let result: (path: String, parameters: [String: AnyObject]?) = {
                switch self {
                case .PopularPhotos (let userID, let accessToken):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/users/" + userID + "/media/recent"
                    return (pathString, params)
                    
                case .SearchUsers (let username, let accessToken):
                    let params = ["q": username, "access_token": accessToken]
                    let pathString = "/v1/users/search"
                    return (pathString, params)
                    
                case .requestOauthCode:
                    let pathString = "/oauth/authorize/?client_id=" + Router.clientID + "&redirect_uri=" + Router.redirectURI + "&response_type=code&scope=public_content"
                    return (pathString, nil)
                    
                
                }
            }()
            
            let BaseURL = NSURL(string: Router.baseURLString)!
            let URLRequest = NSURLRequest(URL: BaseURL.URLByAppendingPathComponent(result.path))
            let encoding = Alamofire.ParameterEncoding.URL
            return encoding.encode(URLRequest, parameters: result.parameters).0
        }
    }
    
}

extension Alamofire.Request {
    public static func imageResponseSerializer() -> ResponseSerializer<UIImage, NSError> {
        return ResponseSerializer { request, response, data, error in
            guard let validData = data where validData.length > 0 else {
                return .Failure(Request.imageDataError())
            }
            
            if let image = UIImage(data: validData, scale: UIScreen.mainScreen().scale) {
                return Result<UIImage, NSError>.Success(image)
            }
            else {
                return .Failure(Request.imageDataError())
            }
            
        }
    }
    
    public func responseImage(completionHandler: Response<UIImage, NSError> -> Void) -> Self {
        return response(responseSerializer: Request.imageResponseSerializer(), completionHandler: completionHandler)
    }
    
    private class func imageDataError() -> NSError {
        let failureReason = "Failed to create a valid Image from the response data"
        return Error.errorWithCode(NSURLErrorCannotDecodeContentData, failureReason: failureReason)
    }
}

class User: NSManagedObject {
    
    @NSManaged var userID: String
    @NSManaged var accessToken: String
    
}
