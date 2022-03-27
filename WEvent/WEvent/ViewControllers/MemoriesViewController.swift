//
//  MemoriesViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 3/4/22.
//

import UIKit
import PhotosUI
import Firebase
import Kingfisher

class MemoriesViewController: UIViewController, PHPickerViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var activityView: CustomActivityIndicatorView!
    @IBOutlet weak var msgLbl: UILabel!
    @IBOutlet weak var mediaCV: UICollectionView!
    
    let db = Firestore.firestore()
    let userId = Auth.auth().currentUser?.uid
    var collRef: CollectionReference?
    
    var imgs = [Image]()
    
    var eventId: String?
    var eventTitle: String?
    var eventGroupId: String?
    var eventAttendeeIds: [String]?
    var urlCount = 0
    var userUrls = [String]()
    var selectedIP = IndexPath()
    
    var getPhotos = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = eventTitle
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(msgLblTapped(_:)))
        
        msgLbl.addGestureRecognizer(tapRecognizer)
        msgLbl.layer.cornerRadius = 6
        msgLbl.layer.masksToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if getPhotos {
            collRef = db.collection("groups").document(eventGroupId!).collection("images")
            getImagesFromStorage()
        }
    }
    
    @objc func msgLblTapped(_ sender: Any) {
        getPictures(sender)
    }
    
    @IBAction func getPictures(_ sender: Any) {
        let getPermissionsDelegate: GetPhotoCameraPermissionsDelegate! = GetImageHelper()
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a Source", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction) in
            Task.init {
                if await getPermissionsDelegate.getPhotosPermissions() {
                    var configuration = PHPickerConfiguration()
                    // Limit media selection to only images for the time being.
                    configuration.filter = .images
                    // Allow users to select as many images as they want.
                    configuration.selectionLimit = 0
                    
                    // Create instance of PHPickerViewController
                    let picker = PHPickerViewController(configuration: configuration)
                    // Set the delegate
                    picker.delegate = self
                    // Present the picker
                    self.present(picker, animated: true)
                }
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Task.init {
                    if await getPermissionsDelegate.getCameraPermissions() {
                        let imagePicker = UIImagePickerController()
                        
                        imagePicker.delegate = self
                        imagePicker.sourceType = .camera
                        
                        self.getPhotos = false
                        
                        self.present(imagePicker, animated: true)
                    }
                }
            } else {
                // Create alert.
                let alert = UIAlertController(title: "No Camera", message: "Camera is not available on this device.", preferredStyle: .alert)
                // Add action to alert controller.
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // Show alert.
                self.present(alert, animated: true, completion: nil)
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        for result in results {
           result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
              if let image = object as? UIImage {
                 DispatchQueue.main.async {
                     self.saveImageToFirebase(image: image, imgCount: results.count)
                 }
              }
           })
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            DispatchQueue.main.async {
                self.saveImageToFirebase(image: image, imgCount: 1)
            }
        }
    }
    
    private func getImagesFromStorage() {
        activityView.activityIndicator.startAnimating()
        activityView.isHidden = false

        for id in eventAttendeeIds! {
            collRef?.document(id).getDocument { (document, error) in
                if let document = document, document.exists {
                    // Get image url strings from Firebase.
                    let data = document.data()
                    guard let userImages = data?["imageUrls"] as? [String]
                    else {
                        print("Error getting user images.")
                        return
                    }
                    
                    if id == self.userId {
                        self.userUrls = userImages
                    }
                    
                    for urlStr in userImages {
                        self.imgs.append(Image(imgUrl: urlStr, userId: id))
                        
                        if !self.imgs.isEmpty {
                            self.msgLbl.isHidden = true
                        }
                        
                        DispatchQueue.main.async {
                            self.mediaCV.reloadData()
                        }
                    }
                } else {
                    print("User has no photos for this event")
                }
            }
        }
        
        DispatchQueue.main.async {
            self.activityView.isHidden = true
            self.activityView.activityIndicator.stopAnimating()
            
            self.navigationController?.isNavigationBarHidden = false
        }
    }
    
    private func saveImageToFirebase(image: UIImage, imgCount: Int) {
        // Resize image
        let targetSize = CGSize(width: 100, height: 100)
        let scaledImg = image.scalePreservingAspectRatio(targetSize: targetSize)
        let imageData = scaledImg.pngData()
        
        self.imgs.append(Image(image: scaledImg, imgUrl: "", userId: self.userId!))
        
//        self.images.append(scaledImg)
//        self.imageCredits.append(["You": scaledImg])
        
//        if let i = self.eventAttendeeIds?.firstIndex(where: { $0 == userId }) {
//            self.imageAssocs.append(i)
//        }
        
        DispatchQueue.main.async {
            self.mediaCV.reloadData()
        }
        
        self.msgLbl.isHidden = !self.imgs.isEmpty
        
//        self.msgLbl.isHidden = !self.images.isEmpty
      
        let fileName = "\(UUID().uuidString).png"
        
        // Save event image to Firebase Storage.
        let storageRef = Storage.storage().reference().child("events").child(eventId!).child(userId!).child(fileName)
        let metaData = StorageMetadata()
        
        metaData.contentType = "image/png"
        
        storageRef.putData(imageData!, metadata: metaData) { (metaData, error) in
            if error == nil, metaData != nil {
                storageRef.downloadURL { url, error in
                    if let url = url {
                        self.urlCount += 1
                        self.imgs.first(where: { $0.imgUrl == "" })?.imgUrl = url.absoluteString
                        self.userUrls.append(url.absoluteString)
//                        self.imageUrls.append(url.absoluteString)
                        
                        if self.urlCount == imgCount {
                            // Add image url strings to Firebase event or merge data if document already exists.
                            self.collRef?.document(self.userId!).setData(["imageUrls": self.userUrls]) { (error) in
                                if let error = error {
                                    print("Error saving image: \(error)")
                                } else {
                                    print("Image successfully saved.")
                                    
                                    self.urlCount = 0
                                }
                            }
                        }
                    }
                }
            } else {
                // Print error if upload fails.
                print(error?.localizedDescription ?? "There was an issue uploading photo.")
            }
        }
    }
    
    // MARK: - CollectionView data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imgs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coll_cell_2", for: indexPath) as! ImageCollectionViewCell

//        if imgs.count > indexPath.row {
//        if imageUrls.count > indexPath.row {
            cell.imageIV.kf.indicatorType = .activity
            cell.imageIV.kf.setImage(with: URL(string: imgs[indexPath.row].imgUrl), placeholder: imgs[indexPath.row].image == nil ? UIImage(named: "logo_stamp") : imgs[indexPath.row].image, options: [.transition(.fade(1))], completionHandler: { result in
//            cell.imageIV.kf.setImage(with: URL(string: imageUrls[indexPath.row]), placeholder: UIImage(named: "logo_stamp"), options: [.transition(.fade(1))], completionHandler: { result in
                switch result {
                case .success(let value):
                    self.imgs[indexPath.row].image = value.image
                    
//                    self.images[indexPath.row] = value.image
//
//                    let keys = self.imageCredits[indexPath.row].keys
//
//                    self.imageCredits[indexPath.row][keys.first!] = value.image
                    break
                    
                case .failure(let error):
                    if !error.isTaskCancelled && !error.isNotCurrentTask {
                        print("Error getting image: \(error)")
                    }
                    break
                }
            })
            
        cell.userIV.image = imgs[indexPath.row].userProfilePic
//            cell.userIV.image = memberProfilePics[imageAssocs[indexPath.row]]
//        } else {
//            cell.imageIV.image = images[indexPath.row]
//            cell.userIV.image = CurrentUser.currentUser?.profilePic
//        }
        
        if collectionView.numberOfItems(inSection: 0) > 0 && !activityView.isHidden {
            activityView.isHidden = true
            activityView.activityIndicator.stopAnimating()
            
            self.navigationController?.isNavigationBarHidden = false
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIP = indexPath
        self.performSegue(withIdentifier: "goToImage", sender: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width
        let cellSize = (width / 3) - 2
        
        return CGSize(width: cellSize, height: cellSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return  2
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return  2
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ImageScrollViewController {
            // Send selected event and userEvents array to DetailsViewController.
            destination.imgs = self.imgs
            destination.imageIndex = self.selectedIP
            destination.userId = self.userId
            destination.eventId = self.eventId
            destination.eventGroupId = self.eventGroupId
            destination.updateCV = { urlStr in
                self.imgs.removeAll(where: { $0.imgUrl == urlStr })
                self.userUrls.removeAll(where: { $0 == urlStr })
                print("removing on memories page")
                self.mediaCV.reloadData()
            }
            
            self.getPhotos = false
        }
    }
}
