//
//  CreateEventViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 3/1/22.
//

import UIKit
import MapKit
import Firebase

class CreateEventViewController: UIViewController, UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var eventPicIV: UIImageView!
    @IBOutlet weak var eventTitleTF: CustomTextField!
    @IBOutlet weak var eventDateTF: CustomTextField!
    @IBOutlet weak var dateGestureView: UIView!
    @IBOutlet weak var datePickerView: CustomActivityIndicatorView!
    @IBOutlet weak var datePickerBkgd: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dateDoneBtn: UIButton!
    @IBOutlet weak var eventPriceTF: CustomTextField!
    @IBOutlet weak var eventLocationTF: CustomTextField!
    @IBOutlet weak var suggestionTableView: UITableView!
    @IBOutlet weak var eventDescriptionTV: UITextView!
    @IBOutlet weak var createButton: UIButton!
    
    let db = Firestore.firestore()
    let docId = Auth.auth().currentUser?.uid
    var docRef: DocumentReference?
    
    private var searchCompleter: MKLocalSearchCompleter?
    private var searchRegion: MKCoordinateRegion = MKCoordinateRegion(MKMapRect.world)
    private var currentPlacemark: CLPlacemark?
    
    var completerResults: [MKLocalSearchCompletion]?
    var imagePicker = UIImagePickerController()
    var imageData: Data?
    var image = UIImage()
    var imgTapRecognizer: UITapGestureRecognizer!
    var dateTapRecognizer: UITapGestureRecognizer!
    
    var allUserEvents = [Event]()
    var event: Event?
    var eventId = ""
    var editEvent = false
    var imageChanged = false
    
    var updateCV: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        docRef = db.collection("users").document(docId!)
        allUserEvents = CurrentUser.currentUser?.userEvents ?? [Event]()
        
        // Set default image.
        image = UIImage(named: "logo_stamp")!
        
        // Set up gesture recognizers.
        imgTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(setPicture(_:)))
        eventPicIV.addGestureRecognizer(imgTapRecognizer)
        
        dateTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(pickDate(_:)))
        dateGestureView.addGestureRecognizer(dateTapRecognizer)
        
        // Set eventDescriptionTV delegate to handle text input changes.
        eventDescriptionTV.delegate = self

        // Style views.
        eventPicIV.layer.cornerRadius = 10
        datePickerBkgd.layer.cornerRadius = 10
        suggestionTableView.layer.cornerRadius = 10
        suggestionTableView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        eventDescriptionTV.layer.cornerRadius = 6
        eventDescriptionTV.layer.borderWidth = 2
        eventDescriptionTV.layer.borderColor = UIColor(red: 194/255, green: 231/255, blue: 250/255, alpha: 1).cgColor
                
        // Populate fields if an event is being edited.
        if event != nil {
            editEvent = true
            eventId = event!.id
            populateFields()
        }
    }
    
    @IBAction func cancelBtnTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func pickDate(_ sender: UIView) {
        datePickerView.activityIndicator.isHidden = true
        datePickerView.statusLbl.isHidden = true
        datePickerView.isHidden = false
    }
    
    @IBAction func hideDatePicker(_ sender: UIButton) {
        let formatter = DateFormatter()
        
        formatter.calendar = datePicker.calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: datePicker.date)
        
        eventDateTF.text = dateString
        datePickerView.isHidden = true
    }
    
    @IBAction func suggestLocation(_ sender: CustomTextField) {
        startProvidingCompletions()
        suggestionTableView.isHidden = false
    }
    
    @IBAction func hideSuggestions(_ sender: CustomTextField) {
        stopProvidingCompletions()
        suggestionTableView.isHidden = true
    }
    
    @IBAction func updateSuggestionResults(_ sender: CustomTextField) {
        searchCompleter?.queryFragment = eventLocationTF.text ?? ""
    }
    
    @IBAction func createBtnTapped(_ sender: UIButton) {
        // Create alert to be displayed if proper conditions are not met.
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        // Add action to alert controller.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Ensure required fields are not empty.
        guard let eventTitle = eventTitleTF.text, !eventTitle.isEmpty,
              let eventDate = eventDateTF.text, !eventDate.isEmpty,
              let eventPrice = eventPriceTF.text, !eventPrice.isEmpty,
              let eventLocation = eventLocationTF.text, !eventLocation.isEmpty,
              let eventDescription = eventDescriptionTV.text, !eventDescription.isEmpty
        else {
            alert.title = "Missing Info"
            alert.message = "All fields must be completed to continue."
            
            // Show alert.
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        if editEvent {
            // Ensure data has been changed.
            let price = event?.tickets[0]["source"] as? String
            
            if eventPicIV.image == event?.image && eventTitle == event?.title && eventDate == event?.date && eventPrice == price && eventLocation == event?.address && eventDescription == event?.description {
                // Set alert title and message.
                alert.title = "Unchanged Data"
                alert.message = "The information that you are trying to submit is unchanged and cannot be updated. Please verify that you have entered new information and try again."
                
                // Show alert.
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            datePickerView.statusLbl.text = "Updating your event..."
        }
        
        datePickerView.activityIndicator.isHidden = false
        datePickerView.statusLbl.isHidden = false
        datePicker.isHidden = true
        datePickerBkgd.isHidden = true
        dateDoneBtn.isHidden = true
        datePickerView.activityIndicator.startAnimating()
        datePickerView.isHidden = false
        
        var eventTickets = [[String: Any]]()
        eventTickets.append(["source" : eventPrice])
        
        // Add event to user's events in Firebase.
        let data: [String: Any] = ["thumbnail": event?.imageUrl ?? "", "title": eventTitle, "date": eventDate, "tickets": eventTickets, "address": eventLocation, "link": "", "description": eventDescription, "groupId": docId!, "attendeeIds": [docId!], "status": "attending", "isCreated": true, "isFavorite": event?.isFavorite ?? false]
        
        event = Event(id: event?.id ?? "", title: eventTitle, date: eventDate, address: eventLocation, link: "", description: eventDescription, tickets: eventTickets, imageUrl: event?.imageUrl ?? "", image: self.image, groupId: docId!, attendeeIds: [docId!], status: "attending", isFavorite: event?.isFavorite ?? false, isCreated: event?.isCreated ?? false)
        
        if !editEvent {
            saveEventToFirebase(data: data)
        } else {
            updateFirebaseEvent(data: data)
        }
    }

    @objc func setPicture(_ sender: UIImageView) {
        let getPermissionsDelegate: GetPhotoCameraPermissionsDelegate! = GetImageHelper()
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a Source", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction) in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                Task.init {
                    if await getPermissionsDelegate.getPhotosPermissions() {
                        let imagePicker = UIImagePickerController()
                        
                        imagePicker.delegate = self
                        imagePicker.sourceType = .photoLibrary
                        imagePicker.allowsEditing = false
                        
                        self.present(imagePicker, animated: true, completion: nil)
                    }
                }
            } else {
                // Create alert.
                let alert = UIAlertController(title: "No Library", message: "Photo library is not available on this device.", preferredStyle: .alert)
                // Add action to alert controller.
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                // Show alert.
                self.present(alert, animated: true, completion: nil)
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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let img = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // Resize image
            let targetSize = CGSize(width: 100, height: 100)
            let scaledImg = img.scalePreservingAspectRatio(targetSize: targetSize)
            
            imageData = scaledImg.pngData()
            eventPicIV.image = img
            imageChanged = true
            self.image = img
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if eventDescriptionTV.textColor == .systemGray3 {
            eventDescriptionTV.text = nil
            eventDescriptionTV.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if eventDescriptionTV.text.isEmpty {
            eventDescriptionTV.text = "Event Description"
            eventDescriptionTV.textColor = .systemGray3
        }
    }
    
    private func startProvidingCompletions() {
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter?.delegate = self
        searchCompleter?.resultTypes = [.pointOfInterest, .address]
        searchCompleter?.region = searchRegion
    }
    
    private func stopProvidingCompletions() {
        searchCompleter = nil
    }
    
    func updatePlacemark(_ placemark: CLPlacemark?, boundingRegion: MKCoordinateRegion) {
        currentPlacemark = placemark
        searchCompleter?.region = searchRegion
    }
    
    private func createHighlightedString(text: String, rangeValues: [NSValue]) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.backgroundColor: UIColor.white.cgColor ]
        let highlightedString = NSMutableAttributedString(string: text)
        
        // Each `NSValue` wraps an `NSRange` that can be used as a style attribute's range with `NSAttributedString`.
        let ranges = rangeValues.map { $0.rangeValue }
        
        ranges.forEach { (range) in
            highlightedString.addAttributes(attributes, range: range)
        }
        
        return highlightedString
    }
    
    private func populateFields() {
        eventPicIV.image = event?.image
        eventTitleTF.text = event?.title
        eventDateTF.text = event?.date
        
        if let price = event?.tickets[0]["source"] as? String {
            eventPriceTF.text = price
        }

        eventLocationTF.text = event?.address
        eventDescriptionTV.text = event?.description
        eventDescriptionTV.textColor = .label
        
        // Change createButton text.
        createButton.setTitle("Save Changes", for: .normal)
    }
    
    private func saveEventToFirebase(data: [String: Any]) {
        var ref: DocumentReference?
        
        ref = docRef?.collection("events").addDocument(data: data) { (error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                
                // Create alert to show user.
            } else {
                if let eId = ref?.documentID {
                    self.event?.id = eId
                    self.eventId = eId
                    
                    // Create new event and add to curren user's events.
                    self.allUserEvents.append(self.event!)
                    CurrentUser.currentUser?.userEvents = self.allUserEvents
                                                        
                    print("Document added with ID: \(eId)")
                    
                    self.showSuccessAlert()
                    self.saveImageToFirebase()
                }
            }
        }
    }
    
    private func updateFirebaseEvent(data: [String: Any]) {
        // Find document in Firebase and update favorite field.
        docRef!.collection("events").document(eventId).updateData(data) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                // Update current user's events.
                if let index = self.allUserEvents.firstIndex(where: { $0.id == self.eventId }) {
                    self.event?.image = self.eventPicIV.image!
                    self.allUserEvents[index] = self.event!
                    CurrentUser.currentUser?.userEvents = self.allUserEvents
                    
                    print("Document successfully updated")
                    
                    self.updateCV?()
                    
                    self.showSuccessAlert()
    
                    if self.imageChanged {
                        self.saveImageToFirebase()
                    }
                }
            }
        }
    }
    
    private func saveImageToFirebase() {
        // Save event image to Firebase Storage.
        let storageRef = Storage.storage().reference().child("events").child(eventId).child("thumbnail.png")
        let metaData = StorageMetadata()
        
        metaData.contentType = "image/png"
        
        if self.imageData == nil {
            self.imageData = self.image.pngData()
        }
        
        storageRef.putData(self.imageData!, metadata: metaData) { (metaData, error) in
            if error == nil, metaData != nil {
                storageRef.downloadURL { url, error in
                    if let url = url {
                        // Update created event in Firebase with url string.
                        self.docRef?.collection("events").document(self.eventId).updateData(["thumbnail": url.absoluteString]) { err in
                            if let err = err {
                                print("Error adding image: \(err)")
                            } else {
                                // Update event in user's current events.
                                CurrentUser.currentUser?.userEvents?.first(where: { $0.id == self.eventId })?.image = self.image

                                print("Image successfully added")
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
    
    private func showSuccessAlert() {
        let action = editEvent ? "updated" : "created"
        
        // Create alert to notify user of successful update.
        let successAlert = UIAlertController(title: "Success", message: "Your event has been successfully \(action).", preferredStyle: .alert)
        
        // Add action to successAlert controller.
        successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.datePickerView.isHidden = true
            self.datePickerView.activityIndicator.stopAnimating()
            self.datePickerView.activityIndicator.isHidden = true
            self.datePickerView.statusLbl.isHidden = true
            self.datePicker.isHidden = false
            self.datePickerBkgd.isHidden = false
            self.dateDoneBtn.isHidden = false
            self.dismiss(animated: true, completion: nil)
        }))
        
        // Show alert.
        self.present(successAlert, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return completerResults?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "table_cell_6", for: indexPath)
        
        if let suggestion = completerResults?[indexPath.row] {
            // Each suggestion is a MKLocalSearchCompletion with a title, subtitle, and ranges describing what part of the title
            // and subtitle matched the current query string. The ranges can be used to apply helpful highlighting of the text in
            // the completion suggestion that matches the current query fragment.
            cell.textLabel?.attributedText = createHighlightedString(text: suggestion.title, rangeValues: suggestion.titleHighlightRanges)
            cell.detailTextLabel?.attributedText = createHighlightedString(text: suggestion.subtitle, rangeValues: suggestion.subtitleHighlightRanges)
        }
        
        return cell
    }

    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row for animation purposes.
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let suggestion = completerResults?[indexPath.row] {
            eventLocationTF.text = "\(suggestion.title) \(suggestion.subtitle)"
            suggestionTableView.isHidden = true
        }
    }
}

extension CreateEventViewController: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // As the user types, new completion suggestions are continuously returned to this method.
        // Overwrite the existing results, and then refresh the UI with the new results.
        completerResults = completer.results
        suggestionTableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle any errors returned from MKLocalSearchCompleter.
        if let error = error as NSError? {
            print("MKLocalSearchCompleter encountered an error: \(error.localizedDescription). The query fragment is: \"\(completer.queryFragment)\"")
        }
    }
}
