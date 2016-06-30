//
//  GalleryCollectionViewCell.swift
//  tstIngrm
//
//  Created by Круцких Олег on 30.06.16.
//  Copyright © 2016 Круцких Олег. All rights reserved.
//

import UIKit

class GalleryCollectionViewCell: UICollectionViewCell {
    var photoInfo: PhotoInfo?
    @IBOutlet weak var imageView: UIImageView!
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        
        //let scale = max(delta, 0.5)
        //titleLabel.transform = CGAffineTransformMakeScale(scale, scale)
        
        //timeAndRoomLabel.alpha = delta
        //speakerLabel.alpha = delta
    }
}
