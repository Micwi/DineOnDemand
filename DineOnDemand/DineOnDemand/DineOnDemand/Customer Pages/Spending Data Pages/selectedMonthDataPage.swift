//
//  selectedMonthDataPage.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/7/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class selectedMonthDataPage: UIViewController, UITableViewDelegate, UITableViewDataSource {
    //database connection
    private let database = Firestore.firestore()
    
    var dateOfOrder = " "
    var totalSpentThisMonth = 0.0
    static var budgetPrice = 0.0
    static var weeks = [SpendData]()
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = SpendingDataPage.monthSelected
        grabBudget(); setupTableView()
    }
    @IBOutlet weak var totalSpentLabel: UILabel!
    let monthDataTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    func grabMonthData() {
        selectedMonthDataPage.weeks = [SpendData]()
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = self.database.collection("account").document("account_\(userID)").collection("budget_data").document("\(PopUpWindowYearPage.yearSelected)").collection("monthlyData").document(SpendingDataPage.backendMonthSelected)
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {return}
            
            //minus 1 for total_this_month field in DB
            let fieldCount = data.count - 1
            print("field count: \(fieldCount)")
            if(fieldCount >= 1){
                for x in 1...fieldCount{
                    let weekDataDictionary = data["week_\(x)"] as! [String: Any]
                    let amountSpent = weekDataDictionary["amountSpent"] ?? "No price found!"
                    selectedMonthDataPage.weeks.append(SpendData(week: weekDataDictionary["dayRange"] as! String, amount: amountSpent as! Double))
                    self.monthDataTableView.reloadData()
                }
                self.totalSpentThisMonth = data["total_spent_this_month"] as! Double
                let formattedTotalSpentThisMonth = String(format: "%.2f", self.totalSpentThisMonth)
                self.totalSpentLabel.text = "Total Spent This Month: $\(formattedTotalSpentThisMonth)"
            }else{ print("No Data Found for this month!")
                self.totalSpentLabel.text = "No Data Found for this month!"
            }
            self.calculateTotalSpentDuringMonth()
        }
    }
    func grabBudget() {
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = self.database.collection("account").document("account_\(userID)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {return}
            let budget = data["budget"] ?? 0
            selectedMonthDataPage.budgetPrice = budget as! Double
        }
    }
    //adds all weekly prices for a total amount for each month
    func calculateTotalSpentDuringMonth(){
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = self.database.collection("account").document("account_\(userID)").collection("budget_data").document("\(PopUpWindowYearPage.yearSelected)").collection("monthlyData").document(SpendingDataPage.backendMonthSelected)
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {return}
            let fieldCount = data.count - 1
            if(fieldCount >= 1){
                var field = 0.0
                for x in 1...fieldCount{
                    let weekDataDictionary = data["week_\(x)"] as! [String: Any]
                    let amountSpent = weekDataDictionary["amountSpent"] ?? "No Price found!"
                    field = field + (amountSpent as! Double)
                }
                self.totalSpentThisMonth = field
                let formattedTotalSpentThisMonth = String(format: "%.2f", field)
                self.totalSpentLabel.text = "Total Spent This Month: $\(formattedTotalSpentThisMonth)"
                self.updateTotalSpentThisMonth()
            }else{ print("No Data Found for this month!")
                self.totalSpentThisMonth = 0
                self.totalSpentLabel.text = "Total Spent This Month: $\(self.totalSpentThisMonth)"
                self.updateTotalSpentThisMonth()
            }
        }
    }
    func updateTotalSpentThisMonth(){
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = self.database.collection("account").document("account_\(userID)").collection("budget_data").document("\(PopUpWindowYearPage.yearSelected)").collection("monthlyData").document(SpendingDataPage.backendMonthSelected).setData([
            "total_spent_this_month": self.totalSpentThisMonth
        ], merge: true)
    }
    //setting up table view
    func setupTableView() {
        view.addSubview(monthDataTableView)
        monthDataTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        monthDataTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        monthDataTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        monthDataTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -175).isActive = true
        monthDataTableView.register(customSpendingDataCell.self, forCellReuseIdentifier: "cell")
        monthDataTableView.delegate = self
        monthDataTableView.dataSource = self
        print("here")
        grabMonthData()
     }
    
     var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         if selectedIndex == indexPath { return 200 }
         return 75
     }
     //table view methods
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return selectedMonthDataPage.weeks.count
     }
 
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = monthDataTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! customSpendingDataCell
         cell.data = selectedMonthDataPage.weeks[indexPath.row]
         cell.selectionStyle = .none
         cell.animate()
         return cell
     }
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         print("Week selected: \(selectedMonthDataPage.weeks[indexPath.row].week)")
         //tableView.deselectRow(at: indexPath, animated: true)
         selectedIndex = indexPath
         monthDataTableView.beginUpdates()
         monthDataTableView.reloadRows(at: [selectedIndex], with: .none)
         monthDataTableView.endUpdates()
     }
}
//for weekly spending data in each month 
struct SpendData {
    var week: String
    var amount: Double
}
class customSpendingDataCell: UITableViewCell {
    var data: SpendData? {
        didSet{
            guard let data = data else { return }
            //when the look at their data, it checks if the amount they spent is more than the budget they set for that week. If it does, it changes the
            //title of the cell to disguish between that cell from the rest
            if(data.amount > selectedMonthDataPage.budgetPrice){self.title.text = "(!!) \(data.week) (!!)"}
            else{self.title.text = data.week}
            self.totalAmountSpent.text = "Total amount spent: $\(data.amount)\n"
            self.budgetLabel.text = "Budget: $\(selectedMonthDataPage.budgetPrice)"
        }
    }
    func animate(){
        UIView.animate(withDuration: 0.5, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
            self.contentView.layoutIfNeeded()
        })
    }
    let title: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.text = "label text"
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let totalAmountSpent: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.text = "description text"
        label.textColor = .black
        label.numberOfLines = -1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let budgetLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.text = "budget"
        label.textColor = .black
        label.numberOfLines = -1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    let container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.backgroundColor = UIColor.systemYellow //change this color of cell background if ugly
        view.layer.cornerRadius = 10
        return view
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(container)
        
        container.topAnchor.constraint(equalTo: contentView.topAnchor , constant: 4).isActive = true
        container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4).isActive = true
        container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4).isActive = true
        container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4).isActive = true
        
        container.addSubview(title)
        container.addSubview(totalAmountSpent)
        container.addSubview(budgetLabel)
        
        title.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        title.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4).isActive = true
        title.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4).isActive = true
        title.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        totalAmountSpent.topAnchor.constraint(equalTo: title.bottomAnchor).isActive = true
        totalAmountSpent.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20).isActive = true
        totalAmountSpent.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4).isActive = true
        totalAmountSpent.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        budgetLabel.topAnchor.constraint(equalTo: title.bottomAnchor).isActive = true
        budgetLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20).isActive = true
        budgetLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4).isActive = true
        budgetLabel.heightAnchor.constraint(equalToConstant: 170).isActive = true
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



