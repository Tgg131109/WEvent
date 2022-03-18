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
import Kingfisher

class DetailsViewController: UIViewController, UIActivityItemSource {

    @IBOutlet weak var backButtonView: UIView!
    @IBOutlet weak var imageIV: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var titleView: CustomActivityIndicatorView!
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
    @IBOutlet weak var stdBtnDisableView: CustomActivityIndicatorView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var notGoingButton: UIButton!
    @IBOutlet weak var memoriesButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var favButton: UIButton!
    @IBOutlet weak var pendingBtnDisableView: CustomActivityIndicatorView!
    @IBOutlet weak var pendingButtonView: UIView!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    let db = Firestore.firestore()
    let userId = Auth.auth().currentUser?.uid
    var docRef: DocumentReference?
    
    var event: Event?
    var eventId = ""
    var eventImgURL = ""
    var eventTitle = ""
    var eventDate = ""
    var eventAddress = ""
    var eventLink = ""
    var eventTickets = [[String: Any]]()
    var eventDescription = ""
    var eventGroupId = ""
    var eventOrganizerId = ""
    var eventAttendeeIds = [String]()
    var attendeeIVs = [UIImageView]()
    var eventStatus = ""
    var isFav = Bool()
    var isCreated = Bool()
    var metadata: LPLinkMetadata?
    
    var shouldEdit = false
    var editEvent: (() -> Void)?

    var eventDataDelegate: EventDataDelegate!
    
    var updateCV: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        docRef = db.collection("users").document(userId!)
        eventDataDelegate = FirebaseHelper()
        
        populateFields()
        configureMapView()

        backButtonView.layer.cornerRadius = 10
        backButtonView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
        if let past = event?.isPast, past == true, event?.status == "attending" {
            inviteBtn.isHidden = true
            notGoingButton.isEnabled = false
            performSegue(withIdentifier: "goToMemories", sender: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
        
        let buttonViewToShow = event?.status == "invited" ? pendingButtonView : stdButtonView
        
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
        stdBtnDisableView.statusLbl.text = "Adding Event..."
        stdBtnDisableView.isHidden = false
        
        if event != nil && docRef != nil {
            // Check that an event invite for this event has not been sent while the user is viewing event.
            if CurrentUser.currentUser?.userEvents?.first(where: { $0.title == self.eventTitle && $0.link == self.eventLink})?.status == "invited" {
                if let e = CurrentUser.currentUser?.userEvents?.first(where: { $0.title == self.eventTitle && $0.link == self.eventLink}) {
                    // Update current event.
                    eventStatus = e.status
                    eventGroupId = e.groupId
                    eventOrganizerId = e.organizerId
                    eventAttendeeIds = e.attendeeIds
                    
                    swapButtonSet(buttonSetView: self.pendingButtonView)
                    
                    // Get inviter from current user's friend array.
                    let inviter = CurrentUser.currentUser?.friends?.first(where: { $0.id == e.organizerId })?.firstName
                    
                    // Create alert.
                    let alert = UIAlertController(title: "Pending Invite", message: "\(inviter ?? "A friend") has invited you to this event and is awaiting your response. ", preferredStyle: .alert)
                    // Add action to alert controller.
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    // Show alert.
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                // Action if event is already saved as a favorite.
                if self.isFav {
                    // If an event has just been added as a favorite, it will not have an id.
                    // Check if the event's id property is empty and attempt to get it if it exists in user's userEvents array.
                    if self.eventId.isEmpty {
                        if let eId = CurrentUser.currentUser?.userEvents?.first(where: { $0.title == self.eventTitle && $0.link == self.eventLink})?.id {
                            self.eventId = eId
                        } else {
                            print("Event cannot be added at this time")
                            stdBtnDisableView.isHidden = true
                            return
                        }
                    }
                    
                    // Create new group in Firebase and update user's event.
                    self.eventDataDelegate.addFirebaseGroup(eventId: self.eventId) { gId in
                        // Find document in Firebase and update status field.
                        self.docRef!.collection("events").document(self.eventId).updateData(["status": "attending", "groupId": gId]) { err in
                            if let err = err {
                                print("Error updating document: \(err)")
                                self.stdBtnDisableView.isHidden = true
                            } else {
                                // Update event status property and update current user's events to match.
                                if let index = CurrentUser.currentUser?.userEvents?.firstIndex(where: { $0.id == self.eventId }) {
                                    // Update displayed event.
                                    self.event?.status = "attending"
                                    self.event?.groupId = gId
                                    self.event?.organizerId = self.userId!
                                    self.event?.attendeeIds = [self.userId!]
                                    
                                    self.eventGroupId = gId
                                    self.eventOrganizerId = self.userId!
                                    
                                    CurrentUser.currentUser?.userEvents?[index] = self.event!
                                    
                                    print("Document successfully updated")
                                    
                                    self.updateVisibleButtons(going: true)
                                    self.updateCV?()
                                }
                            }
                        }
                    }
                } else {
                    // Check if event already exists in Firebase "events" collection.
                    let collRef = db.collection("events")
                    
                    collRef.whereField("title", isEqualTo: eventTitle).whereField("link", isEqualTo: eventLink).getDocuments { (querySnapshot, err) in
                        if let err = err {
                            print("Error getting documents: \(err)")
                            self.stdBtnDisableView.isHidden = true
                        } else {
                            // If event already exists, just add a reference to it to the user's "events" collection.
                            if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                                let docId = querySnapshot.documents[0].documentID
                                
                                self.saveEventToFirebase(eventId: docId)
                            } else {
                                // Add event to Firebase "events" collection.
                                let data: [String: Any] = ["thumbnail": self.eventImgURL, "title": self.eventTitle, "date": self.eventDate, "tickets": self.eventTickets, "address": self.eventAddress, "link": self.eventLink, "description": self.eventDescription]
                                
                                var ref: DocumentReference?
                                
                                ref = collRef.addDocument(data: data) { (error) in
                                    if let error = error {
                                        print("Error: \(error.localizedDescription)")
                                        self.stdBtnDisableView.isHidden = true
                                    } else {
                                        if let docId = ref?.documentID {
                                            self.saveEventToFirebase(eventId: docId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
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
            self.stdBtnDisableView.statusLbl.text = "Removing Event..."
            self.stdBtnDisableView.isHidden = false
                        
            if self.isCreated || !self.isFav {
                self.deleteFirebaseEvent()
            } else if self.isFav {
                self.notGoingToFavoritedEvent(disableButtonView: self.stdBtnDisableView)
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
            eventDataDelegate.setFavorite(event: event!, isFav: !favButton.isSelected)
            
            self.isFav = !favButton.isSelected
            
            favButton.isSelected.toggle()
            favButton.tintColor = favButton.isSelected ? UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1) : .systemGray
            
            self.updateCV?()
        }
    }
    
    @IBAction func acceptBtnTapped(_ sender: UIButton) {
        // Check if group still exists (group organizer hasn't removed event).
        db.collection("groups").document(eventGroupId).getDocument { (document, error) in
            if let document = document, document.exists {
                self.pendingBtnDisableView.isHidden = false
                
                // Find document in Firebase and update status field.
                self.docRef!.collection("events").document(self.eventId).updateData(["status": "attending"]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                        self.pendingBtnDisableView.isHidden = true
                    } else {
                        // Add current user's user id to group attendeeIds array in Firebase.
                        self.db.collection("groups").document(self.eventGroupId).updateData(["memberIds": FieldValue.arrayUnion([self.userId!])]) { error in
                            if let error = error {
                                print("Error updating document: \(error)")
                                self.pendingBtnDisableView.isHidden = true
                            } else {
                                // Update event properties and update current user's events to match.
                                if let index = CurrentUser.currentUser?.userEvents?.firstIndex(where: { $0.id == self.eventId }) {
                                    // Update displayed event.
                                    self.event?.status = "attending"
                                    self.event?.attendeeIds.append(self.userId!)
                                    
                                    CurrentUser.currentUser?.userEvents?[index] = self.event!
                                    
                                    self.showAttendees()
                                    self.swapButtonSet(buttonSetView: self.stdButtonView)
                            
                                    print("Document successfully updated")
                                }
                            }
                        }
                    }
                }
                
            } else {
                print("Invite document does not exist")
                // Update event status or remove event entirely.
                if self.isFav {
                    self.notGoingToFavoritedEvent(disableButtonView: self.pendingButtonView)
                } else {
                    self.deleteFirebaseEvent()
                }
                
                // Create alert.
                let alert = UIAlertController(title: "Deleted Group", message: "The group organizer has deleted this group. This invitation will be removed.", preferredStyle: .alert)
                // Add action to alert controller.
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // Show alert.
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func declineBtnTapped(_ sender: UIButton) {
        pendingBtnDisableView.isHidden = false
        
        if self.isFav {
            notGoingToFavoritedEvent(disableButtonView: pendingButtonView)
        } else {
            self.deleteFirebaseEvent()
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
            eventOrganizerId = event!.organizerId
            eventStatus = event!.status
            isFav = event!.isFavorite
            isCreated = event!.isCreated
            
            // Populate fields.
            imageIV.image = event?.image
            titleView.statusLbl.text = eventTitle
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
            
            groupLbl.text = "Group • \(eventAttendeeIds.count)"
            groupLbl.isHidden = false
            
            if eventOrganizerId == userId {
                inviteBtn.isHidden = false
            }
            
            if eventAttendeeIds.count > 8 {
                let diff = eventAttendeeIds.count - 8
                
                additonalAttendeesLbl.text = diff > 1 ? "+ \(diff) others" : "+ 1 other"
                additonalAttendeesLbl.isHidden = false
            }
            
            for i in 0...eventAttendeeIds.count - 1 {
                attendeeIVs[i].isHidden = false
                
                if eventAttendeeIds[i] == userId {
                    attendeeIVs[i].image = CurrentUser.currentUser?.profilePic
                } else {
                    let imageUrl = CurrentUser.currentUser?.friends?.first(where: { $0.id == eventAttendeeIds[i] })?.picUrl ?? ""
                    
                    attendeeIVs[i].kf.indicatorType = .activity
                    attendeeIVs[i].kf.setImage(with: URL(string: imageUrl), placeholder: UIImage(named: "logo_stamp"), options: [.transition(.fade(1))], completionHandler: { result in
                        switch result {
                        case .success(let value):
                            CurrentUser.currentUser?.friends?.first(where: { $0.id == self.eventAttendeeIds[i] })?.profilePic = value.image
                            break
                            
                        case .failure(let error):
                            if !error.isTaskCancelled && !error.isNotCurrentTask {
                                print("friend: \(self.eventAttendeeIds[i])")
                                print("Error getting attendee image: \(error)")
                            }
                            break
                        }
                    })
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
            
            if let placemarks = placemarks, !placemarks.isEmpty {
                let placemark = placemarks.first
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
    
    private func saveEventToFirebase(eventId: String) {
        self.eventDataDelegate.addUserEvent(uId: self.userId!, eventId: eventId, groupId: self.userId!, isCreated: false) { result in
            if result == true {
                // Create new group in Firebase and update user's event.
                self.eventDataDelegate.addFirebaseGroup(eventId: eventId) { newId in
                    if newId != "error" {
                        // Update displayed event.
                        self.event?.id = eventId
                        self.event?.status = "attending"
                        self.event?.groupId = newId
                        self.event?.organizerId = self.userId!
                        self.event?.attendeeIds = [self.userId!]
                        
                        self.eventId = eventId
                        self.eventGroupId = newId
                        self.eventOrganizerId = self.userId!
                        
                        CurrentUser.currentUser?.userEvents?.append(self.event!)
                        
                        self.updateVisibleButtons(going: true)
                    }
                }
            }
        }
    }
    
    private func notGoingToFavoritedEvent(disableButtonView: UIView) {
        // Find document in Firebase and update status field.
        self.docRef!.collection("events").document(self.eventId).updateData(["status": "", "groupId": ""]) { err in
            if let err = err {
                print("Error updating document: \(err)")
                disableButtonView.isHidden = true
                return
            } else {
                // Update event properties and update current user's events to match.
                if let index = CurrentUser.currentUser?.userEvents?.firstIndex(where: { $0.id == self.eventId }) {
                    // Update displayed event.
                    self.event?.status = ""
                    self.event?.groupId = ""
                    self.event?.organizerId = ""
                    self.event?.attendeeIds = [String]()
                    
                    CurrentUser.currentUser?.userEvents?[index] = self.event!
                    
                    if self.eventStatus == "invited" {
                        self.eventStatus = self.event?.status ?? ""
                        self.swapButtonSet(buttonSetView: self.stdButtonView)
                    }
                    
                    self.updateVisibleButtons(going: false)
                    self.updateCV?()

                    if self.eventAttendeeIds.count > 1 {
                        // Remove current user's user id from group attendeeIds array in Firebase.
                        self.db.collection("groups").document(self.eventGroupId).updateData(["memberIds": FieldValue.arrayRemove([self.userId!])]) { error in
                            if let error = error {
                                print("Error updating group: \(error)")
                            } else {
                                print("Group successfully updated")
                            }
                        }
                    }
                    
                    print("Document successfully updated")
                }
            }
        }
    }
    
    private func deleteFirebaseEvent() {
        self.eventDataDelegate.deleteFirebaseEvent(event: self.event!) { result in
            if result == false {
                print("There was an issue deleting this event.")
            } else {
                if self.isCreated {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    // Update displayed event.
                    self.event?.id = ""
                    self.event?.status = ""
                    self.event?.groupId = ""
                    self.event?.organizerId = ""
                    self.event?.attendeeIds = [String]()
                    
                    if self.eventStatus == "invited" {
                        self.eventStatus = self.event?.status ?? ""
                        self.swapButtonSet(buttonSetView: self.stdButtonView)
                    }
                    
                    self.updateVisibleButtons(going: false)
                }
            }
        }
    }
    
    private func updateVisibleButtons(going: Bool) {
        if going {
            // Update visible buttons.
            addButton.isHidden = true
            notGoingButton.isHidden = false
            memoriesButton.isHidden = false
            
            // Show attendee information.
            showAttendees()
        } else {
            // Update visible buttons.
            addButton.isHidden = false
            notGoingButton.isHidden = true
            memoriesButton.isHidden = true
            
            // Hide attendee information.
            groupLbl.isHidden = true
            inviteBtn.isHidden = true
            additonalAttendeesLbl.isHidden = true
            
            for iv in attendeeIVs {
                if !iv.isHidden {
                    iv.isHidden = true
                }
            }
        }
        
        stdBtnDisableView.isHidden = true
    }
    
    private func swapButtonSet(buttonSetView: UIView) {
        view.addSubview(buttonSetView)
        
        NSLayoutConstraint.activate([
            buttonSetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonSetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonSetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        if buttonSetView == stdButtonView {
            updateVisibleButtons(going: true)
            pendingButtonView.removeFromSuperview()
            pendingBtnDisableView.isHidden = true
            updateCV?()
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
        
        if let destination = segue.destination as? InviteFriendsViewController {
            // Send selected event and userEvents array to DetailsViewController.
            destination.event = self.event
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
