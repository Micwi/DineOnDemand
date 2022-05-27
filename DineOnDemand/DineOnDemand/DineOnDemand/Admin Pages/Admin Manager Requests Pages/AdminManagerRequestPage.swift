//
//  AdminManagerRequestPage.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/25/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class AdminManagerRequestPage: UIViewController,  UITableViewDelegate, UITableViewDataSource  {
    
    private let database = Firestore.firestore()
    @IBOutlet weak var tableView: UITableView!
    var newManagerAccountInfo = [ManagerInfo]()
    var currentManagerAccountInfo = [ManagerInfo]()
    var accountNameSelected = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    override func viewDidAppear(_ animated: Bool) {
        grabManagerAccountDetails()
    }
    @IBAction func refreshButtonTapped(_ sender: Any) {
        grabManagerAccountDetails()
    }
    
    func grabManagerAccountDetails() {
        newManagerAccountInfo = [ManagerInfo](); currentManagerAccountInfo = [ManagerInfo]()
        database.collection("account")
            .whereField("account_type", isEqualTo: "Manager")
            .getDocuments() { (querySnapshot, err) in
            if let err = err { print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents { let data = document.data()
                    let nameOnAccount = data["full_name"] as! String
                    let accountID = data["account_id"] as! String
                    let email = data["email_address"] as! String
                    let restaurantCode = data["restaurant_code"] as! String
                    let accountStatus = data["account_status"] as! String
                    if accountStatus == "Not Activated" {
                        self.newManagerAccountInfo.append(ManagerInfo(fullName: nameOnAccount, email: email, accountID: accountID, restaurantCode: restaurantCode))
                    } else if data["account_status"] as! String == "Activated" {
                        self.currentManagerAccountInfo.append(ManagerInfo(fullName: nameOnAccount, email: email, accountID: accountID, restaurantCode: restaurantCode))
                    }
                }
            }
            self.tableView.reloadData()
        }
    }
    
    func activateAccountAlert(accountID: String) {
        let alertController = UIAlertController(title: "Activate Account", message: "Accept or Reject the creation of this manager account.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in}
        let rejectAction = UIAlertAction(title: "Reject Account", style: .destructive) { _ in
            self.rejectAccount(accountID: accountID)
        }
        let confirmAction = UIAlertAction(title: "Accept Account", style: .default) { _ in
            self.UpdateAccountInDB(accountID: accountID, accountRole: "Manager")
            self.grabManagerAccountDetails()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        alertController.addAction(rejectAction)
        present(alertController, animated: true, completion: nil)
    }
func UpdateAccountInDB(accountID: String, accountRole: String) {
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
            } else { print("Document successfully deleted!"); self.grabManagerAccountDetails() }
        }
    }
    // Sets the section titles
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle = String()
        if section == 0 { sectionTitle = "New Manager Account Creation Requests" } else if section == 1 { sectionTitle = "Current Manager Accounts" }
        return sectionTitle
    }
    // Sets the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return newManagerAccountInfo.count
        } else if section == 1 {
            return currentManagerAccountInfo.count
        }
        return 0
    }
    // Ran when you tap a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Section Tapped: \(indexPath.section)")
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            activateAccountAlert(accountID: newManagerAccountInfo[indexPath.row].accountID)
            accountNameSelected = newManagerAccountInfo[indexPath.row].fullName
        } else if indexPath.section == 1 {
            print("Manager Account already Activated!")
        }
    }
    // Sets the number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 2; if currentManagerAccountInfo.isEmpty { numberOfSections = 1 }
        return(numberOfSections)
    }
    // Sets the height of the cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return(140)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NewManagerCustomCell
        if(indexPath.section == 0){
            cell.fullNameLabel.text = ("Full Name:  \(newManagerAccountInfo[indexPath.row].fullName)")
            cell.accountIDLabel.text = ("Account ID:    \(newManagerAccountInfo[indexPath.row].accountID)")
            cell.emailLabel.text = ("Email:     \(newManagerAccountInfo[indexPath.row].email)")
            cell.restaurantCodeLabel.text = ("Restaurant Code:      \(newManagerAccountInfo[indexPath.row].restaurantCode)")
        } else if (indexPath.section == 1){
            cell.fullNameLabel.text = ("Full Name:  \(currentManagerAccountInfo[indexPath.row].fullName)")
            cell.accountIDLabel.text = ("Account ID:    \(currentManagerAccountInfo[indexPath.row].accountID)")
            cell.emailLabel.text = ("Email:     \(currentManagerAccountInfo[indexPath.row].email)")
            cell.restaurantCodeLabel.text = ("Restaurant Code:      \(currentManagerAccountInfo[indexPath.row].restaurantCode)")
        }
        
        return cell
    }
    
    
}
struct ManagerInfo{
    var fullName: String
    var email: String
    var accountID: String
    var restaurantCode: String
}
class NewManagerCustomCell: UITableViewCell{
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var accountIDLabel: UILabel!
    @IBOutlet weak var restaurantCodeLabel: UILabel!
    
}
