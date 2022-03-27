//
//  ImageScrollViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 3/5/22.
//

import UIKit
import Kingfisher
import Firebase

class ImageScrollViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {

    @IBOutlet weak var trashButton: UIBarButtonItem!
    @IBOutlet weak var imageCV: UICollectionView!
    @IBOutlet weak var imageOwnerLbl: UILabel!
    @IBOutlet weak var pageCon: UIPageControl!
    
    var scrollView = UIScrollView()
    var shouldLayout = true
    
    var imgs: [Image]!
    var imageIndex: IndexPath?
    var eventId: String!
    var userId: String!
    var eventGroupId: String!
    
    var updateCV: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if imgs != nil {
            pageCon.numberOfPages = imgs!.count
            pageCon.currentPage = imageIndex!.row
            updateView()
        }
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
    
    @IBAction func trashBtnTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Delete Photo?", message: "Are you sure that you want to delete this photo? This action cannot be undone.", preferredStyle: .alert)
        // Add actions to alert controller.
        alert.addAction(UIAlertAction(title: "Keep", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { action in
            let i = self.pageCon.currentPage
            let image = self.imgs[i]
            let ref = Storage.storage().reference(forURL: self.imgs[i].imgUrl)
            
            self.imgs.remove(at: i)
            
            DispatchQueue.main.async {
                self.imageCV.reloadData()
            }

            self.updateCV?(image.imgUrl)
            
            // Delete event image from Firebase Storage.
            let storageRef = Storage.storage().reference().child("events").child(self.eventId).child(self.userId).child(ref.name)
            
            Firestore.firestore().collection("groups").document(self.eventGroupId).collection("images").document(image.userId).updateData(["imageUrls": FieldValue.arrayRemove([image.imgUrl])]) { err in
                if let err = err {
                    print("Error updating group: \(err)")
                } else {
                    print("Group successfully updated.")
                }
            }
            
            storageRef.delete { err in
                if let err = err {
                    print("Error deleting image: \(err)")
                } else {
                    print("Image successfully deleted")
                }
            }
        }))
        
        // Show alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func pageChanged(_ sender: UIPageControl) {
        let indexPath = IndexPath(item: pageCon.currentPage, section: 0)
        // Scroll to selected image.
        imageCV.isPagingEnabled = false
        imageCV.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        updateView()
        imageCV.isPagingEnabled = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Update page control.
        pageCon.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        updateView()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // Update page control.
//        imageOwnerLbl.text = "Posted by \(imageCredits?[pageCon.currentPage].keys.first! ?? "A friend")"
//        pageCon.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }
    
    private func updateView() {
        imageOwnerLbl.text = "Posted by \(imgs![pageCon.currentPage].userName)"
        
        if imgs![pageCon.currentPage].userName == "You" {
            trashButton.isEnabled = true
            trashButton.tintColor = .tintColor
        } else {
            trashButton.isEnabled = false
            trashButton.tintColor = .clear
        }
    }
    
    // MARK: - CollectionView data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imgs!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coll_cell_3", for: indexPath) as! ZoomImageCVCell
        let img = imgs![indexPath.row].image
        
        if img != nil {
            cell.imageIV.image = img
        } else {
            cell.imageIV.kf.setImage(with: URL(string: imgs![indexPath.row].imgUrl), placeholder: UIImage(named: "logo_stamp"), options: [.transition(.fade(1))], completionHandler: nil)
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
