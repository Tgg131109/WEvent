//
//  EventsViewController.swift
//  WEvent
//
//  Created by Toby Gamble on 2/23/22.
//

import UIKit

class EventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var segCon: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var allUserEvents = [Event]()
    var userUpcomingEvents = [Event]()
    var userPastEvents = [Event]()
    var userSavedEvents = [Event]()
    var eventTypeArray = [[Event]]()
    var selectedEvent: Event?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        allUserEvents = CurrentUser.currentUser?.userEvents ?? [Event]()
        userUpcomingEvents = allUserEvents.filter({$0.status != ""})
        userPastEvents = allUserEvents.filter({$0.isFavorite == true})
        userSavedEvents = allUserEvents.filter({$0.isFavorite == true})
        
        eventTypeArray = [userUpcomingEvents, userPastEvents, userSavedEvents]
        
        segCon.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1)], for: .selected)
    }
    
    @IBAction func segConChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventTypeArray[segCon.selectedSegmentIndex].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "table_cell_5", for: indexPath) as! CustomTableViewCell
        let dataToShow = eventTypeArray[segCon.selectedSegmentIndex]
        
        cell.eventImageIV.layer.cornerRadius = 10
        cell.eventImageIV.image = dataToShow[indexPath.row].image
        cell.eventDateLbl.text = dataToShow[indexPath.row].date
        cell.eventTitleLbl.text = dataToShow[indexPath.row].title
        cell.eventAddressLbl.text = dataToShow[indexPath.row].address
        cell.favButton.isHidden = true

        return cell
    }

    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row for animation purposes.
        tableView.deselectRow(at: indexPath, animated: true)
        
        let dataToShow = eventTypeArray[segCon.selectedSegmentIndex]
        
        // Set selected event to be passed to DetailsViewController
        selectedEvent = dataToShow[indexPath.row]
        
        // Show DetailsViewController.
        self.performSegue(withIdentifier: "goToDetails", sender: self)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Action if navigating to DetailsViewController.
        if let destination = segue.destination as? DetailsViewController {
            // Send selected event and userEvents array to DetailsViewController.
            destination.event = self.selectedEvent
        }
    }
}
