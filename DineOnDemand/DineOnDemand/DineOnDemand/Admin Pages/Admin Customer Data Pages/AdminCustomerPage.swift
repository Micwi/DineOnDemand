//
//  AdminCustomerPage.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/23/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class AdminCustomerPage: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var totalNumberOfAccountsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    //UPDATED
    var adminAccountsList = [CustomerInfoForCell]()
    var customerAccountList = [CustomerInfoForCell]()
    var managerAccountList = [CustomerInfoForCell]()
    var cookAccountList = [CustomerInfoForCell]()
    var driverAccountList = [CustomerInfoForCell]()
    var employeeAccountList = [CustomerInfoForCell]()
    var notActivatedAccountsList = [CustomerInfoForCell]()
    var totalNumberOfAccounts = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        grabAccountInfo()
        tableView.delegate = self
        tableView.dataSource = self
    }
    //UPDATED
    // Sets the section titles
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle = String()
        if section == 0 { sectionTitle = "Customer Accounts" }
        else if section == 1 { sectionTitle = "Employee Accounts" }
        else if section == 2 { sectionTitle = "Cook Accounts" }
        else if section == 3 { sectionTitle = "Driver Accounts" }
        else if section == 4 { sectionTitle = "Manager Accounts" }
        else if section == 5 { sectionTitle = "Admin Accounts" }
        else if section == 6 { sectionTitle = "Not Activated Accounts" }
        return sectionTitle
    }
    func grabAccountInfo(){
        adminAccountsList = [CustomerInfoForCell](); customerAccountList = [CustomerInfoForCell]();managerAccountList = [CustomerInfoForCell]()
        cookAccountList = [CustomerInfoForCell]();driverAccountList = [CustomerInfoForCell]();employeeAccountList = [CustomerInfoForCell]()
        notActivatedAccountsList = [CustomerInfoForCell]();totalNumberOfAccounts = 0
        let docRef = self.database.collection("account").addSnapshotListener{[self]
            (QuerySnapshot, err) in
            if let err = err{
                //error occurred when trying to grab the data from firestore
                print("Error occurred when grabbing documents from database.")
                print("Error is: \(err)")
            }
            else{
                for doc in QuerySnapshot!.documents {
                    let accountType = doc["account_type"] as! String
                    let accountStatus = doc["account_status"] as! String
                    //UPDATED
                    if(accountType == "Customer" && accountStatus == "Activated"){
                        let nameOnAccount = doc["full_name"] as! String
                        let accountID = doc["account_id"] as! String
                        let email = doc["email_address"] as! String
                        self.customerAccountList.append(CustomerInfoForCell(nameOnAccount: nameOnAccount, emailOnAccount: email, accountType: accountType, accountID: accountID, restaurantCode: ""))
                    }else if (accountType == "Admin" && accountStatus == "Activated"){
                        let nameOnAccount = doc["full_name"] as! String
                        let accountID = doc["account_id"] as! String
                        let email = doc["email_address"] as! String
                        self.adminAccountsList.append(CustomerInfoForCell(nameOnAccount: nameOnAccount, emailOnAccount: email, accountType: accountType, accountID: accountID, restaurantCode: ""))
                    }
                    else if (accountType == "Manager" && accountStatus == "Activated"){
                        let nameOnAccount = doc["full_name"] as! String
                        let accountID = doc["account_id"] as! String
                        let email = doc["email_address"] as! String
                        let code = doc["restaurant_code"] as! String
                        self.managerAccountList.append(CustomerInfoForCell(nameOnAccount: nameOnAccount, emailOnAccount: email, accountType: accountType, accountID: accountID, restaurantCode: code))
                    }
                    else if (accountType == "Cook" && accountStatus == "Activated"){
                        let nameOnAccount = doc["full_name"] as! String
                        let accountID = doc["account_id"] as! String
                        let email = doc["email_address"] as! String
                        let code = doc["restaurant_code"] as! String
                        self.cookAccountList.append(CustomerInfoForCell(nameOnAccount: nameOnAccount, emailOnAccount: email, accountType: accountType, accountID: accountID, restaurantCode: code))
                    }
                    else if (accountType == "Driver" && accountStatus == "Activated"){
                        let nameOnAccount = doc["full_name"] as! String
                        let accountID = doc["account_id"] as! String
                        let email = doc["email_address"] as! String
                        let code = doc["restaurant_code"] as! String
                        self.driverAccountList.append(CustomerInfoForCell(nameOnAccount: nameOnAccount, emailOnAccount: email, accountType: accountType, accountID: accountID, restaurantCode: code))
                    }
                    else if (accountType == "Employee" && accountStatus == "Activated"){
                        let nameOnAccount = doc["full_name"] as! String
                        let accountID = doc["account_id"] as! String
                        let email = doc["email_address"] as! String
                        let code = doc["restaurant_code"] as! String
                        self.employeeAccountList.append(CustomerInfoForCell(nameOnAccount: nameOnAccount, emailOnAccount: email, accountType: accountType, accountID: accountID, restaurantCode: code))
                    }else{
                        let nameOnAccount = doc["full_name"] as! String
                        let accountID = doc["account_id"] as! String
                        let email = doc["email_address"] as! String
                        self.notActivatedAccountsList.append(CustomerInfoForCell(nameOnAccount: nameOnAccount, emailOnAccount: email, accountType: accountType, accountID: accountID, restaurantCode: ""))
                    }
                }
                tableView.reloadData()
                
                database.collection("account").getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        self.totalNumberOfAccounts = querySnapshot!.documents.count
                        self.totalNumberOfAccountsLabel.text = "Total Number of Accounts: \(self.totalNumberOfAccounts)"
                    }
                }
                
            }
        }
    }
    
    //UPDATED
    //Table View Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {return customerAccountList.count}
        else if section == 1 {return employeeAccountList.count}
        else if section == 2 {return cookAccountList.count}
        else if section == 3 {return driverAccountList.count}
        else if section == 4 {return managerAccountList.count}
        else if section == 5 {return adminAccountsList.count}
        else if section == 6 {return notActivatedAccountsList.count}
        return 0
    }
    //UPDATED
    // Sets the number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        let numberOfSections = 7
        return(numberOfSections)
    }
    //UPDATED
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomizedCustomerCell
        if(indexPath.section == 0){
            cell.nameOnAccountLabel.text = ("Name on Account:   \(self.customerAccountList[indexPath.row].nameOnAccount)")
            cell.accountIDLabel.text = ("Account ID:    \(self.customerAccountList[indexPath.row].accountID)")
            cell.accountEmailAddressLabel.text = ("Email:   \(self.customerAccountList[indexPath.row].emailOnAccount)")
            cell.accountTypeLabel.text = ("Account Type:    \(self.customerAccountList[indexPath.row].accountType)")
            cell.restaurantCodeLabel.isHidden = true
        }else if(indexPath.section == 1){
            cell.nameOnAccountLabel.text = ("Name on Account:   \(self.employeeAccountList[indexPath.row].nameOnAccount)")
            cell.accountIDLabel.text = ("Account ID:    \(self.employeeAccountList[indexPath.row].accountID)")
            cell.accountEmailAddressLabel.text = ("Email:   \(self.employeeAccountList[indexPath.row].emailOnAccount)")
            cell.accountTypeLabel.text = ("Account Type:    \(self.employeeAccountList[indexPath.row].accountType)")
            cell.restaurantCodeLabel.isHidden = false
            cell.restaurantCodeLabel.text = ("Restaurant Code: \(self.employeeAccountList[indexPath.row].restaurantCode)")
        }else if(indexPath.section == 2){
            cell.nameOnAccountLabel.text = ("Name on Account:   \(self.cookAccountList[indexPath.row].nameOnAccount)")
            cell.accountIDLabel.text = ("Account ID:    \(self.cookAccountList[indexPath.row].accountID)")
            cell.accountEmailAddressLabel.text = ("Email:   \(self.cookAccountList[indexPath.row].emailOnAccount)")
            cell.accountTypeLabel.text = ("Account Type:    \(self.cookAccountList[indexPath.row].accountType)")
            cell.restaurantCodeLabel.isHidden = false
            cell.restaurantCodeLabel.text = ("Restaurant Code: \(self.cookAccountList[indexPath.row].restaurantCode)")
        }else if(indexPath.section == 3){
            cell.nameOnAccountLabel.text = ("Name on Account:   \(self.driverAccountList[indexPath.row].nameOnAccount)")
            cell.accountIDLabel.text = ("Account ID:    \(self.driverAccountList[indexPath.row].accountID)")
            cell.accountEmailAddressLabel.text = ("Email:   \(self.driverAccountList[indexPath.row].emailOnAccount)")
            cell.accountTypeLabel.text = ("Account Type:    \(self.driverAccountList[indexPath.row].accountType)")
            cell.restaurantCodeLabel.isHidden = false
            cell.restaurantCodeLabel.text = ("Restaurant Code: \(self.driverAccountList[indexPath.row].restaurantCode)")
        }else if(indexPath.section == 4){
            cell.nameOnAccountLabel.text = ("Name on Account:   \(self.managerAccountList[indexPath.row].nameOnAccount)")
            cell.accountIDLabel.text = ("Account ID:    \(self.managerAccountList[indexPath.row].accountID)")
            cell.accountEmailAddressLabel.text = ("Email:   \(self.managerAccountList[indexPath.row].emailOnAccount)")
            cell.accountTypeLabel.text = ("Account Type:    \(self.managerAccountList[indexPath.row].accountType)")
            cell.restaurantCodeLabel.isHidden = false
            cell.restaurantCodeLabel.text = ("Restaurant Code: \(self.managerAccountList[indexPath.row].restaurantCode)")
        }else if(indexPath.section == 5){
            cell.nameOnAccountLabel.text = ("Name on Account:   \(self.adminAccountsList[indexPath.row].nameOnAccount)")
            cell.accountIDLabel.text = ("Account ID:    \(self.adminAccountsList[indexPath.row].accountID)")
            cell.accountEmailAddressLabel.text = ("Email:   \(self.adminAccountsList[indexPath.row].emailOnAccount)")
            cell.accountTypeLabel.text = ("Account Type:    \(self.adminAccountsList[indexPath.row].accountType)")
            cell.restaurantCodeLabel.text = ""
        }else if(indexPath.section == 6){
            cell.nameOnAccountLabel.text = ("Name on Account:   \(self.notActivatedAccountsList[indexPath.row].nameOnAccount)")
            cell.accountIDLabel.text = ("Account ID:    \(self.notActivatedAccountsList[indexPath.row].accountID)")
            cell.accountEmailAddressLabel.text = ("Email:   \(self.notActivatedAccountsList[indexPath.row].emailOnAccount)")
            cell.accountTypeLabel.text = ("Account Type:    \(self.notActivatedAccountsList[indexPath.row].accountType)")
            cell.restaurantCodeLabel.text = ""
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
struct CustomerInfoForCell{
    var nameOnAccount: String
    var emailOnAccount: String
    var accountType: String
    var accountID: String
    var restaurantCode: String
    
}
class CustomizedCustomerCell: UITableViewCell{
    @IBOutlet weak var accountIDLabel: UILabel!
    @IBOutlet weak var accountTypeLabel: UILabel!
    @IBOutlet weak var accountEmailAddressLabel: UILabel!
    @IBOutlet weak var nameOnAccountLabel: UILabel!
    @IBOutlet weak var restaurantCodeLabel: UILabel!
}
