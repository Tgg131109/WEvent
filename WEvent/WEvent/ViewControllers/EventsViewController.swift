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
    @IBOutlet weak var msgLbl: UILabel!
    
    var userUpcomingEvents = [Event]()
    var userPastEvents = [Event]()
    var userSavedEvents = [Event]()
    var userInvitedEvents = [Event]()
    var eventTypeArray = [[Event]]()
    var selectedEvent: Event?
    
    var editEvent = false
    var updateLV = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segCon.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1)], for: .selected)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let allUserEvents = CurrentUser.currentUser?.userEvents ?? [Event]()
        
        userUpcomingEvents = allUserEvents.filter({$0.status != ""})
        userPastEvents = allUserEvents.filter({$0.isFavorite == true})
        userSavedEvents = allUserEvents.filter({$0.isFavorite == true})
        userInvitedEvents = allUserEvents.filter({$0.status == "invited"})
        
        eventTypeArray = [userUpcomingEvents, userPastEvents, userSavedEvents, userInvitedEvents]
        
        tableView.reloadData()
//        if updateLV {
//            self.tableView.reloadData()
//        }
        
        if editEvent {
            editEvent = false
            
            // Show CreateEventViewController.
            self.performSegue(withIdentifier: "goToEdit", sender: self)
        }
    }
    
    @IBAction func segConChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
        
        msgLbl.isHidden = !eventTypeArray[segCon.selectedSegmentIndex].isEmpty
    }
    
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventTypeArray[segCon.selectedSegmentIndex].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "table_cell_5", for: indexPath) as! CustomTableViewCell
        let dataToShow = eventTypeArray[segCon.selectedSegmentIndex]
        let event = dataToShow[indexPath.row]
        
        cell.eventImageIV.layer.cornerRadius = 10
        
        if segCon.selectedSegmentIndex != 0 {
            cell.eventImageIV.kf.indicatorType = .activity
            cell.eventImageIV.kf.setImage(with: URL(string: event.imageUrl), placeholder: UIImage(named: "logo_stamp"), options: [.transition(.fade(1))], completionHandler: { result in
                switch result {
                case .success(let value):
                    dataToShow[indexPath.row].image = value.image
                    event.image = value.image
                    
                    switch self.segCon.selectedSegmentIndex {
                    case 1:
                        self.userPastEvents[indexPath.row].image = value.image
                        break
                    case 2:
                        self.userSavedEvents[indexPath.row].image = value.image
                        break
                    case 3:
                        self.userInvitedEvents[indexPath.row].image = value.image
                        break
                    default:
                        break
                    }
                    
                    CurrentUser.currentUser?.userEvents?.first(where: { $0.id == event.id})?.image = value.image
                    break
                    
                case .failure(let error):
                    print("Error getting image: \(error)")
                    break
                }
            })
        } else {
            cell.eventImageIV.image = event.image
        }

        cell.eventDateLbl.text = event.date
        
        if event.isCreated {
            let title = NSMutableAttributedString(string: "\(event.title) ")
            let imageAttachment = NSTextAttachment()
            
            // Resize image
            let targetSize = CGSize(width: 14, height: 14)
            imageAttachment.image = UIImage(named: "logo_stamp")?.scalePreservingAspectRatio(targetSize: targetSize).withTintColor(UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1))
            
            let imageStr = NSAttributedString(attachment: imageAttachment)
            
            title.append(imageStr)
            
            cell.eventTitleLbl.attributedText = title
        } else {
            cell.eventTitleLbl.text = event.title
        }
        
        cell.eventAddressLbl.text = event.address
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
                self.updateLV = true
            }
        }
    }
}
