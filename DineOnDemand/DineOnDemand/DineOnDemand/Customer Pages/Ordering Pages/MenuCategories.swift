//
//  RestaurantMenuTableView1.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 3/9/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class MenuCategories: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let database = Firestore.firestore()
    @IBOutlet weak var tableView: UITableView!
    
    var menuCategoryNames = [String]()
    static var selectedMenuCategory = ""
    
    @IBOutlet weak var bagButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lockTabBar()
        grabMenuCategories()
    }
    
    func lockTabBar() {
        self.tabBarController?.tabBar.items?[0].isEnabled = false; self.tabBarController?.tabBar.items?[1].isEnabled = false
    }
    
    @IBAction func bagButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "ShowBag", sender: self)
    }
    
    // Gets each menu category from the database for the selected restaurant
    func grabMenuCategories() {
        let docRef = self.database.collection("restaurant").document("restaurant_\(RestaurantDetailsPage.restaurantCode)").collection("menu")
        docRef.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let id = document.documentID
                    self.menuCategoryNames.append(id)
                }
                self.tableView.reloadData()
            }
        }
    }
    
    // Set height for the cells (might need to adjust the height here based on the data)
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return(75)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuCategoryNames.count
    }
    
    // Ran when a menu category was tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Category Tapped: \(menuCategoryNames[indexPath.row])")
        tableView.deselectRow(at: indexPath, animated: true)
        MenuCategories.selectedMenuCategory = menuCategoryNames[indexPath.row]
        self.performSegue(withIdentifier: "MenuCategorySelected", sender: self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCategoryCell", for: indexPath)
        cell.textLabel?.text = self.menuCategoryNames[indexPath.row]
        return cell
    }
}
