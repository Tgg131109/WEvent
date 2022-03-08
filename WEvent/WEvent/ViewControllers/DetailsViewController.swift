//
//  DetailsViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/25/22.
//

import UIKit
import MapKit
import Firebase
import LinkPresentation

class DetailsViewController: UIViewController, UIActivityItemSource {

    @IBOutlet weak var backButtonView: UIView!
    @IBOutlet weak var imageIV: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabelTapableLinks!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var groupLbl: UILabel!
    @IBOutlet weak var inviteBtn: UIButton!
    @IBOutlet weak var attendeeIV0: UIImageView!
    @IBOutlet weak var attendeeIV1: UIImageView!
    @IBOutlet weak var attendeeIV2: UIImageView!
    @IBOutlet weak var attendeeIV3: UIImageView!
    @IBOutlet weak var attendeeIV4: UIImageView!
    @IBOutlet weak var attendeeIV5: UIImageView!
    @IBOutlet weak var attendeeIV6: UIImageView!
    @IBOutlet weak var attendeeIV7: UIImageView!
    @IBOutlet weak var additonalAttendeesLbl: UILabel!
    @IBOutlet weak var stdButtonView: UIView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var notGoingButton: UIButton!
    @IBOutlet weak var memoriesButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var favButton: UIButton!
    @IBOutlet weak var pendingButtonView: UIView!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    let db = Firestore.firestore()
    let userId = Auth.auth().currentUser?.uid
    var docRef: DocumentReference?
    
    var event: Event?
    var allUserEvents = [Event]()
    var eventId = ""
    var eventImgURL = ""
    var eventTitle = ""
    var eventDate = ""
    var eventAddress = ""
    var eventLink = ""
    var eventTickets = [[String: Any]]()
    var eventDescription = ""
    var eventGroupId = ""
    var eventAttendeeIds = [String]()
    var attendeeIVs = [UIImageView]()
    var isFav = Bool()
    var isCreated = Bool()
    var metadata: LPLinkMetadata?
    
    var shouldEdit = false
    var editEvent: (() -> Void)?

    var favoritesDelegate: FavoritesDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        allUserEvents = CurrentUser.currentUser?.userEvents ?? [Event]()
        docRef = db.collection("users").document(userId!)
        favoritesDelegate = FirebaseHelper()
        
        populateFields()
        configureMapView()

        backButtonView.layer.cornerRadius = 10
        backButtonView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        
        let buttonViewToShow = event?.status == "pending" ? pendingButtonView : stdButtonView
        
        view.addSubview(buttonViewToShow!)
        
        NSLayoutConstraint.activate([
            buttonViewToShow!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonViewToShow!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonViewToShow!.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        if event?.status == "attending" {
            // Update visible buttons.
            editButton.isHidden = !isCreated
            addButton.isHidden = true
            notGoingButton.isHidden = false
            memoriesButton.isHidden = false
        }
        
        favButton.isSelected = isFav
        favButton.tintColor = favButton.isSelected ? UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1) : .systemGray
    }
    
    @IBAction func backTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        editEvent?()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        // Add event to userEvents array.
        if event != nil && docRef != nil {
            // Action if event is already saved as a favorite.
            if self.isFav {
                // Find document in Firebase and update status field.
                self.docRef!.collection("events").document(self.eventId).updateData(["status": "attending"]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        // Update event status property and update current user's events to match.
                        if let index = self.allUserEvents.firstIndex(where: { $0.id == self.eventId }) {
                            self.allUserEvents[index].status = "attending"
                            self.allUserEvents[index].groupId = self.userId!
                            self.allUserEvents[index].attendeeIds = [self.userId!]
                            
                            CurrentUser.currentUser?.userEvents = self.allUserEvents
                            
                            print("Document successfully updated")
                        }
                    }
                }
            } else {
                // Add event to user's events in Firebase.
                let data: [String: Any] = ["thumbnail": eventImgURL, "title": eventTitle, "date": eventDate, "tickets": eventTickets, "address": eventAddress, "link": eventLink, "description": eventDescription, "groupID": userId!, "attendeeIds": [userId!], "status": "attending", "isCreated": false, "isFavorite": false]
                var ref: DocumentReference?
                
                ref = docRef!.collection("events").addDocument(data: data) { (error) in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else {
                        if let id = ref?.documentID {
                            self.event?.id = id
                            
                            self.allUserEvents.append(self.event!)
                            CurrentUser.currentUser?.userEvents = self.allUserEvents
                            
                            // Update visible buttons.
                            self.addButton.isHidden = true
                            self.notGoingButton.isHidden = false
                            self.memoriesButton.isHidden = false
                            
                            print("Document added with ID: \(id)")
                        }
                    }
                }
            }
            
            // Update displayed event.
            self.event?.status = "attending"
            self.event?.groupId = self.userId!
            self.event?.attendeeIds = [self.userId!]
            
            // Show attendee information.
            showAttendees()
        }
    }

    @IBAction func notGoingButtonTapped(_ sender: UIButton) {
        // Create alert.
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        
        if isCreated {
            alert.title = "Delete Event"
            alert.message = "Are you sure that you want to change your plans? Since you created this event, doing so will delete this event along with all associated media and this action cannot be undone."
        } else {
            alert.title = "Change plans?"
            alert.message = "Are you sure that you want to change your plans? Any saved memories will be deleted and this cannot be undone."
        }
        
        // Add actions to alert controller.
        alert.addAction(UIAlertAction(title: "Keep", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { action in
            if self.isCreated {
                self.deleteFirebaseEvent()
            } else {
                if self.isFav {
                    // Find document in Firebase and update status field.
                    self.docRef!.collection("events").document(self.eventId).updateData(["status": "", "groupId": "", "attendeeIds": [String]()]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            // Update event status property and update current user's events to match.
                            if let index = self.allUserEvents.firstIndex(where: { $0.id == self.eventId }) {
                                self.allUserEvents[index].status = ""
                                CurrentUser.currentUser?.userEvents = self.allUserEvents
                                
                                print("Document successfully updated")
                            }
                        }
                    }
                } else {
                    self.deleteFirebaseEvent()
                }
            }
            
            // Hide attendee information.
            self.groupLbl.isHidden = true
            self.inviteBtn.isHidden = true
            self.additonalAttendeesLbl.isHidden = true
            
            for iv in self.attendeeIVs {
                if !iv.isHidden {
                    iv.isHidden = true
                }
            }
        }))
        
        // Show alert.
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func shareButtonTapped(_ sender: UIButton) {
        let linkUrl = URL(string: eventLink)
        
        LPMetadataProvider().startFetchingMetadata(for: linkUrl!) { linkMetadata, _ in
            DispatchQueue.main.async {
                linkMetadata?.iconProvider = NSItemProvider(object: self.imageIV.image!)
                linkMetadata?.title = self.eventTitle
                
                self.metadata = linkMetadata
                
                let activityVC = UIActivityViewController(activityItems: [self], applicationActivities: nil)
                
                self.present(activityVC, animated: true)
            }
        }
    }
    
    @IBAction func favButtonTapped(_ sender: UIButton) {
        if event != nil {
            favoritesDelegate.setFavorite(event: event!, isFav: !favButton.isSelected)
            favButton.isSelected.toggle()
            favButton.tintColor = favButton.isSelected ? UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1) : .systemGray
        }
    }
    
    private func populateFields() {
        if event != nil {
            eventId = event!.id
            eventImgURL = event!.imageUrl
            eventTitle = event!.title
            eventDate = event!.date
            eventAddress = event!.address
            eventLink = event!.link
            eventTickets = event!.tickets
            eventDescription = event!.description
            eventGroupId = event!.groupId
            isFav = event!.isFavorite
            isCreated = event!.isCreated
            
            // Populate fields.
            imageIV.image = event?.image
            titleLbl.text = eventTitle
            dateLbl.text = eventDate
            priceLbl.text = "No ticket info provided"
            locationLbl.text = eventAddress
            descriptionLbl.text = eventDescription

            // Create links to tickets.
            let attStr = NSMutableAttributedString(string: "")
            
            if !isCreated && !eventTickets.isEmpty {
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
            } else {
                if let price = eventTickets[0]["source"] as? String {
                    priceLbl.text = price
                }
            }
            
            showAttendees()
        }
    }
    
    private func showAttendees() {
        eventAttendeeIds = event!.attendeeIds
        
        // Display attendees.
        if !eventAttendeeIds.isEmpty {
            attendeeIVs = [attendeeIV0, attendeeIV1, attendeeIV2, attendeeIV3, attendeeIV4, attendeeIV5, attendeeIV6, attendeeIV7]
            groupLbl.isHidden = false
            
            if eventGroupId == userId {
                inviteBtn.isHidden = false
            }
            
            if eventAttendeeIds.count > 8 {
                additonalAttendeesLbl.isHidden = false
            }
            
            for i in 0...eventAttendeeIds.count - 1 {
                attendeeIVs[i].layer.borderColor = UIColor.systemBackground.cgColor
                attendeeIVs[i].isHidden = false
                
                if eventAttendeeIds[i] == userId {
                    attendeeIVs[i].image = CurrentUser.currentUser?.profilePic
                } else {
                    attendeeIVs[i].image = CurrentUser.currentUser?.friends?.first(where: { $0.id == eventAttendeeIds[i] })?.profilePic
                }
            }
        }
    }
    
    private func configureMapView() {
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
    }
    
    private func deleteFirebaseEvent() {
        // Remove event from user's events in Firebase
        if self.docRef != nil {
            self.docRef!.collection("events").document(self.eventId).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    // Remove event from userEvents array.
                    self.allUserEvents.removeAll(where: { $0.id == self.eventId })
                    CurrentUser.currentUser?.userEvents = self.allUserEvents
                    
                    if self.isCreated {
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        // Update visible buttons.
                        self.addButton.isHidden = false
                        self.notGoingButton.isHidden = true
                        self.memoriesButton.isHidden = true
                    }
                    
                    print("Document successfully removed!")
                }
            }
            
            if isCreated {
                // Delete event image from Firebase Storage.
                let storageRef = Storage.storage().reference().child("users").child(userId!).child("events").child(eventId).child("thumbnail.png")
                
                storageRef.delete { err in
                    if let err = err {
                        print("Error deleting image: \(err)")
                    } else {
                        print("Image successfully deleted")
                    }
                }
            }
        }
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return eventTitle
    }
    
    // The item we want the user to act on.
    // In this case, it's the URL to the Wikipedia page
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return self.metadata?.url
    }
    
    // The metadata we want the system to represent as a rich link
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return self.metadata
    }
        
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Action if navigating to DetailsViewController.
        if let destination = segue.destination as? CreateEventViewController {
            // Send selected event and userEvents array to DetailsViewController.
            destination.event = self.event
        }
        
        if let destination = segue.destination as? MemoriesViewController {
            // Send selected event and userEvents array to DetailsViewController.
            destination.eventId = self.eventId
            destination.eventTitle = self.eventTitle
            destination.eventGroupId = self.eventGroupId
            destination.eventAttendeeIds = self.eventAttendeeIds
        }
    }
}

private extension MKMapView {
    func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 200) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
    }
}

extension DetailsViewController: UILabelTapableLinksDelegate {
    func tapableLabel(_ label: UILabelTapableLinks, didTapUrl urlStr: String, atRange range: NSRange) {
        guard let url = URL(string: urlStr) else { return }
        UIApplication.shared.open(url)
    }
}
