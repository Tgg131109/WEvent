//
//  SearchViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/23/22.
//

import UIKit

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {

    @IBOutlet weak var resultCountLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var location = ""
    var isSearching = false
    var suggestedSearches = ["music festival", "family friendly events", "car show"]
    var recentSearches = [String]()
    var searchResults = [Event]()
    var selectedEvent: Event?
    
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
        
        location = CurrentLocation.location
        resultCountLbl.text = recentSearches.isEmpty ? "Suggested Searches" : "Recent Searches"
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
        
        if !searchBar.text!.isEmpty {
            // Run query
            let formattedSearch = searchBar.text?.replacingOccurrences(of: " ", with: "+")
            let searchStr = ("\(formattedSearch!)+in+\(location)")
            print(searchStr)
            
            findEvents(searchStr: searchStr)
            recentSearches.append(searchBar.text!)
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
                            // Step through outer level data to get to relevant post data.
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
                            
                            self.searchResults.append(Event(id: "", title: title, date: dateStr, address: addressStr, link: link, description: description, tickets: tickets, thumbnail: thumbnail))
                        }
                    }
                }
                catch{
                    print("Error: \(error.localizedDescription)")
                }
                
                print("reloading table")
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
            // Start task.
            task.resume()
        }
    }
    
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            resultCountLbl.text = "\(searchResults.count) events found"
            return searchResults.count
        } else {
            resultCountLbl.text = recentSearches.isEmpty ? "Suggested Searches" : "Recent Searches"
            return recentSearches.isEmpty ? suggestedSearches.count : recentSearches.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: isSearching ? "table_cell_4" : "table_cell_3", for: indexPath)

        if isSearching {
            let cell = cell as! CustomTableViewCell

            cell.eventImageIV.layer.cornerRadius = 10
            cell.eventImageIV.image = searchResults[indexPath.row].image
            cell.eventDateLbl.text = searchResults[indexPath.row].date
            cell.eventTitleLbl.text = searchResults[indexPath.row].title
            cell.eventAddressLbl.text = searchResults[indexPath.row].address
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

            navigationItem.searchController!.isActive = true
            navigationItem.searchController!.searchBar.text = cell?.textLabel?.text
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Action if navigating to DetailsViewController.
        if let destination = segue.destination as? DetailsViewController {
            // Send selected event and userEvents array to DetailsViewController.
            destination.event = self.selectedEvent
//            destination.userEvents = self.userEvents
        }
    }
}
