//
//  PopUpWindowYearPage.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/7/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class PopUpWindowYearPage: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    //database connection
    private let database = Firestore.firestore()
    
    static var yearSelected = " "
    @IBOutlet weak var window: UIView!
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    var pickerData: [String] = [String]()
    
    func grabData(){
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        let docRef = self.database.collection("account").document("account_\(userID)").collection("budget_data").addSnapshotListener { [self]
            (QuerySnapshot, err) in
            if let err = err{
                //error occurred when trying to grab the data from firestore
                print("Error occurred when grabbing documents from database.")
                print("Error is: \(err)")
            }
            else{
                for doc in QuerySnapshot!.documents {
                    let id = doc.documentID
                    self.pickerData.append(id)
                }
                self.pickerView.reloadAllComponents()
            }
            print("Data grabbed from Database for Picker: \(pickerData)")
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        window.layer.cornerRadius = 10
        grabData()
        self.pickerView.delegate = self
        self.pickerView.dataSource = self

    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        PopUpWindowYearPage.yearSelected = pickerData[row]
        print("Year Selected: \(PopUpWindowYearPage.yearSelected)")
    }
    func switchViewController(identifier: String) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: identifier)
        self.present(newViewController, animated: true, completion: nil)
    }
}
