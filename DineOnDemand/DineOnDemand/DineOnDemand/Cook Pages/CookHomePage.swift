//
//  CookHomePage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 3/24/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class CookHomePage: UIViewController, UIAdaptivePresentationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    private let database = Firestore.firestore()
    @IBOutlet weak var table: UITableView!
    var ordersReadyToCook = [[String: Any]](); var ordersCurrentlyCooking = [[String: Any]]()
    
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
        ordersReadyToCook = [[String: Any]](); ordersCurrentlyCooking = [[String: Any]]()
        database.collection("order")
            .whereField("restaurant_code", isEqualTo: Load.empRestaurantCode)
            .getDocuments() { (querySnapshot, err) in
            if let err = err { print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents { let data = document.data()
                    if data["status"] as! String == "Preparing to Cook" { self.ordersReadyToCook.append(data) }
                    else if data["status"] as! String == "Cooking" { self.ordersCurrentlyCooking.append(data) }
                }
            }
            self.sortOrderArrays()
            self.table.reloadData()
        }
    }
    
    func sortOrderArrays() {
        self.ordersReadyToCook.sort {
            item1, item2 in
            let date1 = item1["day_of_order"] as! String
            let date2 = item2["day_of_order"] as! String
            let time1 = item1["time_of_order"] as! String
            let time2 = item2["time_of_order"] as! String
            if date1 == date2 { return time1 > time2 } else { return date1 > date2 }
        }
        self.ordersCurrentlyCooking.sort {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CookOrderCell
        if indexPath.section == 0 { // Use data from 'ordersReadyToCook' array
            cell.itemCount.text = "Number of Items: \((ordersReadyToCook[indexPath.row]["foods_in_order"] as! [String]).count)"
            cell.dateTimePlaced.text = "Placed \(ordersReadyToCook[indexPath.row]["day_of_order"]!) at \(ordersReadyToCook[indexPath.row]["time_of_order"]!)"
            cell.orderID.text = "Order Number: \(ordersReadyToCook[indexPath.row]["order_id"]!)"
        } else if indexPath.section == 1 { // Use data from 'orderCurrentlyCooking' array
            cell.itemCount.text = "Number of Items: \((ordersCurrentlyCooking[indexPath.row]["foods_in_order"] as! [String]).count)"
            cell.dateTimePlaced.text = "Placed \(ordersCurrentlyCooking[indexPath.row]["day_of_order"]!) at \(ordersCurrentlyCooking[indexPath.row]["time_of_order"]!)"
            cell.orderID.text = "Order Number: \(ordersCurrentlyCooking[indexPath.row]["order_id"]!)"
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
        if section == 0 { sectionTitle = "Ready to Cook" } else if section == 1 { sectionTitle = "Currently Cooking" }
        return sectionTitle
    }
    
    // Sets the number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 2; if ordersCurrentlyCooking.isEmpty { numberOfSections = 1 }
        return(numberOfSections)
    }
    
    // Sets the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return ordersReadyToCook.count
        } else if section == 1 {
            return ordersCurrentlyCooking.count
        }
        return(0)
    }
    
    // Ran when you tap a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Section Tapped: \(indexPath.section)")
        table.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            // Order That Is Ready to Cook
            CookOrderDetails.orderData = self.ordersReadyToCook[indexPath.row]
            self.performSegue(withIdentifier: "showOrderDetails", sender: self)
        } else if indexPath.section == 1 {
            // Order Currently Cooking
            CookOrderDetails.orderData = self.ordersCurrentlyCooking[indexPath.row]
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

class CookOrderCell: UITableViewCell {
    @IBOutlet weak var dateTimePlaced: UILabel!
    @IBOutlet weak var itemCount: UILabel!
    @IBOutlet weak var orderID: UILabel!
}
