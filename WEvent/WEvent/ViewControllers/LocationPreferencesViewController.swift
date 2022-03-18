//
//  LocationPreferencesViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 3/6/22.
//

import UIKit
import Firebase

class LocationPreferencesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var headerLbl: UILabel!
    @IBOutlet weak var currentLocationSW: UISwitch!
    @IBOutlet weak var locationTF: UITextField!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var suggestionTableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    
    var locations = [Location]()
    var filteredLocations = [Location]()
    var selectedCity: Location?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        headerLbl.text = CurrentLocation.preferredLocation?.city
        locationTF.text = CurrentLocation.preferredLocation?.fullName
        
        if let useCurrentLocation = UserDefaults.standard.object(forKey: "useCurrentLocation") as? Bool {
            currentLocationSW.isOn = useCurrentLocation
            
            if !useCurrentLocation {
                locationTF.isEnabled = true
            }
        } else {
            locationTF.textColor = .systemGray3
            locationTF.isEnabled = false
        }
        
        getLocationsFromFile()
        
        locations = locations.sorted(by: { $0.city > $1.city })
        filteredLocations = locations
        
        suggestionTableView.layer.cornerRadius = 10
        suggestionTableView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    
    @IBAction func doneBtnTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    
    @IBAction func switchChanged(_ sender: UISwitch) {
        if currentLocationSW.isOn {
            headerLbl.text = CurrentLocation.location?.city
            locationTF.text = CurrentLocation.location?.fullName
            locationTF.textColor = .systemGray3
            locationTF.isEnabled = false
            
            if locationTF.text != CurrentLocation.preferredLocation?.fullName {
                saveButton.isEnabled = true
            }
            
            CurrentLocation.preferredLocation = CurrentLocation.location
        } else {
            headerLbl.text = "-"
            locationTF.text = ""
            locationTF.textColor = .label
            locationTF.isEnabled = true
            locationTF.becomeFirstResponder()
        }
    }

    @IBAction func suggestLocation(_ sender: CustomTextField) {
        suggestionTableView.isHidden = false
    }
    
    @IBAction func hideSuggestions(_ sender: CustomTextField) {
        suggestionTableView.isHidden = true
        
        if !locationTF.text!.isEmpty && selectedCity == nil {
            if let loc = locations.first(where: { $0.city.lowercased() == locationTF.text?.lowercased() }) {
                selectedCity = loc
            } else {
                // Alert user that the city they entered cannot be found.
            }
        }
    }
    
    @IBAction func updateSuggestionResults(_ sender: CustomTextField) {
        if !locationTF.text!.isEmpty {
            filteredLocations = locations.filter({ $0.city.lowercased().hasPrefix(locationTF.text!.lowercased()) })
            suggestionTableView.reloadData()
            
            if !saveButton.isEnabled {
                saveButton.isEnabled = true
            }
        } else {
            if saveButton.isEnabled {
                saveButton.isEnabled = false
            }
        }
    }
    
    @IBAction func savePreferences(_ sender: UIButton) {
        let userId = Auth.auth().currentUser?.uid
        // Check that provided city is set.
        if !currentLocationSW.isOn && selectedCity != nil {
            CurrentLocation.preferredLocation = selectedCity
            
            let lat = selectedCity?.coordinates[0]
            let lon = selectedCity?.coordinates[1]
            let latStr = "\(lat!)"
            let lonStr = "\(lon!)"
            let locationData = [selectedCity?.city, selectedCity?.state, selectedCity?.id, latStr, lonStr]
            
            // Update user defaults.
            UserDefaults.standard.set(locationData, forKey: "\(userId!)preferredLocation")
        } else {
            if currentLocationSW.isOn {
                CurrentLocation.preferredLocation = CurrentLocation.location
            } else {
                // Alert user to select a city.
            }
        }
        
        // Update user defaults.
        UserDefaults.standard.set(currentLocationSW.isOn, forKey: "\(userId!)useCurrentLocation")
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // Method to create Store objects from StoresWithItems.json file.
    func getLocationsFromFile() {
        // Get path to zips.json file.
        if let path = Bundle.main.path(forResource: "zips", ofType: ".json") {
            // Create URL with path created above.
            let url = URL(fileURLWithPath: path)
            
            do {
                // Data object from the URL created above.
                let data = try Data.init(contentsOf: url)
                
                // Create json Object from data file created above and cast as Dictionary of [String: Any].
                if let jsonObj = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [[String: Any]] {
                    for zip in jsonObj {
                        guard let city = zip["city"] as? String,
                              let loc = zip["loc"] as? [Double],
                              let state = zip["state"] as? String,
                              let id = zip["_id"] as? String
                        else {
                            print("Error")
                            return
                        }
                        // Create a new Location object and append to locations array.
                        locations.append(Location(city: city.capitalized, coordinates: loc, state: state, id: id))
                    }
                }
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLocations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "table_cell_7", for: indexPath)
        let location = filteredLocations[indexPath.row]
        
        cell.textLabel?.text = "\(location.city), \(location.state)"
        cell.detailTextLabel?.text = location.id
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row for animation purposes.
        tableView.deselectRow(at: indexPath, animated: true)
        
        let location = filteredLocations[indexPath.row]
        selectedCity = location
        
        headerLbl.text = location.city
        locationTF.text = "\(location.city), \(location.state)"
        suggestionTableView.isHidden = true
    }
}
