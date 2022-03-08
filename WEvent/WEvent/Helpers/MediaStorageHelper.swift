//
//  MediaStorageHelper.swift
//  WEvent
//
//  Created by Toby Gamble on 3/2/22.
//

import Foundation
import UIKit
import Firebase

protocol SaveImageDelegate {
    
}

class MediaStorageHelper: SaveImageDelegate {
    func saveImageToFirebase(eventId: String, imageName: String) {
        let docId = Auth.auth().currentUser?.uid
        // Save event image to Firebase Storage.
        let storageRef = Storage.storage().reference().child("events").child(eventId).child(docId!).child(imageName)
        let metaData = StorageMetadata()
        
        metaData.contentType = "image/png"
        
//        if self.imageData == nil {
//            self.imageData = self.image.pngData()
//        }
//        
//        storageRef.putData(self.imageData!, metadata: metaData) { (metaData, error) in
//            if error == nil, metaData != nil {
//                storageRef.downloadURL { url, error in
//                    if let url = url {
//                        // Update created event in Firebase with url string.
//                        self.docRef?.collection("events").document(self.eventId).updateData(["thumbnail": url.absoluteString]) { err in
//                            if let err = err {
//                                print("Error adding image: \(err)")
//                            } else {
//                                // Update event in user's current events.
//                                CurrentUser.currentUser?.userEvents?.first(where: { $0.id == self.eventId })?.image = self.image
//
//                                print("Image successfully added")
//                            }
//                        }
//                    }
//                }
//            } else {
//                // Print error if upload fails.
//                print(error?.localizedDescription ?? "There was an issue uploading photo.")
//            }
//        }
    }
}

//extension UIImage {
//    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
//        // Determine the scale factor that preserves aspect ratio
//        let widthRatio = targetSize.width / size.width
//        let heightRatio = targetSize.height / size.height
//        
//        let scaleFactor = min(widthRatio, heightRatio)
//        
//        // Compute the new image size that preserves aspect ratio
//        let scaledImageSize = CGSize(
//            width: size.width * scaleFactor,
//            height: size.height * scaleFactor
//        )
//
//        // Draw and return the resized UIImage
//        let renderer = UIGraphicsImageRenderer(
//            size: scaledImageSize
//        )
//
//        let scaledImage = renderer.image { _ in
//            self.draw(in: CGRect(
//                origin: .zero,
//                size: scaledImageSize
//            ))
//        }
//        
//        return scaledImage
//    }
//}
