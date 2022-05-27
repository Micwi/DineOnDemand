//
//  MakeReservationPage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 3/6/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class MakeReservationPage: UIViewController, UITextFieldDelegate {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var partySizeStepper: UIStepper!
    @IBOutlet weak var partySizeLabel: UILabel!
    @IBOutlet weak var enterNameLabel: UITextField!
    @IBOutlet weak var nameTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nameTF.delegate = self
        self.datePicker.minimumDate = Date()
        configureDatePickers()
    }
    
    func configureDatePickers() {
        let docRef = self.database.collection("restaurant").document("restaurant_\(RestaurantDetailsPage.restaurantCode)").collection("hours").document("current_hours")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            let selectedDate = self.datePicker.date; let todaysDate = Date()
            let dayOfWeekFormatter = DateFormatter(); dayOfWeekFormatter.dateFormat = "EEEE"
            let selectedDayOfTheWeekString = dayOfWeekFormatter.string(from: selectedDate).lowercased()
            let todaysDayOfTheWeekString = dayOfWeekFormatter.string(from: todaysDate).lowercased()
            
            let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "h:mm a"
            let hours = data["\(selectedDayOfTheWeekString)_hours"] as! String
            let hoursSplit = hours.components(separatedBy: " - ")
            let currentTimeString = dateFormatter.string(from: Date())
            let openingTimeString = hoursSplit[0]
            let closingTimeString = hoursSplit[1]
            let currentTimeDate = dateFormatter.date(from: currentTimeString)?.addingTimeInterval(-18000) // Subtracting 5 hours
            let openingTimeDate = dateFormatter.date(from: openingTimeString)?.addingTimeInterval(-14400) // Subtracting 4 hours
            let closingTimeDate = dateFormatter.date(from: closingTimeString)?.addingTimeInterval(-18000) // Subtracting 5 hours
            self.timePicker.maximumDate = closingTimeDate?.addingTimeInterval(14400) // We set this to 14400 because we don't want them to be able to book reservations when the restaurant closes.
            
            print("Current Time: \(currentTimeDate!)")
            print("Opening Time: \(openingTimeDate!)")
            print("Closing Time: \(closingTimeDate!)")
            
            if selectedDayOfTheWeekString == todaysDayOfTheWeekString && currentTimeDate!.addingTimeInterval(3600) > openingTimeDate! && currentTimeDate!.addingTimeInterval(3600) < closingTimeDate! {
                // Runs when the selected date is todays date and the current time is past the opening time
                print("Restaurant is Open. Current time is between opening time and closing time.")
                self.datePicker.minimumDate = Date()
                self.timePicker.minimumDate = currentTimeDate!.addingTimeInterval(19800) // Adding 5 hours + 30 minutes
            } else if selectedDayOfTheWeekString == todaysDayOfTheWeekString && currentTimeDate!.addingTimeInterval(3600) > closingTimeDate! {
                // Runs when the selected date is todays date and the current time is past the closing time (push date forward)
                print("Restaurant is Closed for the night. Current time is after closing time.")
                var dateComponent = DateComponents(); dateComponent.day = 1
                let futureDate = Calendar.current.date(byAdding: dateComponent, to: Date())
                self.datePicker.minimumDate = futureDate
                self.configureDatePickers()
            } else {
                // Runs when the selected date is a future date or before the restaurant opens on the current date
                print("Restaurant has not opened yet on the selected date. All times are available during hours.")
                self.timePicker.minimumDate = openingTimeDate?.addingTimeInterval(18000) // Adding 5 hours
            }
        }
    }
    
    // Runs when a date is selected
    @IBAction func dateChanged(_ sender: Any) {
        configureDatePickers()
    }
    
    // Runs when a time is selected
    @IBAction func timeChanged(_ sender: Any) {
        // We might not actually touch this method
    }
    
    @IBAction func stepperTapped(_ sender: Any) {
        partySizeLabel.text = String(Int(partySizeStepper.value))
    }
    
    @IBAction func makeReservationButton(_ sender: Any) {
        if "\(enterNameLabel.text!)".trimmingCharacters(in: .whitespaces).isEmpty { enterNameAlert() }
        else { getNumberOfReservations() }
    }
    
    func getNumberOfReservations() {
        database.collection("reservation").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                var reservationID = 0
                for document in querySnapshot!.documents {
                    let tempReservationID = Int(document.data()["reservation_id"] as! String)!
                    if reservationID < tempReservationID { reservationID = tempReservationID }
                }
                self.createReservation(reservationID: reservationID + 1)
            }
        }
    }
    
    func createReservation(reservationID: Int) {
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let reservationID = reservationID
        let selectedDate = datePicker.date
        let selectedTime = timePicker.date
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "MM/dd/yy"
        let timeFormatter = DateFormatter(); timeFormatter.dateFormat = "h:mm a"
        let selectedDateString = dateFormatter.string(from: selectedDate)
        let selectedTimeString = timeFormatter.string(from: selectedTime)
        
        self.database.collection("reservation").document("reservation_\(reservationID)").setData([
            "account_id": userID,
            "day_of_reservation": selectedDateString,
            "party_size": partySizeLabel.text!,
            "reservation_id": String(reservationID),
            "restaurant_code": RestaurantDetailsPage.restaurantCode,
            "restaurant_name": RestaurantDetailsPage.restaurantName,
            "status": "current",
            "time_of_reservation": selectedTimeString,
            "reserved_by": enterNameLabel.text!,
            "no_show": "false"
        ], merge: false) { err in
            if let err = err { print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
                self.reservationSuccessfulAlert(date: selectedDateString, time: selectedTimeString)
            }
        }
    }
    
    func reservationSuccessfulAlert(date: String, time: String) {
        let alertController = UIAlertController(title: "Reservation", message: "Your reservation for \(RestaurantDetailsPage.restaurantName) on \(date) at \(time) has been placed successfully!", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(okayAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func enterNameAlert() {
        let alertController = UIAlertController(title: "Enter Name", message: "You must enter your name before placing a reservation!", preferredStyle: .actionSheet)
        let okayAction = UIAlertAction(title: "Okay", style: .default) { _ in }
        alertController.addAction(okayAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { self.view.endEditing(true) }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == 1 {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.frame = CGRect(x:self.view.frame.origin.x, y:self.view.frame.origin.y - 100, width:self.view.frame.size.width, height:self.view.frame.size.height)
            })
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 1 {
            UIView.animate(withDuration: 0.3, animations: {
                self.view.frame = CGRect(x:self.view.frame.origin.x, y:self.view.frame.origin.y + 100, width:self.view.frame.size.width, height:self.view.frame.size.height)
            })
        }
    }
    
}
