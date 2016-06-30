//
//  GalleryCollectionViewController.swift
//  tstIngrm
//
//  Created by Круцких Олег on 29.06.16.
//  Copyright © 2016 Круцких Олег. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import Alamofire
import FastImageCache
import SwiftyJSON

private let reuseIdentifier = "Cell"

class GalleryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var username: String?
    var userID: String?
    var accessToken: String?
    let formatName = KMSmallImageFormatName
    var photos = [PhotoInfo]()
    let refreshControl = UIRefreshControl()
    var populatingPhotos = false
    var nextURLRequest: NSURLRequest?
    
    let ImageHeight: CGFloat = 200.0
    let OffsetSpeed: CGFloat = 5.0
    
    let GalleryCellIdentifier = "GalleryCell"
    let GalleryFooterViewIdentifier = "GalleryFooterView"

    
    
    func setupCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        let column = UI_USER_INTERFACE_IDIOM() == .Pad ? 4 : 3
        let itemWidth = floor((view.bounds.size.width - CGFloat(column - 1)) / CGFloat(column))
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        layout.footerReferenceSize = CGSize(width: collectionView!.bounds.size.width, height: 100.0)
        collectionView!.collectionViewLayout = layout
    }
    
    func setupView() {
        //setupCollectionViewLayout()
        /*collectionView!.registerClass(GalleryCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: GalleryCellIdentifier)*/
        collectionView!.registerClass(GalleryLoadingCollectionView.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: GalleryFooterViewIdentifier)
 
        refreshControl.tintColor = UIColor.whiteColor()
        refreshControl.addTarget(self, action: #selector(GalleryCollectionViewController.handleRefresh), forControlEvents: .ValueChanged)
        collectionView!.addSubview(refreshControl)
        handleRefresh()
    }
    
    func handleRefresh() {
        nextURLRequest = nil
        refreshControl.beginRefreshing()
        self.photos.removeAll(keepCapacity: false)
        self.collectionView!.reloadData()
        refreshControl.endRefreshing()
        
        let request = Instagram.Router.PopularPhotos(userID!, accessToken!)
        populatePhotos(request)
        
    }
    
    func populatePhotos(request: URLRequestConvertible) {
        
        if populatingPhotos {
            return
        }
        
        populatingPhotos = true
        
        Alamofire.request(request).responseJSON() {
            (response) in
            defer {
                self.populatingPhotos = false
            }
            switch response.result {
            case .Success(let jsonObject):
                debugPrint(jsonObject)
                let json = JSON(jsonObject)
                
                if (json["meta"]["code"].intValue  == 200) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                        if let urlString = json["pagination"]["next_url"].URL {
                            self.nextURLRequest = NSURLRequest(URL: urlString)
                        } else {
                            self.nextURLRequest = nil
                        }
                        let photoInfos = json["data"].arrayValue
                            
                            .filter {
                                $0["type"].stringValue == "image"
                            }.map({
                                PhotoInfo(sourceImageURL: $0["images"]["standard_resolution"]["url"].URL!)
                            })
                        
                        let lastItem = self.photos.count
                        self.photos.appendContentsOf(photoInfos)
                        
                        let indexPaths = (lastItem..<self.photos.count).map { NSIndexPath(forItem: $0, inSection: 0) }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            //self.collectionView!.insertItemsAtIndexPaths(indexPaths)
                            self.collectionView!.reloadData()
                        }
                        
                    }
                    
                }
            case .Failure:
                break;
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let patternImage = UIImage(named: "Pattern") {
            view.backgroundColor = UIColor(patternImage: patternImage)
        }
        collectionView!.backgroundColor = UIColor.clearColor()
        collectionView!.decelerationRate = UIScrollViewDecelerationRateFast
        
        setupView()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        debugPrint("username: \(username)")
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return photos.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(GalleryCellIdentifier, forIndexPath: indexPath) as! GalleryCollectionViewCell
        let sharedImageCache = FICImageCache.sharedImageCache()
        cell.imageView.image = nil
        
        let photo = photos[indexPath.row] as PhotoInfo
        if (cell.photoInfo != photo) {
            
            sharedImageCache.cancelImageRetrievalForEntity(cell.photoInfo, withFormatName: formatName)
            
            cell.photoInfo = photo
        }
        
        sharedImageCache.retrieveImageForEntity(photo, withFormatName: formatName, completionBlock: {
            (photoInfo, _, image) -> Void in
            if (photoInfo as! PhotoInfo) == cell.photoInfo {
                cell.imageView.image = image
            }
        })
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let footerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: GalleryFooterViewIdentifier, forIndexPath: indexPath) as! GalleryLoadingCollectionView
        if nextURLRequest == nil {
            footerView.spinner.stopAnimating()
        } else {
            footerView.spinner.startAnimating()
        }
        return footerView
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //let photoInfo = photos[indexPath.row]
        //performSegueWithIdentifier("show photo", sender: ["photoInfo": photoInfo])
    }
    
    /*override func scrollViewDidScroll(scrollView: UIScrollView) {
        if (self.nextURLRequest != nil && scrollView.contentOffset.y + view.frame.size.height > scrollView.contentSize.height * 0.8) {
            populatePhotos(self.nextURLRequest!)
        }
        /*if let visibleCells = collectionView!.visibleCells() as? [GalleryCollectionViewCell] {
            for parallaxCell in visibleCells {
                let yOffset = ((collectionView!.contentOffset.y - parallaxCell.frame.origin.y) / ImageHeight) * OffsetSpeed
                parallaxCell.offset(CGPointMake(0.0, yOffset))
            }
        }*/
    }*/

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}

/*class GalleryCollectionViewCell: UICollectionViewCell {
    //let imageView = UIImageView()
    var photoInfo: PhotoInfo?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageCoverView: UIView!
    
    /*required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        
        imageView.frame = bounds
        imageView.contentMode = .ScaleAspectFill
        addSubview(imageView)
    }*/
    
    /*func offset(offset: CGPoint) {
        imageView.frame = CGRectOffset(self.imageView.bounds, offset.x, offset.y)
    }*/
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        
        let featuredHeight = ParallaxLayoutConstants.Cell.featuredHeight
        let standardHeight = ParallaxLayoutConstants.Cell.standardHeight
        
        let delta: CGFloat = 1 - ((featuredHeight - CGRectGetHeight(frame)) / (featuredHeight - standardHeight))
        
        let minAlpha: CGFloat = 0.3
        let maxAlpha: CGFloat = 0.75
        
        imageCoverView!.alpha = maxAlpha - (delta * (maxAlpha - minAlpha))
        
        //let scale = max(delta, 0.5)
        //titleLabel.transform = CGAffineTransformMakeScale(scale, scale)
        
        //timeAndRoomLabel.alpha = delta
        //speakerLabel.alpha = delta
    }
    
}*/

class GalleryLoadingCollectionView: UICollectionReusableView {
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        spinner.startAnimating()
        spinner.center = self.center
        addSubview(spinner)
    }
}
