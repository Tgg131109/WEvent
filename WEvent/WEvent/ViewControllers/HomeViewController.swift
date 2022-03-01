//
//  HomeViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/24/22.
//

import UIKit
import CoreLocation

class HomeViewController: UITableViewController, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let imageView = UIImageView(image: UIImage(named: "logo_stamp"))
    
    let manager = CLLocationManager()
    
    var locationStr = ""
    var userEvents = [Event]()
    var localEvents = [Event]()
    var selectedEvent: Event?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        navigationBar.addSubview(imageView)
        //            imageView.layer.cornerRadius = Const.ImageSizeForLargeState / 2
        //            imageView.clipsToBounds = true
        imageView.tintColor = .label
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            imageView.leftAnchor.constraint(equalTo: navigationBar.leftAnchor, constant: 175),
            imageView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalToConstant: 30),
            imageView.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        manager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            print("Services Enabled")
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.startUpdatingLocation()
        } else {
            // Alert user that they need to enable location services.
            print("Services Disabled")
        }
        
        // Register xib.
        let headerNib = UINib.init(nibName: "CustomTableViewHeader", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "header_1")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        userEvents = CurrentUser.currentUser?.userEvents ?? [Event]()

        DispatchQueue.main.async {
            self.tableView.reloadSections(IndexSet([0]), with: .none)
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let height = navigationController?.navigationBar.frame.height else { return }
        moveAndResizeNavImage(for: height)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(locations[0]) { (placemarks, error) in
            if (error != nil) {
                print("error in reverseGeocode")
            }
            
            let placemark = placemarks! as [CLPlacemark]
            
            if placemark.count > 0 {
                let placemark = placemarks![0]
                
                if self.locationStr != placemark.locality! {
                    self.locationStr = placemark.locality!
                    self.tableView.reloadSections(IndexSet(integer: 1), with: .none)
                    
                    let localArea = "\(placemark.locality!)+\(placemark.administrativeArea!)"
                    CurrentLocation.location = localArea
                    self.getLocalEvents(loc: localArea)
                }
            }
        }
    }
    
    func getLocalEvents(loc: String) {
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
                // Create Subreddit object.
                do {
                    // Create json Object from downloaded data above and cast as [String: Any].
                    if let jsonObj = try JSONSerialization.jsonObject(with: validData, options: .mutableContainers) as? [String: Any] {
                        guard let data = jsonObj["events_results"] as? [[String: Any]]
                        else {
                            print("This isn't working")
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
                                  let thumbnail = event["thumbnail"] as? String
                            else {
                                print("There was an error with this event's data")
                                
                                continue
                            }
                            
                            guard let start = date["start_date"] as? String,
                                  let when = date["when"] as? String
                            else {
                                print("This isn't working")
                                return
                            }
                            
                            let dateStr = "\(start) | \(when)"
                            let addressStr = "\(address[0]), \(address[1])"

                            self.localEvents.append(Event(id: "", title: title, date: dateStr, address: addressStr, link: link, description: description, tickets: tickets, thumbnail: thumbnail))
                        }
                    }
                }
                catch{
                    print("Error: \(error.localizedDescription)")
                }
                
                DispatchQueue.main.async {
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
        
        imageView.transform = CGAffineTransform.identity
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
            
            cell.eventImageIV.layer.cornerRadius = 10
            cell.eventImageIV.image = localEvents[indexPath.row].image
            cell.eventDateLbl.text = localEvents[indexPath.row].date
            cell.eventTitleLbl.text = localEvents[indexPath.row].title
            cell.eventAddressLbl.text = localEvents[indexPath.row].address
        } else {
            let cell = cell as! CVTableViewCell
            
            cell.collectionView.reloadData()
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
        
        // Set selected event to be passed to DetailsViewController
        selectedEvent = localEvents[indexPath.row]
        
        // Show DetailsViewController.
        self.performSegue(withIdentifier: "goToDetails", sender: self)
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Call trashTapped with optional argument.
            // Optional argument is used to prevent redundant code.
            trashTapped(indexP: indexPath.row)
        }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    // MARK: - CollectionView data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userEvents.count + 1
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
            cell.eventImageIV.image = userEvents[indexPath.row].image
            cell.eventDateLbl.isHidden = false
            cell.eventDateLbl.text = userEvents[indexPath.row].date
            cell.eventTitleLbl.text = userEvents[indexPath.row].title
            cell.eventTitleLbl.textColor = .label
            cell.eventAddressLbl.text = userEvents[indexPath.row].address
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
            selectedEvent = userEvents[indexPath.row]
            
            // Show DetailsViewController.
            self.performSegue(withIdentifier: "goToDetails", sender: self)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Action if navigating to DetailsViewController.
        if let destination = segue.destination as? DetailsViewController {
            // Send selected event and userEvents array to DetailsViewController.
            destination.event = self.selectedEvent
            destination.userEvents = self.userEvents
        }
    }
}
