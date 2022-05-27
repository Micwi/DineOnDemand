//
//  ManagerAccountRequestsPage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 3/24/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class ManagerAccountRequestsPage: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let database = Firestore.firestore()
    @IBOutlet weak var table: UITableView!
    var accountCreationRequests = [[String: Any]](); var activatedAccounts = [[String: Any]]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        populateArrays()
    }
    
    @IBAction func refreshButton(_ sender: Any) {
        populateArrays()
    }
    
    func populateArrays() {
        accountCreationRequests = [[String: Any]](); activatedAccounts = [[String: Any]]()
        database.collection("account")
            .whereField("restaurant_code", isEqualTo: Load.empRestaurantCode)
            .getDocuments() { (querySnapshot, err) in
            if let err = err { print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents { let data = document.data()
                    if data["account_status"] as! String == "Not Activated" && data["account_type"] as! String != "Manager" {
                        self.accountCreationRequests.append(data)
                    } else if data["account_status"] as! String == "Activated" && data["account_type"] as! String != "Customer" && data["account_type"] as! String != "Manager" {
                        self.activatedAccounts.append(data)
                    }
                }
            }
            self.table.reloadData()
        }
    }
    
    // Populates the cells with data
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! accountCreationRequest
        if indexPath.section == 0 {
            cell.fullNameLabel.text = "\(accountCreationRequests[indexPath.row]["full_name"]!)"
            cell.emailAddressLabel.text = "\(accountCreationRequests[indexPath.row]["email_address"]!)"
            cell.typeLabel.text = ""
        } else if indexPath.section == 1 {
            cell.fullNameLabel.text = "\(activatedAccounts[indexPath.row]["full_name"]!)"
            cell.emailAddressLabel.text = "\(activatedAccounts[indexPath.row]["email_address"]!)"
            cell.typeLabel.text = "\(activatedAccounts[indexPath.row]["account_type"]!)"
        }
        return(cell)
    }
    
    // Sets the height of the cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return(92)
    }
    
    // Sets the section titles
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle = String()
        if section == 0 { sectionTitle = "Account Creation Requests" } else if section == 1 { sectionTitle = "Activated Accounts" }
        return sectionTitle
    }
    
    // Sets the number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 2; if activatedAccounts.isEmpty { numberOfSections = 1 }
        return(numberOfSections)
    }
    
    // Sets the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return accountCreationRequests.count
        } else if section == 1 {
            return activatedAccounts.count
        }
        return 0
    }
    
    // Ran when you tap a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Section Tapped: \(indexPath.section)")
        table.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            setRoleAlert(accountID: accountCreationRequests[indexPath.row]["account_id"] as! String)
        } else if indexPath.section == 1 {
            setRoleAlert(accountID: activatedAccounts[indexPath.row]["account_id"] as! String)
        }
    }
    
    func setRoleAlert(accountID: String) {
        let alertController = UIAlertController(title: "Set Role", message: "Reject this account or assign a role to it from the following options: Employee, Driver, Cook. Roles are case sensitive.", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in textField.placeholder = "Enter Role Here" }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in}
        let rejectAction = UIAlertAction(title: "Reject Account", style: .destructive) { _ in
            self.rejectAccount(accountID: accountID)
        }
        let confirmAction = UIAlertAction(title: "Assign Role", style: .default) { _ in
            let enteredRole = alertController.textFields![0].text
            if enteredRole == "Employee" || enteredRole == "Driver" || enteredRole == "Cook" {
                self.assignRole(accountID: accountID, accountRole: alertController.textFields![0].text!)
                self.populateArrays()
            } else {
                self.invalidRoleAlert(accountID: accountID)
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        alertController.addAction(rejectAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func invalidRoleAlert(accountID: String) {
        let alertController = UIAlertController(title: "Invalid Role", message: "The role you entered is invalid. Please select from the following options: Employee, Driver, Cook.", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default) { _ in
            self.setRoleAlert(accountID: accountID)
        }
        alertController.addAction(okayAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func assignRole(accountID: String, accountRole: String) {
        self.database.collection("account").document("account_\(accountID)").setData([
            "account_status": "Activated",
            "account_type": accountRole
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    func rejectAccount(accountID: String) {
        self.database.collection("account").document("account_\(accountID)").delete() { err in
            if let err = err { print("Error deleting document: \(err)")
            } else { print("Document successfully deleted!"); self.populateArrays() }
        }
    }
    
}

class accountCreationRequest: UITableViewCell {
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var emailAddressLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
}
