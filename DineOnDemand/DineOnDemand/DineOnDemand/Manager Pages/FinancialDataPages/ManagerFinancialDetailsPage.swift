//
//  ManagerFinancialDetailsPage.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/15/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ManagerFinancialDetailsPage: UIViewController, UITableViewDelegate, UITableViewDataSource {
    //database connection
    private let database = Firestore.firestore()
    
    @IBOutlet weak var FinancialPageYearTableView: UITableView!
    static var yearSelected = ""
    var FinancialDataYears = ["2021", "2022", "2023"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    //Table view methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {return self.FinancialDataYears.count}
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = self.FinancialDataYears[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Year Selected: \(FinancialDataYears[indexPath.row])")
        ManagerFinancialDetailsPage.yearSelected = FinancialDataYears[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "ManagerFinancialMonthSegue", sender: self)
    }
    // Set height for the cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {return(105)}
}

