//
//  SpendingDataPage.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/7/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class SpendingDataPage: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    //database connection
    private let database = Firestore.firestore()
    
    //array for document titles (months for spending data) from db
    var monthsOfSpendingData = [String] ()
    static var monthSelected = " "
    static var backendMonthSelected = ""
    let spendingDataTableView:UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    //grabs document titles from database
    func grabMonths(){
        monthsOfSpendingData = [String] ()
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = self.database.collection("account").document("account_\(userID)").collection("budget_data").document("\(PopUpWindowYearPage.yearSelected)").collection("monthlyData").addSnapshotListener { [self]
            (QuerySnapshot, err) in
            if let err = err{
                //error occurred when trying to grab the data from firestore
                print("Error occurred when grabbing documents from database.")
                print("Error is: \(err)")
            } else {
                for doc in QuerySnapshot!.documents {
                    let id = doc.documentID
                    self.monthsOfSpendingData.append(id)
                }
                spendingDataTableView.reloadData()
            }
            print("Months grabbed from Database: \(monthsOfSpendingData)")
        }
    }
    //setting up table view
    func setupTableView(){
        view.addSubview(spendingDataTableView)
        spendingDataTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        spendingDataTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        spendingDataTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        spendingDataTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        
        spendingDataTableView.register(UITableViewCell.self, forCellReuseIdentifier: "spendingDataCell")
        spendingDataTableView.delegate = self
        spendingDataTableView.dataSource = self
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = PopUpWindowYearPage.yearSelected
        monthsOfSpendingData = [String] ()
        setupTableView()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        print("View Appeared")
        grabMonths()
    }
    
    func getMonthName(rowName: String) -> String {
        var monthName = ""
        switch(rowName.dropLast(4)) {
        case "01_":
            monthName = "January"
            break;
        case "02_":
            monthName = "February"
            break;
        case "03_":
            monthName = "March"
            break;
        case "04_":
            monthName = "April"
            break;
        case "05_":
            monthName = "May"
            break;
        case "06_":
            monthName = "June"
            break;
        case "07_":
            monthName = "July"
            break;
        case "08_":
            monthName = "August"
            break;
        case "09_":
            monthName = "September"
            break;
        case "10_":
            monthName = "October"
            break;
        case "11_":
            monthName = "November"
            break;
        case "12_":
            monthName = "December"
            break;
        default:
            monthName = ""
            break;
        }
        return monthName
    }
    
    //table view methods
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {return 75}
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {return monthsOfSpendingData.count}
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = spendingDataTableView.dequeueReusableCell(withIdentifier: "spendingDataCell", for: indexPath)
        let currentMonth = getMonthName(rowName: monthsOfSpendingData[indexPath.row])
        cell.textLabel?.text = currentMonth
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Month Record \(monthsOfSpendingData[indexPath.row]) selected!")
        let currentMonth = getMonthName(rowName: monthsOfSpendingData[indexPath.row])
        SpendingDataPage.monthSelected = currentMonth
        SpendingDataPage.backendMonthSelected = monthsOfSpendingData[indexPath.row]
        self.performSegue(withIdentifier: "monthSelectedSegue", sender: self)
        spendingDataTableView.beginUpdates()
        spendingDataTableView.reloadRows(at: [indexPath], with: .none)
        spendingDataTableView.endUpdates()
    }
}
