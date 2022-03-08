//
//  ImageScrollViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 3/5/22.
//

import UIKit

class ImageScrollViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {

    @IBOutlet weak var imageCV: UICollectionView!
    @IBOutlet weak var pageCon: UIPageControl!
    
    var scrollView = UIScrollView()
    
    var images: [UIImage]?
    var imageIndex: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageCon.numberOfPages = images!.count
        pageCon.currentPage = imageIndex!.row
    }
    
    override func viewDidLayoutSubviews() {
        // Scroll to selected image.
        imageCV.isPagingEnabled = false
        imageCV.scrollToItem(at: imageIndex!, at: .centeredHorizontally, animated: false)
        imageCV.isPagingEnabled = true
    }
    
    @IBAction func pageChanged(_ sender: UIPageControl) {
        let indexPath = IndexPath(item: pageCon.currentPage, section: 0)
        
        // Scroll to selected image.
        imageCV.isPagingEnabled = false
        imageCV.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        imageCV.isPagingEnabled = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Update page control.
        pageCon.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // Update page control.
        pageCon.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }
    
    // MARK: - CollectionView data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coll_cell_3", for: indexPath) as! ImageCollectionViewCell
        
        cell.imageIV.image = images![indexPath.row]
        
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
