//
//  popUpWindow.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 3/25/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

//  Created by Louie Patrizi Jr. on 3/25/22.

class PopUpWindow: UIViewController {
    
    @IBOutlet weak var orderedItemLabel: UILabel!
    @IBOutlet weak var quantityValueLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var viewWindow: UIView!
    @IBOutlet weak var stepper: UIStepper!
    var quantityValue: Int = 1
    var updatedPrice: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stepper.value = 1; stepper.minimumValue = 1
        orderedItemLabel.text = "\(CategoryFoods.menuCategoryItems[CategoryFoods.orderItemIndex!].item)"
        viewWindow.layer.cornerRadius = 10; stepper.layer.cornerRadius = 10
    }
    
    @IBAction func stepperTapped(_ sender: UIStepper) { quantityValueLabel.text = "\(Int(sender.value).description)" }
    
    @IBAction func addToCartButtonTapped(_ sender: Any) {
        quantityValue = Int(quantityValueLabel.text!)!
        updatedPrice = CategoryFoods.menuCategoryItems[CategoryFoods.orderItemIndex!].price * quantityValue
            CategoryFoods.bagItems.append(order(orderedItem:"\(CategoryFoods.menuCategoryItems[CategoryFoods.orderItemIndex!].item)", price: updatedPrice, quantity: quantityValue))
        self.dismiss(animated: true) // Closes the popup window
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
}
