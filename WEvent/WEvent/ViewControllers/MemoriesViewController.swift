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
    var docRef: DocumentReference?
 
    var images = [UIImage]()
    var imageUrls = [String]()
    
    var eventId: String?
    var eventTitle: String?
    var eventGroupId: String?
    var eventAttendeeIds: [String]?
    var urlsToAdd = [String]()
    var selectedIP = IndexPath()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.title = eventTitle

        docRef = db.collection("users").document(eventGroupId!).collection("events").document(eventId!)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(msgLblTapped(_:)))
        
        msgLbl.addGestureRecognizer(tapRecognizer)
        msgLbl.layer.cornerRadius = 6
        msgLbl.layer.masksToBounds = true
        
        getImagesFromStorage()
        
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
            self.saveImageToFirebase(image: image, imgCount: 1)
        }
    }
    
    private func getImagesFromStorage() {
        activityView.activityIndicator.startAnimating()
        activityView.isHidden = false

        for id in eventAttendeeIds! {
            docRef!.collection("images").document(id).getDocument { (document, error) in
                if let document = document, document.exists {
                    // Get image url strings from Firebase.
                    let data = document.data()
                    guard let userImages = data?["imageUrls"] as? [String]
                    else {
                        print("Error getting user images.")
                        return
                    }
                    
                    for urlStr in userImages {
                        self.imageUrls.append(urlStr)
                        self.images.append(UIImage(named: "logo_stamp")!)
                        
                        if !self.images.isEmpty {
                            self.msgLbl.isHidden = true
                        }

                        DispatchQueue.main.async {
                            self.mediaCV.reloadData()
                        }
                    }
                } else {
                    print("Document does not exist")
                    
                    DispatchQueue.main.async {
                        self.activityView.isHidden = true
                        self.activityView.activityIndicator.stopAnimating()
                        
                        self.navigationController?.isNavigationBarHidden = false
                    }
                }
            }
        }
    }
    
    private func saveImageToFirebase(image: UIImage, imgCount: Int) {
        // Resize image
        let targetSize = CGSize(width: 100, height: 100)
        let scaledImg = image.scalePreservingAspectRatio(targetSize: targetSize)
        let imageData = scaledImg.pngData()
        
        self.images.append(scaledImg)
        self.mediaCV.reloadData()
        
        if !self.images.isEmpty {
            self.msgLbl.isHidden = true
        }
        
        let fileName = "\(UUID().uuidString).png"
        
        // Save event image to Firebase Storage.
        let storageRef = Storage.storage().reference().child("events").child(eventId!).child(userId!).child(fileName)
        let metaData = StorageMetadata()
        
        metaData.contentType = "image/png"
        
        storageRef.putData(imageData!, metadata: metaData) { (metaData, error) in
            if error == nil, metaData != nil {
                storageRef.downloadURL { url, error in
                    if let url = url {
                        self.urlsToAdd.append(url.absoluteString)
                        
                        if self.urlsToAdd.count == imgCount {
                            // Add image url strings to Firebase event or merge data if document already exists.
                            self.docRef!.collection("images").document(self.userId!).setData(["imageUrls": self.urlsToAdd], merge: true) { (error) in
                                if let error = error {
                                    print("Error saving images: \(error)")
                                } else {
                                    print("Images successfully saved.")
                                    
                                    self.urlsToAdd.removeAll()
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
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coll_cell_2", for: indexPath) as! ImageCollectionViewCell
        
        cell.imageIV.kf.indicatorType = .activity
        cell.imageIV.kf.setImage(with: URL(string: imageUrls[indexPath.row]), placeholder: UIImage(named: "logo_stamp"), options: [.transition(.fade(1))], completionHandler: { result in
            switch result {
            case .success(let value):
                self.images[indexPath.row] = value.image
                break
                
            case .failure(let error):
                print("Error getting image: \(error)")
                break
            }
        })
        
        if collectionView.numberOfItems(inSection: 0) > 0 && !activityView.isHidden {
            activityView.isHidden = true
            activityView.activityIndicator.stopAnimating()
            
            self.navigationController?.isNavigationBarHidden = false
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected \(indexPath)")
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
            destination.images = self.images
            destination.imageIndex = self.selectedIP
        }
    }
}
