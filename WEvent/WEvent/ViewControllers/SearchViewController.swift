//
//  SearchViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/23/22.
//

import UIKit
import Firebase
import Kingfisher

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {

    @IBOutlet weak var activityView: CustomActivityIndicatorView!
    @IBOutlet weak var resultCountLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var userId = Auth.auth().currentUser?.uid
    var allUserEvents = [Event]()
    var location = ""
    var isSearching = false
    var suggestedSearches = ["music festival", "family friendly events", "car show"]
    var recentSearches = [String]()
    var nonSearchBarInputStr = ""
    var searchResults = [Event]()
    var selectedEvent: Event?
    
    var favoritesDelegate: EventDataDelegate!
    var getImageDelegate: GetImageDelegate!
    
    private var searchController: UISearchController {
        let sc = UISearchController(searchResultsController: nil)
        
        sc.searchResultsUpdater = self
        sc.delegate = self
        sc.searchBar.delegate = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Find Events"
        sc.definesPresentationContext = true
        
        return sc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.searchController = searchController
        
        favoritesDelegate = FirebaseHelper()
        getImageDelegate = GetImageHelper()
        
        recentSearches = UserDefaults.standard.stringArray(forKey: "\(userId!)recentSearches") ?? [String]()
        
        allUserEvents = CurrentUser.currentUser?.userEvents ?? [Event]()
        
        if CurrentLocation.location != nil {
            location = CurrentLocation.location!.searchStr
        } else {
            print("unable to get location at this time")
            searchController.searchBar.isHidden = true
            self.tableView.isHidden = true
        }

        resultCountLbl.text = recentSearches.isEmpty ? "Suggested Searches" : "Recent Searches"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Update user defaults.
        UserDefaults.standard.set(recentSearches, forKey: "\(userId!)recentSearches")
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        
        if searchBar.text!.isEmpty {
            isSearching = false
            
            tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        isSearching = true
        
        var inputStr = searchBar.text ?? ""
        
        if inputStr.isEmpty {
            inputStr = nonSearchBarInputStr
        }
        
        if !inputStr.isEmpty {
            self.navigationItem.searchController?.searchBar.isHidden = true
            activityView.activityIndicator.startAnimating()
            activityView.isHidden = false

            // Run query
            let formattedSearch = inputStr.replacingOccurrences(of: " ", with: "+")
            let searchStr = ("\(formattedSearch)+in+\(location)")
            print(searchStr)
            
            findEvents(searchStr: searchStr)
            nonSearchBarInputStr = ""
            
            // Limit recent searches to 20 items.
            if recentSearches.count > 19 {
                recentSearches.removeLast()
            }
            
            recentSearches.insert(inputStr, at: 0)
        }
    }
    
    func findEvents(searchStr: String) {
        // Clear searchResults array.
        searchResults.removeAll()
        
        // Create default configuration.
        let config = URLSessionConfiguration.default

        // Create session.
        let session = URLSession(configuration: config)
        
        // Validate URL.
        if let validURL = URL(string: "https://serpapi.com/search.json?engine=google_events&q=\(searchStr)&api_key=f5f6c4283773ca865ad9b308708d823a2f01101aa39aeabcba72bfde7014c9e8") {
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
                    
                    print("JSON object creation failed.")
                    return
                }
                
                // Create event object.
                do {
                    // Create json Object from downloaded data above and cast as [String: Any].
                    if let jsonObj = try JSONSerialization.jsonObject(with: validData, options: .mutableContainers) as? [String: Any] {
                        guard let data = jsonObj["events_results"] as? [[String: Any]]
                        else {
                            print("This isn't working")
                            return
                        }
                        
                        for event in data {
                            // Step through outer level data to get to relevant post data.
                            guard let title = event["title"] as? String,
                                  let date = event["date"] as? [String: Any],
                                  let address = event["address"] as? [String],
                                  let link = event["link"] as? String,
                                  let description = event["description"] as? String,
                                  let tickets = event["ticket_info"] as? [[String: Any]],
                                  let imageUrl = event["thumbnail"] as? String
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
                            let eventImage = UIImage(named: "logo_placeholder")!
                            
                            self.searchResults.append(Event(id: "", title: title, date: dateStr, address: addressStr, link: link, description: description, tickets: tickets, imageUrl: imageUrl, image: eventImage, groupId: "", organizerId: "", attendeeIds: [String](), pendingIds: [String]()))
                        }
                    }
                }
                catch{
                    print("Error: \(error.localizedDescription)")
                }
                
                self.searchResults = self.searchResults.sorted(by: { $0.dateStamp < $1.dateStamp })
                
                DispatchQueue.main.async {
                    self.tableView.reloadSections(IndexSet([0]), with: .fade)
                    self.activityView.activityIndicator.stopAnimating()
                    self.activityView.isHidden = true
                    self.navigationItem.searchController?.searchBar.isHidden = false
                }
            })
            // Start task.
            task.resume()
        }
    }
    
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            resultCountLbl.text = searchResults.count > 1 ? "\(searchResults.count) events found" : "1 event found"
            return searchResults.count
        } else {
            resultCountLbl.text = recentSearches.isEmpty ? "Suggested Searches" : "Recent Searches"
            return recentSearches.isEmpty ? suggestedSearches.count : recentSearches.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: isSearching ? "table_cell_4" : "table_cell_3", for: indexPath)
        
        if isSearching {
            if searchResults.count > indexPath.row {
                let cell = cell as! CustomTableViewCell
                let event = searchResults[indexPath.row]
                
                cell.eventImageIV.layer.cornerRadius = 10
                cell.eventImageIV.kf.indicatorType = .activity
                cell.eventImageIV.kf.setImage(with: URL(string: event.imageUrl), placeholder: UIImage(named: "logo_placeholder"), options: [.transition(.fade(1))], completionHandler: { result in
                    switch result {
                    case .success(let value):
                        event.image = value.image
                        self.searchResults[indexPath.row].image = value.image
                        break
                        
                    case .failure(let error):
                        if !error.isTaskCancelled && !error.isNotCurrentTask {
                            print("Error getting image: \(error)")
                        }
                        break
                    }
                })
                cell.eventDateLbl.text = event.date
                cell.eventTitleLbl.text = event.title
                cell.eventAddressLbl.text = event.address
                cell.favButton.isSelected = allUserEvents.filter({$0.isFavorite == true}).contains(where: {$0.title == event.title})
                cell.favButton.tintColor = cell.favButton.isSelected ? UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1) : .systemGray
                
                cell.favTapped = {(favButton) in
                    self.favoritesDelegate.setFavorite(event: event, isFav: !favButton.isSelected)
                    favButton.isSelected.toggle()
                    favButton.tintColor = favButton.isSelected ? UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1) : .systemGray
                }
            } else {
                print("wait")
            }
        } else {
            cell.textLabel?.text = recentSearches.isEmpty ? suggestedSearches[indexPath.row] : recentSearches[indexPath.row]
        }

        return cell
    }

    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row for animation purposes.
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        if isSearching {
            // Set selected event to be passed to DetailsViewController
            selectedEvent = searchResults[indexPath.row]
            
            // Show DetailsViewController.
            self.performSegue(withIdentifier: "goToDetails", sender: self)
        } else {
            let cell = tableView.cellForRow(at: indexPath)

            if let cellStr = cell?.textLabel?.text {
                navigationItem.searchController!.isActive = true
                navigationItem.searchController!.searchBar.text = cellStr
                
                nonSearchBarInputStr = cellStr
                self.searchBarSearchButtonClicked(searchController.searchBar)
            }
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
            }
        }
    }
}
