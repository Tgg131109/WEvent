//
//  CustomCollectionViewCell.swift
//  WEvent
//
//  Created by Toby Gamble on 2/24/22.
//

import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var eventImageIV: UIImageView!
    @IBOutlet weak var eventDateLbl: UILabel!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var eventAddressLbl: UILabel!
}

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageIV: UIImageView!
    @IBOutlet weak var userIV: CustomImageView!
//    @IBOutlet weak var scrollView: UIScrollView!
    
    var isZooming = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
//        let panGR = UIPanGestureRecognizer(target: self, action: #selector(self.pan(sender:)))
        imageIV.addGestureRecognizer(pinchGR)
//        imageIV.addGestureRecognizer(panGR)
    }
    
    @objc func pinch(sender:UIPinchGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            let currentScale = self.imageIV.frame.size.width / self.imageIV.bounds.size.width
            let newScale = currentScale*sender.scale
            let transform = CGAffineTransform(scaleX: newScale, y: newScale)
            if newScale > 1 {
                self.isZooming = true
            }
            self.imageIV.transform = transform
            sender.scale = 1
        }
    }
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        if(isZooming){
            if self.isZooming && sender.state == .began {
//                self.originalImageCenter = sender.view?.center
            } else if self.isZooming && sender.state == .changed {
                let translation = sender.translation(in: self)
                if let view = sender.view {
                    view.center = CGPoint(x:view.center.x +
                                          translation.x,
                                          y:view.center.y +
                                          translation.y)
                }
                sender.setTranslation(CGPoint.zero, in:
                                        self.imageIV.superview)
            }
        }else{
            print("blocked pan")
        }
   }
}

class ZoomImageCVCell: UICollectionViewCell, UIScrollViewDelegate {
    @IBOutlet weak var imageIV: UIImageView!
    @IBOutlet weak var userIV: CustomImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 4.0
        self.scrollView.delegate = self
//        let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
//        imageIV.addGestureRecognizer(pinchGR)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageIV
    }
}
