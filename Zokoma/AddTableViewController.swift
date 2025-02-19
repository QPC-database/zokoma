//
//  AddTableViewController.swift
//  Zokoma
//
//  Created by jiro9611 on 12/3/15.
//  Copyright © 2015 jiro9611. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
//import Parse
//import Bolts

class AddTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var restaurant:Restaurant!
    
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var nameTextField:UITextField!
    @IBOutlet weak var typeTextField:UITextField!
    @IBOutlet weak var locationTextField:UITextField!
    @IBOutlet weak var yesButton:UIButton!
    @IBOutlet weak var noButton:UIButton!
    
    var isVisited = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.allowsEditing = false
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary
                self.present(imagePicker, animated: true, completion: nil)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.clipsToBounds = true
        
        dismiss(animated: true, completion: nil)
    }

    @IBAction func save() {
    
        // Form validation
        var errorField = ""
        
        if nameTextField.text == "" {
            errorField = "name"
        } else if locationTextField.text == "" {
            errorField = "location"
        } else if typeTextField.text == "" {
            errorField = "type"
        }
        
        if errorField != "" {
            
            let alertController = UIAlertController(title: "Oops", message: "We can't proceed as you forget to fill in the restaurant " + errorField + ". All fields are mandatory.", preferredStyle: .alert)
            let doneAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(doneAction)
            
            self.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        // If all fields are correctly filled in, extract the field value
        // Create Restaurant Object and save to Local Core Data store
        if let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext {
            
            restaurant = NSEntityDescription.insertNewObject(forEntityName: "Restaurant",
                into: managedObjectContext) as! Restaurant
            restaurant.name = nameTextField.text
            restaurant.type = typeTextField.text
            restaurant.location = locationTextField.text
            restaurant.image = UIImagePNGRepresentation(imageView.image!)
            restaurant.isVisited = isVisited as NSNumber!
            
            // The newest way to handle error situation
            do {
                try managedObjectContext.save()
                print("Jiro test The name is: \(restaurant.name)")
                print("Jiro test The tyoe is: \(restaurant.type)")
                print("Jiro test The location is: \(restaurant.location)")
                print("Jiro test The isVisited is: " + (isVisited ? "Yes" : "No"))
            } catch let e {
                print("Could not cache the response \(e)")
            }
            
        }
        
        // Save record to the iCloud and share the restaurant with others (public DB)
        saveRecordToCloud(restaurant)
        
        //Excute the unwind segue and go back to the home screen
        performSegue(withIdentifier: "unwindToHomeScreen", sender: self)
        
    }
    
    @IBAction func updateIsVisited(_ sender: AnyObject) {
        // yes button clicked
        let buttonClicked = sender as! UIButton
        if buttonClicked == yesButton {
            isVisited = true
            yesButton.backgroundColor = UIColor(red: 216.0/255.0, green: 51.0/255.0, blue: 29.0/255.0, alpha: 1.0)
            noButton.backgroundColor = UIColor.gray
        } else if buttonClicked == noButton {
            isVisited = false
            yesButton.backgroundColor = UIColor.gray
            noButton.backgroundColor = UIColor(red: 216.0/255.0, green: 51.0/255.0, blue: 29.0/255.0, alpha: 1.0)
        }
        
    }
    
    func saveRecordToCloud(_ restaurant:Restaurant!) -> Void {
        
        //prepare the record to save
        let record = CKRecord(recordType: "Restaurant")
        record.setValue(restaurant.name, forKey: "name")
        record.setValue(restaurant.type, forKey: "type")
        record.setValue(restaurant.location, forKey: "location")
        
        //Resize the image
        let originalImage = UIImage(data: restaurant.image as Data)
//        let NSDataImage = NSData(data: restaurant.image)
        let scalingFactor = (originalImage!.size.width > 1024) ? 1024 / originalImage!.size.width : 1.0
        let scaledImage = UIImage(data: restaurant.image as Data, scale: scalingFactor)
        // Write the image to local file for temporary use
        let imageFilePath = NSTemporaryDirectory() + restaurant.name
        try? UIImageJPEGRepresentation(scaledImage!, 0.8)!.write(to: URL(fileURLWithPath: imageFilePath), options: [.atomic])
        
        // Create image asset for upload
        let imageFileURL = URL(fileURLWithPath: imageFilePath)
        let imageAsset = CKAsset(fileURL: imageFileURL)
        record.setValue(imageAsset, forKey: "image")
        
        // Get the public icloud database
        //cloudContainer
        _ = CKContainer.default()
        let publicDatabase = CKContainer.default().publicCloudDatabase
        
        // Save the record to iCloud
        publicDatabase.save(record, completionHandler: { (record:CKRecord?, error:Error?) -> Void  in
            
            // Remove temp file
            // New error handling method in Swift 2.0
            do {
                try FileManager.default.removeItem(atPath: imageFilePath)
            } catch let error as NSError{
                print("Failed to save record to the iCloud: \(error.description)")
            }
            
        } )
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
