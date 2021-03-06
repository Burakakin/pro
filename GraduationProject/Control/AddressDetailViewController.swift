//
//  AddressDetailViewController.swift
//  GraduationProject
//
//  Created by Burak Akin on 2.12.2018.
//  Copyright © 2018 Burak Akin. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class AddressDetailViewController: UIViewController, UITextFieldDelegate {

    var ref: DocumentReference!
    @IBOutlet weak var addressNameTextField: UITextField!
    @IBOutlet weak var fullAddressTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

      addressNameTextField.delegate = self
      fullAddressTextField.delegate = self
        // Do any additional setup after loading the view.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    @IBAction func saveToDatabase(_ sender: Any) {
        guard let addressName = addressNameTextField.text, !addressName.isEmpty else { return }
        guard let fullAddress = fullAddressTextField.text, !fullAddress.isEmpty else { return }
        
        let currentUser = Auth.auth().currentUser
        guard let user = currentUser else { return }
        let userId = user.uid
        
        
        ref = Firestore.firestore().document("User/\(userId)")
        
        ref.updateData([
            "address.\(addressName)": fullAddress
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
        
        
    }
    

}
