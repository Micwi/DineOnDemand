//
//  DriverHomePage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 3/24/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class DriverHomePage: UIViewController, UIAdaptivePresentationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    private let database = Firestore.firestore()
    @IBOutlet weak var table: UITableView!
    var ordersToDeliver = [[String: Any]](); var ordersBeingDelivered = [[String: Any]]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        populateArrays()
    }
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOrderDetails" {
            segue.destination.presentationController?.delegate = self;
        }
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        populateArrays()
    }
    
    @IBAction func refreshButton(_ sender: Any) {
        populateArrays()
    }
    
    func populateArrays() {
        ordersToDeliver = [[String: Any]](); ordersBeingDelivered = [[String: Any]]()
        database.collection("order")
            .whereField("restaurant_code", isEqualTo: Load.empRestaurantCode)
            .getDocuments() { (querySnapshot, err) in
            if let err = err { print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents { let data = document.data()
                    if data["status"] as! String == "Preparing to Deliver" { self.ordersToDeliver.append(data) }
                    else if data["status"] as! String == "Out for Delivery" { self.ordersBeingDelivered.append(data) }
                }
            }
            self.sortOrderArrays()
            self.table.reloadData()
        }
    }
    
    func sortOrderArrays() {
        self.ordersToDeliver.sort {
            item1, item2 in
            let date1 = item1["day_of_order"] as! String
            let date2 = item2["day_of_order"] as! String
            let time1 = item1["time_of_order"] as! String
            let time2 = item2["time_of_order"] as! String
            if date1 == date2 { return time1 > time2 } else { return date1 > date2 }
        }
        self.ordersBeingDelivered.sort {
            item1, item2 in
            let date1 = item1["day_of_order"] as! String
            let date2 = item2["day_of_order"] as! String
            let time1 = item1["time_of_order"] as! String
            let time2 = item2["time_of_order"] as! String
            if date1 == date2 { return time1 > time2 } else { return date1 > date2 }
        }
    }
    
    // Populates the cells with data
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DriverOrderCell
        if indexPath.section == 0 {
            cell.orderedBy.text = "\(ordersToDeliver[indexPath.row]["ordered_by"]!)"
            cell.dateTimePlaced.text = "Placed \(ordersToDeliver[indexPath.row]["day_of_order"]!) at \(ordersToDeliver[indexPath.row]["time_of_order"]!)"
            cell.orderID.text = "Order Number: \(ordersToDeliver[indexPath.row]["order_id"]!)"
            cell.distance.text = "" // Add the distance in miles here later
        } else if indexPath.section == 1 {
            cell.orderedBy.text = "\(ordersBeingDelivered[indexPath.row]["ordered_by"]!)"
            cell.dateTimePlaced.text = "Placed \(ordersBeingDelivered[indexPath.row]["day_of_order"]!) at \(ordersBeingDelivered[indexPath.row]["time_of_order"]!)"
            cell.orderID.text = "Order Number: \(ordersBeingDelivered[indexPath.row]["order_id"]!)"
            cell.distance.text = "" // Add the distance in miles here later
        }
        return(cell)
    }
    
    // Sets the height of the cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return(91)
    }
    
    // Sets the section titles
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle = String()
        if section == 0 { sectionTitle = "Ready to Deliver" } else if section == 1 { sectionTitle = "Out for Delivery" }
        return sectionTitle
    }
    
    // Sets the number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 2; if ordersBeingDelivered.isEmpty { numberOfSections = 1 }
        return(numberOfSections)
    }
    
    // Sets the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return ordersToDeliver.count
        } else if section == 1 {
            return ordersBeingDelivered.count
        }
        return (0)
    }
    
    // Ran when you tap a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Section Tapped: \(indexPath.section)")
        table.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            DriverOrderDetails.orderData = self.ordersToDeliver[indexPath.row]
            self.performSegue(withIdentifier: "showOrderDetails", sender: self)
        } else if indexPath.section == 1 {
            DriverOrderDetails.orderData = self.ordersBeingDelivered[indexPath.row]
            self.performSegue(withIdentifier: "showOrderDetails", sender: self)
        }
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

class DriverOrderCell: UITableViewCell {
    @IBOutlet weak var dateTimePlaced: UILabel!
    @IBOutlet weak var orderID: UILabel!
    @IBOutlet weak var orderedBy: UILabel!
    @IBOutlet weak var distance: UILabel!
}
