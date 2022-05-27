//
//  ManagersFinancialDetailsPage2.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/15/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ManagersFinancialDetailsPage2: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //database connection
    private let database = Firestore.firestore()
    
    var months = [String]()
    var monthlyTotalPrice = 0.0
    //values to help with grabbing correct orders from database
    var ordersIDsFromRestaurant = [String] ()
    static var orderInfoFromRestaurant = [cellData]()
    @IBOutlet weak var monthFinancialTableView: UITableView!
    
    //For calculateTotals method
    var totalPriceJanuary = 0.0;var totalPriceFebruary = 0.0;var totalPriceMarch = 0.0;var totalPriceApril = 0.0
    var totalPriceMay = 0.0;var totalPriceJune = 0.0; var totalPriceJuly = 0.0; var totalPriceAugust = 0.0
    var totalPriceSeptember = 0.0;var totalPriceOctober = 0.0;var totalPriceNovember = 0.0;var totalPriceDecember = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //For labels in cells
        months = [
            "January \n01/\(ManagerFinancialDetailsPage.yearSelected)", "February \n02/\(ManagerFinancialDetailsPage.yearSelected)",
            "March \n03/\(ManagerFinancialDetailsPage.yearSelected)", "April \n04/\(ManagerFinancialDetailsPage.yearSelected)",
            "May \n05/\(ManagerFinancialDetailsPage.yearSelected)", "June \n06/\(ManagerFinancialDetailsPage.yearSelected)",
            "July \n07/\(ManagerFinancialDetailsPage.yearSelected)", "August \n08/\(ManagerFinancialDetailsPage.yearSelected)",
            "September \n09/\(ManagerFinancialDetailsPage.yearSelected)", "October \n10/\(ManagerFinancialDetailsPage.yearSelected)",
            "November \n11/\(ManagerFinancialDetailsPage.yearSelected)", "December \n12/\(ManagerFinancialDetailsPage.yearSelected)"]
        navigationItem.title = "\(ManagerFinancialDetailsPage.yearSelected)"
        grabOrderIDInfoFromRestaurant()
    }
    override func viewDidAppear(_ animated: Bool) {
        self.calculateTotalsForEachMonth()
        self.monthFinancialTableView.reloadData()
    }
    func grabOrderIDInfoFromRestaurant(){
        ordersIDsFromRestaurant = [String] ()
        monthlyTotalPrice = 0.0
        database.collection("order")
            .whereField("restaurant_code", isEqualTo: Load.empRestaurantCode)
            .getDocuments() { (querySnapshot, err) in
                if let err = err { print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents { let data = document.data()
                        self.ordersIDsFromRestaurant.append(data["order_id"] as! String)
                    }
                }
                print("Orders Found: \(self.ordersIDsFromRestaurant)")
                self.grabOrderInfo(orderInfo: self.ordersIDsFromRestaurant)
            }
    }
    func grabOrderInfo(orderInfo: [String]){
        ManagersFinancialDetailsPage2.orderInfoFromRestaurant = [cellData]()
        var dateOfOrder = " "
        var priceOfOrder = ""
        for i in 0...orderInfo.count - 1 {
            let docRef = database.collection("order").document("order_\(orderInfo[i])")
            docRef.getDocument { snapshot, error in
                guard let data = snapshot?.data(), error == nil else {return}
                dateOfOrder = data["day_of_order"] as! String
                priceOfOrder = data["order_total"] as! String
                ManagersFinancialDetailsPage2.orderInfoFromRestaurant.append(cellData(orderID: "order_\(orderInfo[i])", date: dateOfOrder, TotalPriceOfOrder: priceOfOrder))
            }
        }
    }
    func calculateTotalsForEachMonth(){
        totalPriceJanuary = 0.0;totalPriceFebruary = 0.0;totalPriceMarch = 0.0;totalPriceApril = 0.0
        totalPriceMay = 0.0;totalPriceJune = 0.0;totalPriceJuly = 0.0;totalPriceAugust = 0.0
        totalPriceSeptember = 0.0;totalPriceOctober = 0.0;totalPriceNovember = 0.0;totalPriceDecember = 0.0
        
        if(ManagerFinancialDetailsPage.yearSelected == "2021"){print("No Data Available for this year: \(ManagerFinancialDetailsPage.yearSelected)")}
        if(ManagerFinancialDetailsPage.yearSelected == "2022"){
            for i in 0...ManagersFinancialDetailsPage2.orderInfoFromRestaurant.count - 1{
                let splitDate = ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].date.split(separator: "/")
                let month = splitDate[0]
                let splitMonth = Array(month)
                //for the months that have a 0 in front -> 1-9
                if(month.contains("0")){
                    if(splitMonth[1].wholeNumberValue == 1){totalPriceJanuary = totalPriceJanuary + Double(ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].TotalPriceOfOrder)!}
                    else if(splitMonth[1].wholeNumberValue == 2){totalPriceFebruary = totalPriceFebruary + Double(ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].TotalPriceOfOrder)!}
                    else if(splitMonth[1].wholeNumberValue == 3){totalPriceMarch = totalPriceMarch + Double(ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].TotalPriceOfOrder)!}
                    else if(splitMonth[1].wholeNumberValue == 4){totalPriceApril = totalPriceApril + Double(ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].TotalPriceOfOrder)!}
                    else if(splitMonth[1].wholeNumberValue == 5){totalPriceMay = totalPriceMay + Double(ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].TotalPriceOfOrder)!}
                    else if(splitMonth[1].wholeNumberValue == 6){totalPriceJune = totalPriceJune + Double(ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].TotalPriceOfOrder)!}
                    else if(splitMonth[1].wholeNumberValue == 7){totalPriceJuly = totalPriceJuly + Double(ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].TotalPriceOfOrder)!}
                    else if(splitMonth[1].wholeNumberValue == 8){totalPriceAugust = totalPriceAugust + Double(ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].TotalPriceOfOrder)!}
                    else if(splitMonth[1].wholeNumberValue == 9){totalPriceSeptember = totalPriceSeptember + Double(ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].TotalPriceOfOrder)!}
                }else{
                    if(Int(month) == 10){totalPriceOctober = totalPriceOctober + Double(ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].TotalPriceOfOrder)!}
                    else if(Int(month) == 11){totalPriceNovember = totalPriceNovember + Double(ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].TotalPriceOfOrder)!}
                    else if(Int(month) == 12){totalPriceDecember = totalPriceDecember + Double(ManagersFinancialDetailsPage2.orderInfoFromRestaurant[i].TotalPriceOfOrder)!}
                }
            }
            //Here if you need to print the price to check
//            print("Total Price in Jan: \(totalPriceJanuary)")
//            print("Total Price in Feb: \(totalPriceFebruary)")
//            print("Total Price in Mar: \(totalPriceMarch)")
//            print("Total Price in Apr: \(totalPriceApril)")
//            print("Total Price in May: \(totalPriceMay)")
//            print("Total Price in June: \(totalPriceJune)")
//            print("Total Price in July: \(totalPriceJuly)")
//            print("Total Price in Aug: \(totalPriceAugust)")
//            print("Total Price in Sept: \(totalPriceSeptember)")
//            print("Total Price in Oct: \(totalPriceOctober)")
//            print("Total Price in Nov: \(totalPriceNovember)")
//            print("Total Price in Dec: \(totalPriceDecember)")
        }
        if(ManagerFinancialDetailsPage.yearSelected == "2023"){print("No Data Available for this year: \(ManagerFinancialDetailsPage.yearSelected)")}
    }
    func roundPrice(price: Double) -> String {
        let roundedPrice = String(format: "%.2f", price)
        return roundedPrice
    }
    //Table view methods
    var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)
    
    var selectedIndexJanuary: IndexPath = IndexPath(row: 0, section: 0)
    var selectedIndexFebruary: IndexPath = IndexPath(row: 1, section: 0)
    var selectedIndexMarch: IndexPath = IndexPath(row: 2, section: 0)
    var selectedIndexApril: IndexPath = IndexPath(row: 3, section: 0)
    var selectedIndexMay: IndexPath = IndexPath(row: 4, section: 0)
    var selectedIndexJune: IndexPath = IndexPath(row: 5, section: 0)
    var selectedIndexJuly: IndexPath = IndexPath(row: 6, section: 0)
    var selectedIndexAugust: IndexPath = IndexPath(row: 7, section: 0)
    var selectedIndexSeptember: IndexPath = IndexPath(row: 8, section: 0)
    var selectedIndexOctober: IndexPath = IndexPath(row: 9, section: 0)
    var selectedIndexNovember: IndexPath = IndexPath(row: 10, section: 0)
    var selectedIndexDecember: IndexPath = IndexPath(row: 11, section: 0)
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {return 93}
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {return months.count}
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! customFinancialDataCell
        cell.monthLabel.text = months[indexPath.row]
        if(selectedIndexJanuary == indexPath){cell.profitAmountLabel.text = "$\(roundPrice(price: totalPriceJanuary))"}
        else if(selectedIndexFebruary == indexPath){cell.profitAmountLabel.text = "$\(roundPrice(price: totalPriceFebruary))"}
        else if(selectedIndexMarch == indexPath){cell.profitAmountLabel.text = "$\(roundPrice(price: totalPriceMarch))"}
        else if(selectedIndexApril == indexPath){cell.profitAmountLabel.text = "$\(roundPrice(price: totalPriceApril))"}
        else if(selectedIndexMay == indexPath){cell.profitAmountLabel.text = "$\(roundPrice(price: totalPriceMay))"}
        else if(selectedIndexJune == indexPath){cell.profitAmountLabel.text = "$\(roundPrice(price: totalPriceJune))"}
        else if(selectedIndexJuly == indexPath){cell.profitAmountLabel.text = "$\(roundPrice(price: totalPriceJuly))"}
        else if(selectedIndexAugust == indexPath){cell.profitAmountLabel.text = "$\(roundPrice(price: totalPriceAugust))"}
        else if(selectedIndexSeptember == indexPath){cell.profitAmountLabel.text = "$\(roundPrice(price: totalPriceSeptember))"}
        else if(selectedIndexOctober == indexPath){cell.profitAmountLabel.text = "$\(roundPrice(price: totalPriceOctober))"}
        else if(selectedIndexNovember == indexPath){cell.profitAmountLabel.text = "$\(roundPrice(price: totalPriceNovember))"}
        else if(selectedIndexDecember == indexPath){cell.profitAmountLabel.text = "$\(roundPrice(price: totalPriceDecember))"}
        else{ print("Error has occurred when populating data in cell")}
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath
        monthFinancialTableView.beginUpdates()
        monthFinancialTableView.reloadRows(at: [selectedIndex], with: .none)
        monthFinancialTableView.endUpdates()
    }
}
struct cellData {
    var orderID: String
    var date: String
    var TotalPriceOfOrder: String
}
class customFinancialDataCell: UITableViewCell{
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var profitAmountLabel: UILabel!
}
