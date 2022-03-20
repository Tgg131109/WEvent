//
//  ImageScrollViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 3/5/22.
//

import UIKit
import Kingfisher

class ImageScrollViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {

    @IBOutlet weak var imageCV: UICollectionView!
    @IBOutlet weak var imageOwnerLbl: UILabel!
    @IBOutlet weak var pageCon: UIPageControl!
    
    var scrollView = UIScrollView()
    var shouldLayout = true
    
    var images: [UIImage]?
    var imageUrls: [String]?
    var imageCredits: [[String: UIImage]]?
    var imageIndex: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageOwnerLbl.text = "Posted by \(imageCredits?[imageIndex!.row].keys.first! ?? "A friend")"
        pageCon.numberOfPages = images!.count
        pageCon.currentPage = imageIndex!.row
    }
    
    override func viewDidLayoutSubviews() {
        if shouldLayout {
            shouldLayout = false
            // Scroll to selected image.
            imageCV.isPagingEnabled = false
            imageCV.scrollToItem(at: imageIndex!, at: .centeredHorizontally, animated: false)
            imageCV.isPagingEnabled = true
        }
    }
    
    @IBAction func pageChanged(_ sender: UIPageControl) {
        let indexPath = IndexPath(item: pageCon.currentPage, section: 0)
        // Scroll to selected image.
        imageCV.isPagingEnabled = false
        imageCV.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        imageOwnerLbl.text = "Posted by \(imageCredits?[pageCon.currentPage].keys.first! ?? "A friend")"
        imageCV.isPagingEnabled = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Update page control.
        pageCon.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        imageOwnerLbl.text = "Posted by \(imageCredits?[pageCon.currentPage].keys.first! ?? "A friend")"
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // Update page control.
//        imageOwnerLbl.text = "Posted by \(imageCredits?[pageCon.currentPage].keys.first! ?? "A friend")"
//        pageCon.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }
    
    // MARK: - CollectionView data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coll_cell_3", for: indexPath) as! ZoomImageCVCell
        let img = images![indexPath.row]
        
        if img != UIImage(named: "logo_stamp") {
            cell.imageIV.image = img
        } else {
            cell.imageIV.kf.setImage(with: URL(string: imageUrls![indexPath.row]), placeholder: UIImage(named: "logo_stamp"), options: [.transition(.fade(1))], completionHandler: nil)
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = imageCV.frame.width
        let height = imageCV.frame.height
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return  0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return  0
    }
}
