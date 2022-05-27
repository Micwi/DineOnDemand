//
//  ReservationHistoryPage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 2/28/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class ReservationHistoryPage: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var table: UITableView!
    var currentReservations = [[String: Any]](); var pastReservations = [[String: Any]]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        print("View Appeared")
        populateArrays()
    }
    
    func populateArrays() {
        currentReservations = [[String: Any]](); pastReservations = [[String: Any]]()
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        database.collection("reservation").whereField("account_id", isEqualTo: userID).getDocuments() { (querySnapshot, err) in
            if let err = err { print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents { let data = document.data()
                    if data["status"] as! String == "current" { self.checkReservationTimes(data: data) }
                    else if data["status"] as! String == "past" { self.pastReservations.append(data) }
                }
            }
            self.sortReservationArrays()
            self.table.reloadData()
        }
    }
    
    // Checks each reservation in the database for the currently signed in user to see if any are 15 minutes or less before the current time
    func checkReservationTimes(data: [String: Any]) {
        let reservationDate = data["day_of_reservation"] as! String
        let timeFormatter = DateFormatter(); timeFormatter.dateFormat = "MM/dd/yy h:mm a"
        let reservationTime = timeFormatter.date(from: "\(reservationDate) \(data["time_of_reservation"]!)")
        if Date() >= reservationTime!.addingTimeInterval(900) {
            // Runs when the time is 15 minutes or more past the reservation time
            self.changeReservationStatus(reservationID: data["reservation_id"] as! String)
            var tempData = data; tempData["no_show"] = "true"
            self.pastReservations.append(tempData)
        } else {
            // Runs when the time is not 15 mins or more past the reservation time
            self.currentReservations.append(data)
        }
    }
    
    // Changes a reservation's status to 'past' if the current time is 15 minutes or more past the reservation time
    func changeReservationStatus(reservationID: String) {
        self.database.collection("reservation").document("reservation_\(reservationID)").setData([
            "status": "past",
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    func sortReservationArrays() {
        self.currentReservations.sort {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! reservationCell
        if indexPath.section == 0 { // Use data from 'currentReservations' array
            cell.restaurantName.text = "\(currentReservations[indexPath.row]["restaurant_name"]!)"
            cell.dateTime.text = "\(currentReservations[indexPath.row]["day_of_reservation"]!) at \(currentReservations[indexPath.row]["time_of_reservation"]!)"
            cell.partySize.text = "Party of \(currentReservations[indexPath.row]["party_size"]!)"
            cell.reservationID.text = "Reservation ID: \(currentReservations[indexPath.row]["reservation_id"]!)"
        } else if indexPath.section == 1 { // Use data from 'pastReservations' array
            cell.restaurantName.text = "\(pastReservations[indexPath.row]["restaurant_name"]!)"
            cell.dateTime.text = "\(pastReservations[indexPath.row]["day_of_reservation"]!) at \(pastReservations[indexPath.row]["time_of_reservation"]!)"
            cell.partySize.text = "Party of \(pastReservations[indexPath.row]["party_size"]!)"
            cell.reservationID.text = "Reservation ID: \(pastReservations[indexPath.row]["reservation_id"]!)"
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
        if section == 0 { sectionTitle = "Current Reservations" } else if section == 1 { sectionTitle = "Past Reservations" }
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
            return currentReservations.count
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
            let reservationID = currentReservations[indexPath.row]["reservation_id"] as! String
            let docRef = database.collection("reservation").document("reservation_\(reservationID)")
            docRef.getDocument { snapshot, error in
                guard let data = snapshot?.data(), error == nil else {
                    return
                }
                if data["status"] as! String == "current" {
                    self.cancelReservationAlert(reservationID: reservationID)
                } else if data["status"] as! String == "past" && indexPath.section == 0 {
                    self.populateArrays()
                }
            }
        }
    }
    
    func cancelReservationAlert(reservationID: String) {
        let alertController = UIAlertController(title: "Reservation", message: "Would you like to cancel this reservation?", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Yes", style: .cancel) { _ in
            self.cancelReservation(reservationID: reservationID)
        }
        let cancelAction = UIAlertAction(title: "No", style: .default) { _ in}
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func cancelReservation(reservationID: String) {
        self.database.collection("reservation").document("reservation_\(reservationID)").delete() { err in
            if let err = err { print("Error deleting document: \(err)")
            } else { print("Document successfully deleted!"); self.populateArrays() }
        }
    }
    
}

class reservationCell: UITableViewCell {
    @IBOutlet weak var restaurantName: UILabel!
    @IBOutlet weak var dateTime: UILabel!
    @IBOutlet weak var partySize: UILabel!
    @IBOutlet weak var reservationID: UILabel!
}
