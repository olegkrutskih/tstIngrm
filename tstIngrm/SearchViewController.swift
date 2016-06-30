//
//  SearchViewController.swift
//  tstIngrm
//
//  Created by Круцких Олег on 28.06.16.
//  Copyright © 2016 Круцких Олег. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import FastImageCache

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var userID: String?
    var accessToken: String?
    var searchingUsers = false
    let formatName = KMSmallImageFormatName
    
    @IBOutlet weak var tableView: UITableView!
    var results = [ResultString]()

    @IBOutlet weak var buttonSearch: UIButton!
    @IBOutlet weak var usernameField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        buttonSearch.enabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func valueChangeEvent(sender: UITextField) {
        buttonSearch.enabled = sender.text != ""
    }
    
    @IBAction func editingChanged(sender: UITextField) {
        buttonSearch.enabled = sender.text != ""
    }
    @IBAction func searchAction() {
        /*if ((usernameField.text != nil) && (accessToken != nil)) {
            self.performSegueWithIdentifier("showGallery", sender: ["username": usernameField.text!, "accessToken": accessToken!])
        }*/
        results.removeAll()
        let request = Instagram.Router.SearchUsers(usernameField.text!, accessToken!)
        print(request)
        searchUser(request)
    }
    
    func searchUser(request: URLRequestConvertible) {
        if searchingUsers {
            return
        }
        
        searchingUsers = true
        
        Alamofire.request(request).responseJSON() {
            (response) in
            defer {
                self.searchingUsers = false
            }
            switch response.result {
            case .Success(let jsonObject):
                debugPrint(response.request?.URLString)
                debugPrint(jsonObject)
                let json = JSON(jsonObject)
                
                if let data = json["data"].array {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                        /*if let urlString = json["pagination"]["next_url"].URL {
                            self.nextURLRequest = NSURLRequest(URL: urlString)
                        } else {
                            self.nextURLRequest = nil
                        }*/
                        
                        for d in data {
                            var u,uid: String?
                            var p: PhotoInfo?
                            for (key, object) in d {
                                switch key {
                                case "username":
                                    u = object.stringValue
                                case "id":
                                    uid = object.stringValue
                                case "profile_picture":
                                    p = PhotoInfo(sourceImageURL: d["profile_picture"].URL!)
                                default:
                                    break
                                }
                            }
                            if (u != nil && uid != nil && p != nil) {
                                let result = ResultString(username: u!, userID: uid!, photoInfo: p!)
                                self.results.append(result!)
                            }
                            
                        }
                        /*let results = json["data"].arrayValue
                            
                            .map({
                                PhotoInfo(sourceImageURL: $0["images"]["standard_resolution"]["url"].URL!)
                            })
                        
                        let lastItem = self.photos.count
                        self.photos.appendContentsOf(photoInfos)
                        
                        let indexPaths = (lastItem..<self.photos.count).map { NSIndexPath(forItem: $0, inSection: 0) }*/
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.tableView.reloadData()
                        }
                        
                    }
                    
                }
            case .Failure:
                print(response.request?.URLString)
                break
            }
            
        }
        
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showGallery" && segue.destinationViewController.isKindOfClass(GalleryCollectionViewController.classForCoder()) {
            let gViewController = segue.destinationViewController as! GalleryCollectionViewController
            
            let uid = sender?.valueForKey("userID") as? String
            //let accessToken = sender?.valueForKey("accessToken") as? String
            
            gViewController.userID = uid
            gViewController.accessToken = accessToken
             
            
        }

    }
    
    // MARK: - Table view data source
    
    /*func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }*/
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("searchViewCell", forIndexPath: indexPath) as! SearchTableCell
        cell.labelUsername.text = results[indexPath.row].username
        cell.userID = results[indexPath.row].userID
        let sharedImageCache = FICImageCache.sharedImageCache()
        cell.imageUser.image = nil
        
        let photo: PhotoInfo = results[indexPath.row].photoInfo
        if (cell.photoInfo != photo) {
            
            sharedImageCache.cancelImageRetrievalForEntity(cell.photoInfo, withFormatName: formatName)
            
            cell.photoInfo = photo
        }
        
        sharedImageCache.retrieveImageForEntity(photo, withFormatName: formatName, completionBlock: {
            (photoInfo, _, image) -> Void in
            if (photoInfo as! PhotoInfo) == cell.photoInfo {
                cell.imageUser.image = image
            }
        })
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return results.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //let username = sender?.valueForKey("username") as? String
        //let accessToken = sender?.valueForKey("accessToken") as? String
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SearchTableCell
        
        self.performSegueWithIdentifier("showGallery", sender: ["userID": cell.userID!, "accessToken": accessToken!])
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}

class SearchTableCell: UITableViewCell {
    var userID: String?
    var photoInfo: PhotoInfo?
    @IBOutlet weak var labelUsername: UILabel!
    @IBOutlet weak var imageUser: UIImageView!
}

class ResultString {
    // MARK: Properties
    
    var username: String
    var userID: String
    var photoInfo: PhotoInfo
    
    
    // MARK: Initialization
    
    init?(username: String, userID: String, photoInfo: PhotoInfo) {
        self.username = username
        self.userID = userID
        self.photoInfo = photoInfo
    }
    
}

