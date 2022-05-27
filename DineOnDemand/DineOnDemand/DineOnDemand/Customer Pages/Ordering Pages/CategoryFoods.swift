//
//  RestaurantMenuTableView2.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 3/21/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

//  Created by Louie Patrizi Jr. on 3/21/22.

class CategoryFoods: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    private let database = Firestore.firestore()
    @IBOutlet var tableView2: UITableView!
    
    static var menuCategoryItems = [food]()
    static var bagItems = [order]()
    static var orderItemIndex: Int?
    
    @IBOutlet weak var bagButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = MenuCategories.selectedMenuCategory
        grabMenuCategoryItems()
    }
    
    @IBAction func bagButtonTapped(_ sender: Any) {
        self.performSegue(withIdentifier: "ShowBag", sender: self)
    }
    
    func grabMenuCategoryItems() {
        CategoryFoods.menuCategoryItems = [food]()
        let docRef = self.database.collection("restaurant").document("restaurant_\(RestaurantDetailsPage.restaurantCode)").collection("menu").document(MenuCategories.selectedMenuCategory)
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            let fieldCount = data.count
            
            for x in 1...fieldCount{
                let item = data["food_\(x)"] as! [Any]
                CategoryFoods.menuCategoryItems.append(food(item: item[0] as! String, price: item[1] as! Int))
                self.tableView2.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CategoryFoods.menuCategoryItems.count
    }
    
    // Set height for the cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return(103)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Item Tapped: \(CategoryFoods.menuCategoryItems[indexPath.row])")
        tableView.deselectRow(at: indexPath, animated: true)
        CategoryFoods.orderItemIndex = indexPath.row
        switchViewController(identifier: "PopUpWindowID")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodCell", for: indexPath) as! foodItemCell
        cell.itemLabel.text = "\(CategoryFoods.menuCategoryItems[indexPath.row].item)"
        cell.priceLabel.text = "$\(CategoryFoods.menuCategoryItems[indexPath.row].price)"
        return(cell)
    }
    
    func switchViewController(identifier: String) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: identifier)
        self.present(newViewController, animated: true, completion: nil)
    }
    
}

class foodItemCell: UITableViewCell {
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var itemLabel: UILabel!
}

//for foods in DB
struct food {
    var item: String
    var price: Int
}

//for customer order
struct order {
    var orderedItem: String
    var price: Int
    var quantity: Int
}
