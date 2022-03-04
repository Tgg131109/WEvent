//
//  ImagePickerHelper.swift
//  WEvent
//
//  Created by Toby Gamble on 3/2/22.
//

import Foundation
import UIKit

protocol GetImageDelegate {
    func getImageFromUrl(imageUrl: String) -> UIImage
}

class GetImageHelper: GetImageDelegate {
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
