//
//  RestaurantReservationsStatisticsPage2.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/23/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class RestaurantReservationsStatisticsPage2: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let database = Firestore.firestore()
    @IBOutlet weak var tableView: UITableView!
    //clickRestaurantToReservationsStatsSegue
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var totalNumberOfReservationsLabel: UILabel!
    var reservationsFromRestaurant = [ReservationInfo]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.restaurantNameLabel.text = RestaurantReservationsStatisticsPage.restaurantSelected
        tableView.delegate = self
        tableView.dataSource = self
        grabReservations()
    }
    override func viewDidAppear(_ animated: Bool) {
        self.totalNumberOfReservationsLabel.text = ("Total Number Of Reservations for this Restaurant:      \(self.reservationsFromRestaurant.count)")
    }
    func grabReservations(){
        reservationsFromRestaurant = [ReservationInfo]()
        let docRef = self.database.collection("reservation").addSnapshotListener{[self]
            (QuerySnapshot, err) in
            if let err = err{
                //error occurred when trying to grab the data from firestore
                print("Error occurred when grabbing documents from database.")
                print("Error is: \(err)")
            }
            else{
                for doc in QuerySnapshot!.documents {
                    let Rcode = doc["restaurant_code"] as! String
                    if(Rcode == RestaurantReservationsStatisticsPage.restaurantCode){
                        let nameOnReservation = doc["reserved_by"] as! String
                        let reservationID = doc["reservation_id"] as! String
                        let partySize = doc["party_size"] as! String
                        let dateOfReservation = doc["day_of_reservation"] as! String
                        self.reservationsFromRestaurant.append(ReservationInfo(partySize: partySize, nameOnReservation: nameOnReservation, reservationID: reservationID, dateOfReservation: dateOfReservation))
                    }
                    tableView.reloadData()
                }
                print("Names: \(self.reservationsFromRestaurant)")
            }
        }
    }
    //Table View Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.reservationsFromRestaurant.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomizedReservationCell
        cell.dateOfReservationLabel.text = ("Reserved for: \(self.reservationsFromRestaurant[indexPath.row].dateOfReservation)")
        cell.nameOnReservationLabel.text = ("Reserved by: \(self.reservationsFromRestaurant[indexPath.row].nameOnReservation)")
        cell.partySizeLabel.text = ("Party Size: \(self.reservationsFromRestaurant[indexPath.row].partySize)")
        cell.reservationIDLabel.text = ("Reservation ID: \(self.reservationsFromRestaurant[indexPath.row].reservationID)")
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
struct ReservationInfo {
    var partySize: String
    var nameOnReservation: String
    var reservationID: String
    var dateOfReservation: String
}
class CustomizedReservationCell: UITableViewCell{
    
    @IBOutlet weak var partySizeLabel: UILabel!
    @IBOutlet weak var nameOnReservationLabel: UILabel!
    @IBOutlet weak var reservationIDLabel: UILabel!
    @IBOutlet weak var dateOfReservationLabel: UILabel!
}
