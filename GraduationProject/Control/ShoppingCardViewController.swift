//
//  ShoppingCardViewController.swift
//  GraduationProject
//
//  Created by Burak Akin on 1.12.2018.
//  Copyright © 2018 Burak Akin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class ShoppingCardViewController: UIViewController {

    
    var ref: DocumentReference!
    var refItem: DocumentReference!
   
    var shoppingCartArr = [[String: String]]()
    var priceKeeperArr = [[String: Int]]()
    
    @IBOutlet weak var shoppingCartTableView: UITableView!
    @IBOutlet weak var totalPriceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        totalPriceLabel.text = "Total Price: \(0)TL"
        getShoppingCartPath()
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if shoppingCartArr.isEmpty {
                print("There is no item in Shopping Cart")
            }
            else {
                if segue.identifier == "checkOut" {
                    if let addressSelectionVC = segue.destination as? AddressSelectionViewController {
                        addressSelectionVC.shoppingCartAddressSelection = shoppingCartArr
                        addressSelectionVC.priceKeeperAddressSelection = priceKeeperArr
                    }
                }
            }
            
        }
    

    @IBAction func leftSideButtonTapped(_ sender: Any) {
        let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.centerContainer!.toggle(MMDrawerSide.left, animated: true, completion: nil)
    }
   
    
    func deleteField(key: String) {
        let user = Auth.auth().currentUser
        guard let uid = user?.uid else { return }
        ref = Firestore.firestore().document("User/\(uid)/userDetail/userDetailDocument")
        
        ref.updateData([
            "shoppingCart.\(key)": FieldValue.delete(),
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully deleted")
                }
        }
    }
    
    func getShoppingCartPath() {
        
        let user = Auth.auth().currentUser
        guard let uid = user?.uid else { return }
        ref = Firestore.firestore().document("User/\(uid)/userDetail/userDetailDocument")
        
        ref.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let shoppingCartArr = data!["shoppingCart"] as? Dictionary<String, String> {
                    for item in shoppingCartArr {
                        self.refItem = Firestore.firestore().document("\(item.value)")
                        self.refItem.getDocument { (document, error) in
                            if let document = document, document.exists {
                                let dataDescription = document.data()
                                let key = item.key
                                let imageUrl = dataDescription!["imageUrl"] as! String
                                let name = dataDescription!["name"] as! String
                                let seller = dataDescription!["seller"] as! String
                                let description = dataDescription!["description"] as! String
                                let price = Int(dataDescription!["price"] as! String)
                                //print("Document data: \(dataDescription)")
                                let shoppingCart: [String: String] = ["key": key,"name": name, "imageUrl": imageUrl, "description": description, "seller": seller ]
                                let priceKeeper: [String: Int] = ["price": price!, "total": price!, "amount": 1]
                                DispatchQueue.main.async {
                                    self.priceKeeperArr.append(priceKeeper)
                                    self.shoppingCartArr.append(shoppingCart)
                                    self.shoppingCartTableView.reloadData()
                                }
                                
                                
                            } else {
                                print("Document does not exist")
                            }
                        }
                        
                    }
                }
                
            } else {
                print("Document does not exist")
            }
        }
        
        
    }
    
    

}


extension ShoppingCardViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shoppingCartArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "shoppingCell", for: indexPath) as! ShoppingCardTableViewCell
        
        var totalPrice = 0
        for i in 0..<self.priceKeeperArr.count {
            totalPrice += self.priceKeeperArr[i]["total"]!
            self.totalPriceLabel.text = "Total Price: \(totalPrice) TL"
        }
        
        cell.shoppingCardProductName.text = shoppingCartArr[indexPath.row]["name"]
        cell.shoppingCardProductDescription.text = shoppingCartArr[indexPath.row]["description"]
        cell.shoppingCardProductSeller.text = "by " + shoppingCartArr[indexPath.row]["seller"]!
        cell.shoppingCardProductPrice.text = "\(priceKeeperArr[indexPath.row]["total"] ?? 0)" + "TL"
        cell.shoppingCardPieceLabel.text = "\(priceKeeperArr[indexPath.row]["amount"] ?? 0) Piece(s)"
        imageDownload.getImage(withUrl: shoppingCartArr[indexPath.row]["imageUrl"]!) { (image) in
            cell.shoppingCardProductImageView.image = image
        }
        
        cell.DeleteButtonTapped = { (selectedCell) -> Void in
             let path = tableView.indexPathForRow(at: selectedCell.center)!
             let selectedKey = self.shoppingCartArr[path.row]["key"]
            self.deleteField(key: selectedKey!)
            self.shoppingCartArr.remove(at: path.row)
            tableView.reloadData()
            //self.getShoppingCartPath()
            self.priceKeeperArr.remove(at: path.row)
            
    
            var totalPrice = 0
            for i in 0..<self.priceKeeperArr.count {
                totalPrice += self.priceKeeperArr[i]["total"]!
                self.totalPriceLabel.text = "Total Price: \(totalPrice) TL"
            }
            
        }
        
        
        cell.PlusButtonTapped = { (selectedCell) -> Void in
            let path = tableView.indexPathForRow(at: selectedCell.center)!
            let selectedItem = self.priceKeeperArr[path.row]
            
            let price = selectedItem["price"]!
            var total = selectedItem["total"]!
            var amount = selectedItem["amount"]!
           
            if amount > 5 {
                print("We don't have much")
            }
            else {
                amount += 1
                total = price * amount
                self.priceKeeperArr[indexPath.row]["total"] = total
                self.priceKeeperArr[path.row]["amount"] = amount
                cell.shoppingCardProductPrice.text = "\(total)" + "TL"
                cell.shoppingCardPieceLabel.text = "\(amount) Piece(s)"
                print(self.priceKeeperArr)
                
                var totalPrice = 0
                
                for i in 0..<self.priceKeeperArr.count {
                    totalPrice += self.priceKeeperArr[i]["total"]!
                    self.totalPriceLabel.text = "Total Price: \(totalPrice) TL"
                }
            }
        }
        
        cell.MinusButtonTapped = { (selectedCell) -> Void in
            let path = tableView.indexPathForRow(at: selectedCell.center)!
            let selectedItem = self.priceKeeperArr[path.row]
            
            let price = selectedItem["price"]!
            var total = selectedItem["total"]!
            var amount = selectedItem["amount"]!

            if amount > 1 {
                
                amount -= 1
                total = price * amount
                self.priceKeeperArr[indexPath.row]["total"] = total
                self.priceKeeperArr[path.row]["amount"] = amount
                cell.shoppingCardProductPrice.text = "\(total)" + "TL"
                cell.shoppingCardPieceLabel.text = "\(amount) Piece(s)"
                print(self.priceKeeperArr)
                

                var totalPrice = 0
                
                for i in 0..<self.priceKeeperArr.count {
                    totalPrice += self.priceKeeperArr[i]["total"]!
                    self.totalPriceLabel.text = "Total Price: \(totalPrice) TL"
                }
                
                
            }
            else {
                print("We don't have much")
            }
        }
        
        
        
        
        return cell
    }
    
}
