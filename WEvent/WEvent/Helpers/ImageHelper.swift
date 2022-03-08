//
//  ImagePickerHelper.swift
//  WEvent
//
//  Created by Toby Gamble on 3/2/22.
//

import Foundation
import UIKit
import PhotosUI

protocol GetImageDelegate {
    func getImageFromUrl(imageUrl: String) -> UIImage
}

protocol GetPhotoCameraPermissionsDelegate {
    func getPhotosPermissions() async -> Bool
    func getCameraPermissions() async -> Bool
}

class GetImageHelper: GetImageDelegate, GetPhotoCameraPermissionsDelegate {
    func getImageFromUrl(imageUrl: String) -> UIImage {
        // Get event image.
        var eventImage = UIImage(named: "logo_stamp")
        
        // Check that imageUrl contains a URL string by checking for "http" in the string.
        if imageUrl.contains("http"),
           let url = URL(string: imageUrl),
           // Create URLComponent object to convert URL from "http" (not secure) to "https" (secure).
           var urlComp = URLComponents(url: url, resolvingAgainstBaseURL: false) {

            urlComp.scheme = "https"

            if let secureURL = urlComp.url {
                // Retrieve image from secureURL created above.
                do {
                    eventImage = UIImage(data: try Data.init(contentsOf: secureURL))!
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
        
        return eventImage!
    }
    
    func getPhotosPermissions() async -> Bool {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            return true
            
        case .notDetermined:
            let status = Task.init { () -> Bool in
                return await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
            }
            
            return await status.value
            
        case .limited:
            print("limited")
            return false
            
        case .restricted, .denied:
            // Present alert to notify user that photo library access is needed.
            print("restricted or denied")
            return false

        @unknown default:
            print("something else")
            // Present alert to notify user that photo library access status is unknown.
            return false
        }
    }
    
    func getCameraPermissions() async -> Bool {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authorizationStatus {
        case .authorized:
            return true
            
        case .notDetermined:
            let status = Task.init { () -> Bool in
                return await AVCaptureDevice.requestAccess(for: .video)
            }
            
            return await status.value

        case .restricted, .denied:
            print("restricted or denied")
            // Present alert to notify user that camera access is needed.
            return false
            
        @unknown default:
            print("something else")
            // Present alert to notify user that camera access status is unknown.
            return false
        }
    }
    
//    func getPicturesFromDevice(_ sender: UIBarButtonItem, vc: UIViewController) {
//        var configuration = PHPickerConfiguration()
//        // Limit media selection to only images for the time being.
//        configuration.filter = .images
//        // Allow users to select as many images as they want.
//        configuration.selectionLimit = 0
//
//        // Create instance of PHPickerViewController
//        let picker = PHPickerViewController(configuration: configuration)
//        // Set the delegate
//        picker.delegate = self
//        picker.editButtonItem.tintColor = UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1)
//        picker.navigationController?.navigationBar.barTintColor = UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1)
//        // Present the picker
//        vc.present(picker, animated: true)
//    }
//
//    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//        picker.dismiss(animated: true, completion: nil)
//
//        for result in results {
//           result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
//              if let image = object as? UIImage {
//                 DispatchQueue.main.async {
//                     // Use UIImage
//                     print("Selected image: \(image)")
////                     print(self.imageData?.description)
//                     self.imageData = image.pngData()
//                     self.imageCollection.append(image)
//                     self.mediaCV.reloadData()
//
//                     print("Checking image collection")
//                     if !self.imageCollection.isEmpty {
//                         self.msgLbl.isHidden = true
//                     }
//                 }
//              }
//           })
//        }
//    }
}

extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
}

//class ImagePickerHelper: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//
//    var imagePicker = UIImagePickerController()
//    var imageData: Data?
//
//    func setPicture(_ sender: UIButton) {
//        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
//            imagePicker.delegate = self
//            imagePicker.sourceType = .photoLibrary
//            imagePicker.allowsEditing = false
//
//            present(imagePicker, animated: true, completion: nil)
//        }
//    }
//
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        picker.dismiss(animated: true, completion: nil)
//
//        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
//            // Resize image
//            let targetSize = CGSize(width: 100, height: 100)
//            let scaledImg = image.scalePreservingAspectRatio(targetSize: targetSize)
//
//            imageData = scaledImg.pngData()
//            picIV.image = scaledImg
//        }
//    }
//}
