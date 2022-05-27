//
//  ManagerReservationsPage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 3/23/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class ManagerReservationsPage: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let database = Firestore.firestore()
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var table: UITableView!
    
    var upcomingReservations = [[String: Any]](); var pastReservations = [[String: Any]]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        Load.empRestaurantCode = UserDefaults().dictionary(forKey: "userData")!["restaurant_code"] as! String
        populateArrays()
    }
    
    @IBAction func dateSelected(_ sender: Any) {
        populateArrays()
    }
    
    @IBAction func refreshButton(_ sender: Any) {
        populateArrays()
    }
    
    func populateArrays() {
        upcomingReservations = [[String: Any]](); pastReservations = [[String: Any]]()
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "MM/dd/yy"
        let selectedDate = dateFormatter.string(from: datePicker.date)
        database.collection("reservation")
            .whereField("restaurant_code", isEqualTo: Load.empRestaurantCode)
            .whereField("day_of_reservation", isEqualTo: selectedDate)
            .getDocuments() { (querySnapshot, err) in
            if let err = err { print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents { let data = document.data()
                    if data["status"] as! String == "current" { self.checkReservationTimes(data: data) }
                    else if data["status"] as! String == "past" { self.pastReservations.append(data) }
                }
                self.sortReservationArrays()
                self.table.reloadData()
            }
        }
    }
    
    // Checks each reservation in the database for the currently signed in user to see if any are 15 minutes or less before the current time
    func checkReservationTimes(data: [String: Any]) {
        let reservationDate = data["day_of_reservation"] as! String
        let timeFormatter = DateFormatter(); timeFormatter.dateFormat = "MM/dd/yy h:mm a"
        let reservationTime = timeFormatter.date(from: "\(reservationDate) \(data["time_of_reservation"]!)")
        if Date() >= reservationTime!.addingTimeInterval(900) {
            // Runs when the time is 15 minutes or more past the reservation time
            self.changeReservationStatus(reservationID: data["reservation_id"] as! String, noShowStatus: "true")
            var tempData = data; tempData["no_show"] = "true"
            self.pastReservations.append(tempData)
        } else {
            // Runs when the time is not 15 mins or more past the reservation time
            self.upcomingReservations.append(data)
        }
    }
    
    // Changes a reservation's status to 'past' if the party is marked as 'present' by an Employee or Manager
    func changeReservationStatus(reservationID: String, noShowStatus: String) {
        self.database.collection("reservation").document("reservation_\(reservationID)").setData([
            "status": "past",
            "no_show": noShowStatus,
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    func sortReservationArrays() {
        self.upcomingReservations.sort {
            item1, item2 in
            let date1 = item1["day_of_reservation"] as! String
            let date2 = item2["day_of_reservation"] as! String
            let time1 = item1["time_of_reservation"] as! String
            let time2 = item2["time_of_reservation"] as! String
            if date1 == date2 { return time1 > time2 } else { return date1 > date2 }
        }
        self.pastReservations.sort {
            item1, item2 in
            let date1 = item1["day_of_reservation"] as! String
            let date2 = item2["day_of_reservation"] as! String
            let time1 = item1["time_of_reservation"] as! String
            let time2 = item2["time_of_reservation"] as! String
            if date1 == date2 { return time1 > time2 } else { return date1 > date2 }
        }
    }
    
    // Populates the cells with data
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! empReservationCell
        if indexPath.section == 0 { // Use data from 'upcomingReservations' array
            cell.reservedByLabel.text = "\(upcomingReservations[indexPath.row]["reserved_by"]!)"
            cell.timeLabel.text = "\(upcomingReservations[indexPath.row]["time_of_reservation"]!)"
            cell.partyLabel.text = "Party of \(upcomingReservations[indexPath.row]["party_size"]!)"
            cell.reservationID.text = "Reservation ID: \(upcomingReservations[indexPath.row]["reservation_id"]!)"
            if upcomingReservations[indexPath.row]["no_show"] as! String == "true" { cell.noShowLabel.text = "No Show"
            } else { cell.noShowLabel.text = "" }
        } else if indexPath.section == 1 { // Use data from 'pastReservations' array
            cell.reservedByLabel.text = "\(pastReservations[indexPath.row]["reserved_by"]!)"
            cell.timeLabel.text = "\(pastReservations[indexPath.row]["time_of_reservation"]!)"
            cell.partyLabel.text = "Party of \(pastReservations[indexPath.row]["party_size"]!)"
            cell.reservationID.text = "Reservation ID: \(pastReservations[indexPath.row]["reservation_id"]!)"
            if pastReservations[indexPath.row]["no_show"] as! String == "true" { cell.noShowLabel.text = "No Show"
            } else { cell.noShowLabel.text = "" }
        }
        return(cell)
    }
    
    // Sets the height of the cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return(123)
    }
    
    // Sets the section titles
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle = String()
        if section == 0 { sectionTitle = "Upcoming" } else if section == 1 { sectionTitle = "Marked as Present or No Show" }
        return sectionTitle
    }
    
    // Sets the number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 2; if pastReservations.isEmpty { numberOfSections = 1 }
        return(numberOfSections)
    }
    
    // Sets the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return upcomingReservations.count
        } else if section == 1 {
            return pastReservations.count
        }
        return(0)
    }
    
    // Ran when you tap a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Section Tapped: \(indexPath.section)")
        table.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            markAsPresentAlert(reservationID: upcomingReservations[indexPath.row]["reservation_id"] as! String)
        }
    }
    
    func markAsPresentAlert(reservationID: String) {
        let alertController = UIAlertController(title: "Reservation", message: "Would you like to mark this party as present?", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Yes", style: .default) { _ in
            self.changeReservationStatus(reservationID: reservationID, noShowStatus: "false")
            self.populateArrays()
        }
        let cancelAction = UIAlertAction(title: "No", style: .cancel) { _ in}
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func signOutButtonTapped(_ sender: Any) {
        do {
            try FirebaseAuth.Auth.auth().signOut()
            print("Sign out was successful!")
            UserDefaults().removeObject(forKey: "userData")
            self.performSegue(withIdentifier: "SignOut", sender: self)
        } catch { }
    }
    
}
