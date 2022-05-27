# DineOnDemand Project Details

Welcome Everyone! This project is a fully functional IOS application that was developed in a group consisting of my two friends and I. This application was for a college graduate final project and was presented in front of professors and the head of computer science at my college (NYIT). 

DineOnDemand was developed using the Swift programming language in the xCode IDE, UIKit package in xCode, Sketch (for UI Designs), and Firebase (the backend database)

We followed the Waterfall Software Engineering Model in combination with Scrum

ALL sensitive data (passwords, credit card info, etc) was encrypted in the database for security purposes

When loading the application for the first time, Users will be prompted by the sign-in page. If they have an account, they could sign-in. If they forgot their credentials, they can tap the forgot password button and an email will be sent to reset their password. If they are first-time users, they can tap the sign-up button which will proceed to ask the user for the necessary information needed to sign-up. If the user is an employee for a restaurant, they need to select that they are an employee and type in the correct "restaurant code" for the restaurant they are working for. Each restaurant code is specific and is used to identify each restaurant. the restaurant code is stored in the database.

Here are the main features of DineOnDemand for customers:
  - Order food from local restaurants and track delivery if the delivery option was selected
      - Customers are presented with the restaurant's menu when they select a restaurant. Each menu item is listed with it's price in a table view. Once the customer             taps a menu item, a popup appears asking the quantity they would like of the item. Once the customer selects the quantity, the selected item will be added to             their cart where they are presented with the total cost of their order. Customers must choose either pickup or delivery for their order. The delivery option adds         a delivery fee to the total cost of their order
      - Customers have the option to apply a giftcard to their order, if it exists
      - Customers can change the card on file when placing order, in case they don't want to charge that specific card for the order
  - Make reservations at local restaurants
  - Set weekly budgets to help keep track of how much you order takeout
  - Purchase and redeem giftcards to use in the application
 
Other features for customers are:
  - Save credit card information to purchase food or giftcards
  - Save delivery address for the driver to use when delivering customer's order
  - View their spending data per month. Customers can see when they go over their set budget
  - View their order's status when they place an order at a restaurant. If customer chooses delivery, they can track their order via GPS.


DineOnDemand has five other account types: Employee, Manager, Cook, Driver, and Admin. 

Here are the features for Employees in the application:
  - View current order status for all current orders placed by customers
      - All orders are sorted from most recently placed
  - View all past orders placed by customers
  - View all current and past reservations made at the restaurant
      - Can update reservation status if party shows up or doesn't
      - Reservations are sorted from most recently placed

Here are the features for Drivers in the application:
  - View all order's set for delivery
  - Can take on orders (meaning grab the order to delivery to customer's address), which updates the order's status on the customer's end and employee's end
  - Can calculate a route on a GPS (Using Apple Maps) from their current location to the customer's provided delivery address
      - Their current location updates automatically and will update on the customer's end simultaneously
      - Shows an ETA to the customer's address from the driver's location
      - (Future Implementation) -> Fix the GPS route polyline so it updates once the driver's location changes and removes the polyline after driver passes it. Also make         ETA decrement as driver moves
  - Once delivery is completed, drivers can mark the order as delivered, which will then update the status on the customer's end and employee's end

Here are the features for the Cook in the application:
  - Able to see newly placed orders that need to be cooked
  - Can update the status of orders when preparing/cooking it
  - Can mark it as ready to be picked up or delivered (depending on the option the customer chose)

Here are the features for the Manager in the application:
  - Can view all orders (current and past) and reservations (current and past) placed at the restaurant
      - Again everything is sorted from most recently placed
  - Can view the restaurant's financial data
      - Chooses a year in which they want to view the data for
            - Displays the total amount of profit made for each month at the restaurant
                - A table with each row as a month followed by the profit amount made
      - Profits update in real-time
  - Can accept new employee account creation requests
      - In the application, there are employees, cooks, and drivers. When an account is created for an employee during sign-up, the manager has to manually set their             role in the restaurant by typing in "Employee" or "Cook" or "Driver". This will then activate their account and have the correct privileges for that account. To         clarify what an "Employee" role is in the application, they could be host/hostesses or waitors/waitresses.
      - Are able to see all current workers at the restaurant in a table view. Each table cell shows certain pieces of information related to the account.
  
Here are the features for the Admin in the application:
  - Can view their account details
  - Can view restaurant's order and reservation statistics
      - They choose a restaurant they want to see, and all the orders ever placed will populate in a table view and show the necessary information we felt was appropriate for them to see; Without disclosing any sensitive data
      - Can see the total number of orders or reservations made at the selected restaurant
      - Same thing with the reservation statistics
  - Can accept new manager account creation requests
      - Shown all new manager account requests and all current manager accounts in a table with each account's necessary information, respectively
      - Can accept or reject new manager account requests for specific restaurants
  - Can see all the registered accounts with the appropriate information from their accounts in the application. Basically every account ever created in the application, whether the account type. They can also view the accounts that have not been activated yet (Only the employee accounts). The become activated when the manager or admin accept their account request on their end.

DineOnDemand Testing:
  - Whitebox testing
      - Unit Testing
  - Blackbox testing
      - Smoke Testing
      - Functional Testing

Future Implementations Include:
  - Encrypting more data than just the sensitive data
  - Create an android version of the application
  - Fix the GPS function issues we had in the application. As of right now the ETA does not update as the driver gets closer and the route polyline does not get removed     as the driver passes by a location.
  - Add promotion codes for users to get discounts on their orders
  - Add pictures of the menu items in the menu for each restaurant


Thank you for reading this far! I hope you are interested in our project. My group and I are extremely proud of it.
Have a wonderful day!

Micwi
