//
//  DetailsViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/25/22.
//

import UIKit
import MapKit
import Firebase

class DetailsViewController: UIViewController {

    @IBOutlet weak var backButtonView: UIView!
    @IBOutlet weak var imageIV: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabelTapableLinks!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var notGoingButton: UIButton!
    @IBOutlet weak var memoriesButton: UIButton!
    
    let db = Firestore.firestore()
    let docId = Auth.auth().currentUser?.uid
    var docRef: DocumentReference?
    
    var event: Event?
    var userEvents = [Event]()
    var eventId = ""
    var eventImgURL = ""
    var eventTitle = ""
    var eventDate = ""
    var eventAddress = ""
    var eventLink = ""
    var eventTickets = [[String: Any]]()
    var eventDescription = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        docRef = db.collection("users").document(docId!)
        
        if event != nil {
            eventId = event!.id
            eventImgURL = event!.thumbnail
            eventTitle = event!.title
            eventDate = event!.date
            eventAddress = event!.address
            eventLink = event!.link
            eventTickets = event!.tickets
            eventDescription = event!.description
            
            // Populate fields.
            imageIV.image = event?.image
            titleLbl.text = eventTitle
            dateLbl.text = eventDate
            locationLbl.text = eventAddress
            descriptionLbl.text = eventDescription

            // Create links to tickets.
            let attStr = NSMutableAttributedString(string: "")
            print(attStr)
            for i in 0...eventTickets.count - 1 {
                if let source = eventTickets[i]["source"] as? String, let link = eventTickets[i]["link"] as? String {
                    let attLink = NSMutableAttributedString(string: i < eventTickets.count - 1 ? "\(source)\n" : source)
                    let range = NSMakeRange(attStr.length, source.count)
                    
                    attStr.append(attLink)
                    
                    let linkCustomAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1),
                                                NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                NSAttributedString.Key.attachment: URL(string: link)!] as [NSAttributedString.Key : Any]
                    
                    attStr.addAttributes(linkCustomAttributes, range: range)
                }
            }
            
            priceLbl.attributedText = attStr
            priceLbl.delegate = self
        }
  
        userEvents = CurrentUser.currentUser?.userEvents ?? [Event]()
    
        // Set up map.
        mapView.layer.cornerRadius = 10
        
        // Get coordinates from event address
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(eventAddress) { (placemarks, error) in
            if (error != nil) {
                print("error in geocodeAddressString")
            }
            
            if !placemarks!.isEmpty {
                let placemark = placemarks?.first
                let lat = placemark?.location!.coordinate.latitude
                let lon = placemark?.location!.coordinate.longitude
                let location = CLLocation(latitude: lat!, longitude: lon!)
                
                // Create map annotation for current location.
                let locAnnotation = EventAnnotation(title: self.eventAddress, coordinate: (placemark?.location!.coordinate)!)
                
                // Update mapView with coordinates.
                self.mapView.centerToLocation(location)
                self.mapView.addAnnotation(locAnnotation)
            }
        }
        
        backButtonView.layer.cornerRadius = 10
        backButtonView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if userEvents.contains(where: { $0.title == eventTitle }) {
            // Update visible buttons.
            addButton.isHidden = true
            notGoingButton.isHidden = false
            memoriesButton.isHidden = false
        }
    }
    
    @IBAction func backTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        // Add event to userEvents array.
        if event != nil && docRef != nil {
            // Add event to user's events in Firebase.
            let data: [String: Any] = ["thumbnail": eventImgURL, "title": eventTitle, "date": eventDate, "tickets": eventTickets, "address": eventAddress, "link": eventLink, "description": eventDescription, "status": "attending", "isCreated": false, "isFavorite": false]
            
            docRef!.collection("events").addDocument(data: data) { (error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                } else {
                    self.event?.id = self.docRef!.documentID
                    
                    self.userEvents.append(self.event!)
                    CurrentUser.currentUser?.userEvents = self.userEvents
                    
                    // Update visible buttons.
                    self.addButton.isHidden = true
                    self.notGoingButton.isHidden = false
                    self.memoriesButton.isHidden = false
                    
                    print("Document added with ID: \(self.docRef!.documentID)")
                }
            }
        }
    }

    @IBAction func notGoingButtonTapped(_ sender: UIButton) {
        // Create alert.
        let alert = UIAlertController(title: "Change plans?", message: "Are you sure that you want to change your plans? Any saved memories will be deleted and this cannot be undone.", preferredStyle: .alert)
        
        // Add actions to alert controller.
        alert.addAction(UIAlertAction(title: "Keep", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { action in
            // Remove event from user's events in Firebase
            if self.docRef != nil {
                print(self.eventId)
                self.docRef!.collection("events").document(self.eventId).delete() { err in
                    if let err = err {
                        print("Error removing document: \(err)")
                    } else {
                        // Remove event from userEvents array.
                        self.userEvents.removeAll(where: { $0.id == self.eventId })
                        CurrentUser.currentUser?.userEvents = self.userEvents
                        
                        // Update visible buttons.
                        self.addButton.isHidden = false
                        self.notGoingButton.isHidden = true
                        self.memoriesButton.isHidden = true
                        
                        print("Document successfully removed!")
                    }
                }
            }
        }))
        
        // Show alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

private extension MKMapView {
    func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 200) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
    }
}

extension DetailsViewController: UILabelTapableLinksDelegate {
    func tapableLabel(_ label: UILabelTapableLinks, didTapUrl urlStr: String, atRange range: NSRange) {
        print("didTapUrl: ", urlStr)
        guard let url = URL(string: urlStr) else { return }
        UIApplication.shared.open(url)
    }
}
