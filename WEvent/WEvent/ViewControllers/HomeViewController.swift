//
//  HomeViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/24/22.
//

import UIKit
import CoreLocation
import Firebase
import Kingfisher

class HomeViewController: UITableViewController, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let navIconIV = UIImageView(image: UIImage(named: "logo_stamp"))
    
    let manager = CLLocationManager()
    
    let db = Firestore.firestore()
    let docId = Auth.auth().currentUser?.uid
    var docRef: DocumentReference?
    
    var useCurrentLocation = true
    var locationStr = ""
    var allUserEvents = [Event]()
    var userUpcomingEvents = [Event]()
    var localEvents = [Event]()
    var selectedEvent: Event?
    var editEvent = false
    var updateCV = false
    
    var favoritesDelegate: FavoritesDelegate!
    var getImageDelegate: GetImageDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Add icon to navigation bar and configure for scroll animation.
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        navigationBar.addSubview(navIconIV)
        
        navIconIV.tintColor = .label
        navIconIV.translatesAutoresizingMaskIntoConstraints = false
        navIconIV.contentMode = .scaleAspectFit
        
        NSLayoutConstraint.activate([
            navIconIV.leftAnchor.constraint(equalTo: navigationBar.leftAnchor, constant: 175),
            navIconIV.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -16),
            navIconIV.heightAnchor.constraint(equalToConstant: 30),
            navIconIV.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        docRef = db.collection("users").document(docId!)
        favoritesDelegate = FirebaseHelper()
        getImageDelegate = GetImageHelper()
        
        useCurrentLocation = UserDefaults.standard.object(forKey: "useCurrentLocation") as? Bool ?? true
        
        if !useCurrentLocation {
            if let preferredLocation = UserDefaults.standard.stringArray(forKey: "preferredLocation"),
               let lat = Double(preferredLocation[3]), let lon = Double(preferredLocation[4]) {
                let loc = Location(city: preferredLocation[0], coordinates: [lat, lon], state: preferredLocation[1], id: preferredLocation[2])
                
                CurrentLocation.preferredLocation = loc
                locationStr = loc.city
                getLocalEvents(loc: loc.searchStr)
            }
        }
        
        getUserLocation()
        
        // Register CustomTableViewHeader xib.
        let headerNib = UINib.init(nibName: "CustomTableViewHeader", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "header_1")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let prefLoc = CurrentLocation.preferredLocation
        
        if prefLoc != nil && locationStr != prefLoc!.city {
            locationStr = prefLoc!.city
            getLocalEvents(loc: prefLoc!.searchStr)
        }
        
        if !editEvent {
            let currentEventCount = allUserEvents.count
            let actualEventCount = CurrentUser.currentUser?.userEvents?.count

            allUserEvents = CurrentUser.currentUser?.userEvents ?? [Event]()
            userUpcomingEvents = allUserEvents.filter({$0.status == "attending"})

            // Reload tableView collectionView if events have been added, removed, or updated.
            if currentEventCount != actualEventCount || updateCV {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
//                    self.tableView.reloadSections(IndexSet([0]), with: .none)
                }
            }
        } else {
            editEvent = false
            
            // Show CreateEventViewController.
            self.performSegue(withIdentifier: "goToEdit", sender: self)
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let height = navigationController?.navigationBar.frame.height else { return }
        moveAndResizeNavImage(for: height)
    }
    
    private func getUserLocation() {
        manager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.startUpdatingLocation()
        } else {
            // Alert user that they need to enable location services.
            print("Services Disabled")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(locations[0]) { (placemarks, error) in
            if (error != nil) {
                print("error in reverseGeocode")
            }
            
            let placemark = placemarks! as [CLPlacemark]
            
            if placemark.count > 0 {
                let placemark = placemarks![0]
                
                if self.locationStr != placemark.locality! {
                    let currentLocation = Location(city: placemark.locality!, coordinates: [placemark.location!.coordinate.latitude, placemark.location!.coordinate.longitude], state: placemark.administrativeArea!, id: placemark.postalCode!)
                    
                    CurrentLocation.location = currentLocation
                    
                    if self.useCurrentLocation {
                        self.locationStr = currentLocation.city
                        
                        CurrentLocation.preferredLocation = CurrentLocation.location
                        
                        self.getLocalEvents(loc: currentLocation.searchStr)
                    }
                }
            }
        }
    }
    
    private func getLocalEvents(loc: String) {
        self.localEvents.removeAll()
        
        // Create default configuration.
        let config = URLSessionConfiguration.default

        // Create session.
        let session = URLSession(configuration: config)
        
        // Validate URL.
        if let validURL = URL(string: "https://serpapi.com/search.json?engine=google_events&q=events+in+\(loc)&api_key=f5f6c4283773ca865ad9b308708d823a2f01101aa39aeabcba72bfde7014c9e8") {
            // Create task to download data from validURL as Data object.
            let task = session.dataTask(with: validURL, completionHandler: { (data, response, error) in
                // Exit method if there is an error.
                if let error = error {
                    print("Task failed with error: \(error.localizedDescription)")
                    return
                }

                // If there are no errors, check response status code and validate data.
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200, // 200 = OK
                      let validData = data
                else {
                    DispatchQueue.main.async {
                        // Present alert on main thread if there is an error with the URL (subreddit does not exist).
//                        self.present(alert, animated: true, completion: nil)
                    }
                    
                    print("Sub cannot be found.")
                    print("JSON object creation failed.")
                    return
                }
                // Create Event object.
                do {
                    // Create json Object from downloaded data above and cast as [String: Any].
                    if let jsonObj = try JSONSerialization.jsonObject(with: validData, options: .mutableContainers) as? [String: Any] {
                        guard let data = jsonObj["events_results"] as? [[String: Any]]
                        else {
                            print("The data cannot be found")
                            return
                        }
                        
                        for event in data {
                            // Step through outer level data to get to relevant event data.
                            guard let title = event["title"] as? String,
                                  let date = event["date"] as? [String: Any],
                                  let address = event["address"] as? [String],
                                  let link = event["link"] as? String,
                                  let description = event["description"] as? String,
                                  let tickets = event["ticket_info"] as? [[String: Any]],
                                  let imageUrl = event["thumbnail"] as? String
                            else {
                                print("There was an error with this local event's data")
                                continue
                            }
                            
                            guard let start = date["start_date"] as? String,
                                  let when = date["when"] as? String
                            else {
                                print("Date data cannot be found")
                                return
                            }
                            
                            let dateStr = "\(start) | \(when)"
                            let addressStr = "\(address[0]), \(address[1])"
//                            let eventImage = self.getImageDelegate.getImageFromUrl(imageUrl: imageUrl)
                            let eventImage = UIImage(named: "logo_stamp")!
       
                            self.localEvents.append(Event(id: "", title: title, date: dateStr, address: addressStr, link: link, description: description, tickets: tickets, imageUrl: imageUrl, image: eventImage, groupId: "", attendeeIds: [String]()))
                        }
                    }
                }
                catch{
                    print("Error: \(error.localizedDescription)")
                }
                
                DispatchQueue.main.async {
                    print("reload table view")
                    self.tableView.reloadSections(IndexSet([1]), with: .fade)
                }
            })
            // Start task.
            task.resume()
        }
    }

    private func moveAndResizeNavImage(for height: CGFloat) {
        let coeff: CGFloat = {
            let delta = height - 44 // Small navigation bar height.
            let heightDifferenceBetweenStates = (96.5 - 44) // Large - Small navigation bar heights.
            return delta / heightDifferenceBetweenStates
        }()

        // Scale factor using small image size/large image size.
        let factor = 20.0 / 30.0

        let scale: CGFloat = {
            let sizeAddendumFactor = coeff * (1.0 - factor)
            return min(1.0, sizeAddendumFactor + factor)
        }()

        // Value of difference between icons for large and small states
        let sizeDiff = 30.0 * (1.0 - factor)
        let yTranslation: CGFloat = {
            return max(0, min(sizeDiff, (sizeDiff - coeff * (12 + sizeDiff))))
        }()

        let xTranslation = max(0, sizeDiff - coeff * sizeDiff)
        
        navIconIV.transform = CGAffineTransform.identity
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: xTranslation * 11, y: yTranslation)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : localEvents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.section == 0 ? "table_cell_1" : "table_cell_2", for: indexPath)

        if indexPath.section != 0 {
            let cell = cell as! CustomTableViewCell
            let event = localEvents[indexPath.row]
            
            cell.eventImageIV.layer.cornerRadius = 10
//            cell.eventImageIV.image = event.image
            cell.eventImageIV.kf.indicatorType = .activity
            cell.eventImageIV.kf.setImage(with: URL(string: event.imageUrl), placeholder: UIImage(named: "logo_stamp"), options: [.transition(.fade(1))])
            cell.eventDateLbl.text = event.date
            cell.eventTitleLbl.text = event.title
            cell.eventAddressLbl.text = event.address
            cell.favButton.isSelected = allUserEvents.filter({$0.isFavorite == true}).contains(where: {$0.title == event.title})
            cell.favButton.tintColor = cell.favButton.isSelected ? UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1) : .systemGray
            
            cell.favTapped = {(favButton) in
                var updateEvent: Event?
                // Set event to be updated.
                if let index = self.allUserEvents.firstIndex(where: { $0.title == event.title }) {
                    // If event is contained in user's events, pass that event instead.
                    // This ensures correct information is shown on DetailsViewController.
                    self.allUserEvents[index].isFavorite = !favButton.isSelected
                    updateEvent = self.allUserEvents[index]
                } else {
                    if event.image != cell.eventImageIV.image {
                        event.image = cell.eventImageIV.image!
                        self.localEvents[indexPath.row].image = cell.eventImageIV.image!
                    }
                    
                    updateEvent = event
                }
                
                self.favoritesDelegate.setFavorite(event: updateEvent!, isFav: !favButton.isSelected)
                favButton.isSelected.toggle()
                favButton.tintColor = favButton.isSelected ? UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1) : .systemGray
            }
        } else {
            let cell = cell as! CVTableViewCell
            
            DispatchQueue.main.async {
                cell.collectionView.reloadData()
                cell.collectionView.collectionViewLayout.invalidateLayout()
                cell.collectionView.layoutSubviews()
            }
        }

        return cell
    }
        
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Create custom header.
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header_1") as? CustomTableViewHeader
        header?.headerLbl?.text = section == 0 ? "Your Upcoming Events" : "Events Near \(locationStr)"

        return header
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row for animation purposes.
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = self.tableView(tableView, cellForRowAt: indexPath) as? CustomTableViewCell
        let localEvent = localEvents[indexPath.row]
        
        localEvents[indexPath.row].image = cell?.eventImageIV.image! ?? UIImage(named: "logo_stamp")!
        
        // Set selected event to be passed to DetailsViewController
        if let index = allUserEvents.firstIndex(where: { $0.title == localEvent.title }) {
            // If event is contained in user's events, pass that event instead.
            // This ensures correct information is shown on DetailsViewController.
            selectedEvent = allUserEvents[index]
        } else {
            selectedEvent = localEvent
        }

        // Show DetailsViewController.
        self.performSegue(withIdentifier: "goToDetails", sender: self)
    }
    
    // MARK: - CollectionView data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userUpcomingEvents.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coll_cell_1", for: indexPath) as! CustomCollectionViewCell
        
        if indexPath.row == collectionView.numberOfItems(inSection: 0) - 1 {
            cell.eventImageIV.image = UIImage(named: "logo_stamp")
            cell.eventDateLbl.isHidden = true
            cell.eventTitleLbl.text = "Find an event or create one of your own"
            cell.eventTitleLbl.textColor = UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1)
            cell.eventAddressLbl.isHidden = true
        } else {
            let event = userUpcomingEvents[indexPath.row]

            cell.eventImageIV.image = event.image
            cell.eventDateLbl.isHidden = false
            cell.eventDateLbl.text = event.date
            
            if event.isCreated {
                let title = NSMutableAttributedString(string: "\(event.title) ")
                let imageAttachment = NSTextAttachment()
                
                // Resize image
                let targetSize = CGSize(width: 16, height: 16)
                imageAttachment.image = UIImage(named: "logo_stamp")?.scalePreservingAspectRatio(targetSize: targetSize).withTintColor(UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1))
                
                let imageStr = NSAttributedString(attachment: imageAttachment)
                
                title.append(imageStr)
                
                cell.eventTitleLbl.attributedText = title
            } else {
                cell.eventTitleLbl.text = event.title
            }
            
            cell.eventTitleLbl.textColor = .label
            cell.eventAddressLbl.text = event.address
            cell.eventAddressLbl.isHidden = false
        }

        // Format cells.
        cell.eventImageIV.layer.cornerRadius = 10
        cell.eventImageIV.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cell.layer.shadowColor = UIColor.systemGray.cgColor
        cell.layer.shadowOpacity = 1
        cell.layer.shadowOffset = .zero
        cell.layer.shadowRadius = 3
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = false
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == collectionView.numberOfItems(inSection: 0) - 1 {
            // Show SearchViewController
            self.tabBarController?.selectedIndex = 1
        } else {
            // Set selected event to be passed to DetailsViewController
            selectedEvent = userUpcomingEvents[indexPath.row]
            
            // Show DetailsViewController.
            self.performSegue(withIdentifier: "goToDetails", sender: self)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Action if navigating to DetailsViewController.
        if let navCon = segue.destination as? UINavigationController {
            if let destination = navCon.topViewController as? DetailsViewController {
                // Send selected event and userEvents array to DetailsViewController.
                destination.event = self.selectedEvent
                destination.editEvent = {
                    self.editEvent = true
                }
            }
        }
        
        if let destination = segue.destination as? CreateEventViewController {
            destination.event = self.selectedEvent
            destination.updateCV = {
                self.updateCV = true
            }
        }
    }
}
