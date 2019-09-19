//
//  AddProject.swift
//  Fidback Shack
//
//  Created by macbookair on 4/16/19.
//  Copyright © 2019 Jeffrey Small. All rights reserved.


import Foundation
import UIKit
import Firebase
import MobileCoreServices
import TOCropViewController
import Photos
import SwipeCellKit



class AddProject: UIViewController, UITextViewDelegate, TOCropViewControllerDelegate, SwipeTableViewCellDelegate {
    
    @IBOutlet var projectTitle: UITextField!
    @IBOutlet var projectDescription: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    
    var placeholderLabel = UILabel()
    
    @IBOutlet var imageView: UIImageView!
    
    let pickerData = ["Coding", "Marketing", "Music", "Video", "Design", "Podcasting", "Writing", "Art"]

    
    var ref: DocumentReference!
    var db : Firestore!
    var selectedCategoryRef: DocumentReference!
    var handle : AuthStateDidChangeListenerHandle?
    var rootRef = Storage.storage().reference()

    var selectedCriteria = [String]()
    
    var UID = String()
    var tableViewArray = [String]()
    var selectedCategory = String()
    var newProj : Project?
    
    var currentUser : User?
    var projectID = String()
    var blipArray = [[String:Any]]()
    var projectRef : StorageReference?
    
    var selectedBlip : [String:Any]?
    var selectedBlipIndex : Int?
    
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var addImageButton: roundedButton!
    @IBOutlet weak var addProjectButton: roundedButton!
    @IBOutlet weak var addBlipButton: roundedButton!
    
    


    //MARK: ViewDidLoad/ViewDidAppear Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupView()
        
        tableView.register(UINib(nibName: "BlipCell", bundle: nil), forCellReuseIdentifier: "cell")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        
        db = Firestore.firestore()
    }
    
    override func viewWillAppear(_ animated: Bool)    {
        
        updateArray()
        tableView.reloadData()
        
        
        // MARK: Firebase handler
        
        
        self.handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            
            if let user = user {
                
                self.projectID = UUID().uuidString
                self.projectRef = self.rootRef.child("\(user.uid)/\(self.projectID).jpg")
                self.UID = user.uid
            }
                
            else {
                
                print("could not authenticate user")
                return
            }
        })
    }
    
    

    @IBAction func addBlip(_ sender: Any) {
        
        ((sender) as! UIView).animate()
        
        if selectedBlip != nil {
        
            selectedBlip!.removeAll()
        }
        
        if blipArray.count < 3 {
        
        performSegue(withIdentifier: "newBlip", sender: self)
        
        }
        
        else {
            
            self.showBasicAlert(alertText: "Blip Limit Reached", alertMessage: "You can only have 3 blips per project")
        }
    }
    
    
    
// TODO: Add guard/let and write to firetore statements for project image, selected criteria, userID
    
    @IBAction func addProject(_ sender: Any) {
        
        ((sender as! UIView).animate())
        
        if blipArray == nil {showBasicAlert(alertText: "Blipless", alertMessage: "Please add a blip"); return}
        
        if projectTitle.text!.isEmpty {return}
        
//MARK: Get imageData and downloadURL
        
        if let imageData = imageView.image!.jpegData(compressionQuality: 1) {
            
            self.projectRef!.putData(imageData, metadata: nil) { (metadata, error) in
                
                if error != nil {
                    print (error!)
                    return
                }
        
                else {
                
                print(metadata!)
                self.projectRef!.downloadURL(completion: { (url, error) in
                    
                    if error != nil {
                        
                        print("Error loading image download URL: \(error!)")
                    }
                    
                    else {
                        
                        print ("Successfuly loaded image download URL")
                        self.registerProjectToDatabase(project: self.createProject(url: url!))
                    }
                })
            }
        }
    }
        
        else {
            
            print("no photo available for upload")
        }
    }

    
    
//MARK: Project Creation Helper functions
    
    
    func registerProjectToDatabase(project: Project) {
        
        ref = db.collection("Projects").addDocument(data: project.dictionary) { error in

            if let error = error {
                print("There was an error: \(error.localizedDescription)")
            }
            else {
                
                self.navigationController?.popToRootViewController(animated: true)
                print("Document has been saved with ID: \(self.ref!.documentID)")
                self.defaults.removeObject(forKey: "blipArray")
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "newBlip" {
            
            if let vc = segue.destination as? NewBlip {
                
                vc.user = self.currentUser
                
                if selectedBlip != nil {
                    
                    vc.currentBlipDict = selectedBlip
                    vc.blipIndex = selectedBlipIndex
                    vc.blipArray = blipArray
                    vc.isNewProject = true
                }
                
                else {
                    
                    vc.blipArray = blipArray
                }
            }
        }
        
        if segue.identifier == "showPopOver" {
            
            if let view = segue.destination as? EditBlips {
                
                view.popoverPresentationController?.delegate = self as! UIPopoverPresentationControllerDelegate
                view.preferredContentSize = CGSize(width: 160, height: 400)
                
                view.blipArray = blipArray
                
            }
        }
    }
    
    
    func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        
        imageView.image = image
        self.dismiss(animated: true, completion: nil)
    }
    
    func createProject(url: URL) -> Project {
        
        let titleProject = projectTitle.text!
        let pDescription = projectDescription.text!
        let ratedByUID = [String]()
        let feedbackArray = [[String:Any]]()
        
        
        let newProj = Project(projectOwnerUsername:(Auth.auth().currentUser?.displayName)!, imageLink: ((url.absoluteString)), title: titleProject, category: self.selectedCategory, description: pDescription, UID: self.UID, timeStamp: Timestamp(), id: projectID, selectedCriteria: self.selectedCriteria, ratedByUID: ratedByUID, feedbackArray: feedbackArray, blipArray: blipArray, userScore: currentUser!.points, profileImageLink: currentUser!.profileImageLink, featured: false, contributorsUID: [["UID" : self.UID, "profileImageLink" : currentUser!.profileImageLink, "owner" : true, "username" : currentUser?.username]])

        return newProj
    }
    
    
    //MARK: Textview functions
    
    func textViewDidChange(_ textView: UITextView) {
        
        if projectDescription.text.isEmpty {
            
            placeholderLabel.isHidden = false
        }
        
        else {
            
            let label = placeholderLabel
            label.isHidden = true
        }
    }
    
    
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        //TODO : RE-impl
        
//        if parent == nil {
//
//            self.defaults.removeObject(forKey: "blipArray")
//        }
    }
    
    
    func updateArray() {
        
        guard let dArray = defaults.object(forKey: "blipArray") as? [[String:Any]] else {return}
        
        blipArray = dArray
        
        DispatchQueue.main.async {
            
            self.tableView.reloadData()
        }
    }
    
    
    
    func setupView() {
        
        addImageButton.setBackgroundColor(colorName: "Splish")
        addImageButton.setBackgroundColor(colorName: "Splesh")
        addProjectButton.setBackgroundColor(colorName: "Splish")
        addBlipButton.setBackgroundColor(colorName: "EditColor")
        
        projectDescription.setupTextview()
        placeholderLabel.initiatePlaceholder(textView: projectDescription, currentViewController: self)
    }
}


extension AddProject: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return blipArray.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! BlipCell
        
        cell.delegate = self
        
        let dict = blipArray[indexPath.row]
        cell.setCell(blipDict: dict)
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        selectedBlip = blipArray[indexPath.row]
        
        selectedBlipIndex = indexPath.row
        
        self.performSegue(withIdentifier: "newBlip", sender: self)
        
        // TODO: Segue to add blip

    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {

//        self.performSegue(withIdentifier: "addBlip", sender: self)
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        guard orientation == .right else  {return nil}
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            
            self.blipArray.remove(at: indexPath.row)
            self.defaults.set(self.blipArray, forKey: "blipArray")
            tableView.reloadData()
        }
        
        return [deleteAction]
    }
}



extension AddProject: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBAction func addImage(_ sender: Any) {
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        
        imagePickerController.navigationBar.tintColor = UIColor.white
        imagePickerController.navigationBar.backItem?.rightBarButtonItem?.tintColor = UIColor.white
        imagePickerController.navigationBar.backItem?.leftBarButtonItem?.tintColor = UIColor.white
        
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a source", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                
                imagePickerController.sourceType = .camera
                self.present(imagePickerController, animated: true, completion: nil)
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction) in
            
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        if let originalImage = info[UIImagePickerController.InfoKey.originalImage] {
            
            picker.dismiss(animated: true) {
                
                
// Setup Crop View Controller
                
                var destinationVC = TOCropViewController(image: originalImage as! UIImage)
                
                destinationVC.delegate = self as! TOCropViewControllerDelegate
                destinationVC.aspectRatioPreset = .preset16x9
                destinationVC.resetButtonHidden = true
                destinationVC.aspectRatioPickerButtonHidden = true
                destinationVC.aspectRatioLockEnabled = true
                
                self.present(destinationVC, animated: true, completion: nil)
            }
        }
    }
    
    
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated:true, completion:nil)
    }
}

