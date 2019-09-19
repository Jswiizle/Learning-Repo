//
//  NewBlip.swift
//  Fidback Shack
//
//  Created by user on 8/29/19.
//  Copyright © 2019 Jeffrey Small. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import TOCropViewController
import Photos


class NewBlip : UIViewController, UITextViewDelegate, TOCropViewControllerDelegate {
    
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var blipDescription: UITextView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var addElementButton: roundedButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var blipView: UIView!
    @IBOutlet weak var editImageButton: UIButton!
    
    
    var placeholderLabel = UILabel()
    var cropViewController = TOCropViewController()
    let defaults = UserDefaults.standard
    var secondArray = ["1","2","3","4","5","6","7","8","9","10"]

    var blipIndex : Int?
    var blipEditing = Bool()
    var currentBlipDict : [String:Any]?
    var blipArray = [[String:Any]]()
    var currentLink : URL?
    var user : User?
    var isNewProject = Bool()
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        setBlipArray()
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
        
        guard let dict = currentBlipDict else {isNewBlip(); print("no current blip"); return}
        
//        loadBlip(blipDict: dict)
//        setBlipArray()
        
        if blipEditing == true {
            
            self.navigationItem.rightBarButtonItem?.title = "Done Editing"
        }
        
        else {
            
            loadBlip(blipDict: dict)
        }
    }

    
    @IBAction func addElementPressed(_ sender: Any) {
        
        addElementButton.isHidden = true
        
        if segmentedControl.selectedSegmentIndex == 0  {
            
            setBlipImage()
        }
        
        else {
            
            presentURLPopup()
        }
    }
    
    
    
    @IBAction func segmentedControlPressed(_ sender: Any) {
        
        if segmentedControl.selectedSegmentIndex == 0 {
            
            if blipEditing == true {
                
                editImageButton.setImage(UIImage(named: "editImage"), for: .normal)
                blipView.bringSubviewToFront(editImageButton)
            }
            

            imageView.isHidden = false
            webView.isHidden = true
            
            if currentBlipDict != nil {
                
                loadBlip(blipDict: currentBlipDict!)
                addElementButton.isEnabled = false
                addElementButton.isHidden = true
            }
                
            else {
                
                addElementButton.setTitle("Add Photo", for: .normal)
            }
        }
            
        else {
            
            if blipEditing == true {
                
                blipView.bringSubviewToFront(editImageButton)
                editImageButton.setImage(UIImage(named: "editLink"), for: .normal)
            }
            
            imageView.isHidden = true
            webView.isHidden = false
            
            if currentBlipDict != nil {
                
                loadBlip(blipDict: currentBlipDict!)
                addElementButton.isEnabled = false
                addElementButton.isHidden = true
            }
                
            else {
                
                addElementButton.setTitle("Add Link", for: .normal)
            }
        }
    }
    
    
    @IBAction func editImage(_ sender: Any) {
        
        if segmentedControl.isEnabledForSegment(at: 0) {
            
            setBlipImage()
        }
        
        else {
            
            presentURLPopup()
        }
    }
    
    
    
    
    func loadBlip(blipDict: [String:Any]) {
        
        if blipEditing == false {
            
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: Selector(("editBlip")))
            self.navigationItem.rightBarButtonItem?.tintColor = UIColor.white
            self.navigationController?.title = "Edit Blip"
        }
        
        editImageButton.isHidden = false
        
        pickerView.selectRow(blipDict["seconds"] as! Int - 1, inComponent: 0, animated: true)
        
        currentBlipDict = blipDict
        
        addElementButton.isHidden = true
        placeholderLabel.isHidden = true
        
        pickerView.isUserInteractionEnabled = false
        
        titleField.isEnabled = false
        blipDescription.isEditable = false
        
        if blipDict["image"] != nil {
            
            webView.isHidden = true
            imageView.isHidden = false
            
            blipView.bringSubviewToFront(imageView)
            
            if blipEditing == true {
                
                blipView.bringSubviewToFront(editImageButton)
            }
            
            imageView.image = UIImage(data: blipDict["image"] as! Data)
            titleField.text = blipDict["title"] as? String
            blipDescription.text = blipDict["description"] as? String
        }
            
        else if blipDict["url"] != nil {
            
            webView.isHidden = false
            imageView.isHidden = true
            blipView.bringSubviewToFront(webView)
            
            if blipEditing == true {
                
                blipView.bringSubviewToFront(editImageButton)
            }
            
            titleField.text = blipDict["title"] as? String
            blipDescription.text = blipDict["description"] as? String
            
            guard let url = URL(string: (blipDict["url"] as! String)) else {showBasicAlert(alertText: "No URL Available", alertMessage: "The URL could not be loaded"); return}
            
            print(url.absoluteString)
            
            webView.load(URLRequest(url: URL(string: blipDict["url"] as! String)!))
        }
        
        else {return}
        
    }
    
    
    func presentURLPopup() {
        
        let alertController = UIAlertController(title: "Link?", message: "Please input your link URL:", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            guard let textFields = alertController.textFields,
                textFields.count > 0 else {return}
            
            let field = textFields[0]
            self.configureLink(link: field.text!)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            
            self.addElementButton.isHidden = false
        }
        
        alertController.addTextField { (textField) in
            
            textField.text = "http://"
            textField.placeholder = "Enter a URL"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
    func configureLink(link : String) {
        
        currentLink = URL(string: link)
        
        guard let url = URL(string: link) else { print("cannot init URL"); return }
        
        let request  = URLRequest(url: url)
        
        webView.load(request)
        webView.isHidden = false
    }
    
    
    
    func textViewDidChange(_ textView: UITextView) {
        
        if textView.text.isEmpty {
            
            placeholderLabel.isHidden = false
        }
            
        else {
            
            placeholderLabel.isHidden = true
        }
    }
    
    
    
    // MARK: Selectors
    
    
    
    @objc func blipAdded() {

        print("selector pressed")
        
        if imageView.image != nil {
            
            print("imageView is not nil")
            
            guard let imageData = imageView.image?.jpegData(compressionQuality: 0.25) else {print("no image data"); return}
            guard blipDescription.text != nil else {print("description is nil"); return}
            
            let newDict = ["description" : blipDescription.text!, "image" : imageData, "seconds" : 5, "title" : titleField.text!] as [String : Any]
            
            blipArray.append(newDict)
            
            defaults.setValue(blipArray, forKey: "blipArray")
            
            print("blip was set")
            
            self.navigationController?.dismiss(animated: true, completion: nil)
            
        }
            
        else if webView.url != nil {

            print("webview is not nil")

            guard blipDescription.text != nil else {print("descrip empty"); return}
            guard imageView != nil else {print("image not nil"); return}
            
            let newDict = ["description" : self.blipDescription.text!, "url" : self.currentLink!.absoluteString, "title" : self.titleField.text!] as [String : Any]
            blipArray.append(newDict)
            defaults.setValue(blipArray, forKey: "blipArray")
            
            if isNewProject == false {
                
                self.navigationController!.popViewController(animated: true)
            }
        }
    }
    
    
    
    @objc func editBlip() {
        
        blipEditing.toggle()
        
        if blipEditing == true {
        
            startEditing()
        }
        
        else {
            
            endEditing()
        }
    }
    
    
    @objc func dismissView() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // View did load/view did appear functions
    
    
    func setupView() {
        
        blipView.layer.borderWidth = 1.0
        blipView.layer.borderColor = self.view.tintColor.cgColor
        
        addElementButton.setBackgroundColor(colorName: "Splish")
        editImageButton.isHidden = true
        
        let leftNavButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: Selector("dismissView"))
        
        self.navigationItem.leftBarButtonItem = leftNavButton
        leftNavButton.tintColor = .white
        
        blipDescription.setupTextview()
        placeholderLabel.initiatePlaceholder(textView: blipDescription, currentViewController: self)
    }
    
    
    func resetView() {
        
        
    }
    
    
    func setBlipArray() {
        
        if blipArray.count < 1  {
            
            if let array = (defaults.array(forKey: "blipArray") as? [[String:Any]]) {
                
                blipArray = array
            }
                
            else {
                
                blipArray = []
            }
        }
    }
    
    
    
    //MARK: Editing Helper Functions
    
    
    
    func startEditing() {
        
        self.navigationItem.rightBarButtonItem?.title = "Done Editing"
        
        imageView.alpha = 0.5
        webView.alpha = 0.5
        
        editImageButton.isHidden = false
        editImageButton.addScaleAnimationToFloatingButton()
        
        self.view.bringSubviewToFront(blipView)
        blipView.bringSubviewToFront(editImageButton)
        
        pickerView.isUserInteractionEnabled = true
        titleField.isEnabled = true
        blipDescription.isEditable = true
    }
    
    
    func endEditing() {
        
        currentBlipDict!["title"] = titleField.text
        currentBlipDict!["seconds"] = pickerView.selectedRow(inComponent: 0) + 1
        currentBlipDict!["description"] = blipDescription.text
        
//        imageView.alpha = 1
//        webView.alpha = 1
        
        blipArray.remove(at: blipIndex!)
        blipArray.append(currentBlipDict!)
        
        editImageButton.isHidden = true
        
        defaults.setValue(blipArray, forKey: "blipArray")
    
        // IF the project has already been uploaded, dismiss. If not, pop nav ctrler
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func isNewBlip() {
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Blip", style: .plain, target: self, action: Selector(("blipAdded")))
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.white
        self.title = "Add Blip"
    }
}

extension NewBlip : UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return secondArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return secondArray[row]
    }
}


extension NewBlip: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    func setBlipImage() {
        
        
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
        
        self.present(actionSheet, animated: true, completion: {
            
            self.addElementButton.isHidden = false
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        if let originalImage = info[UIImagePickerController.InfoKey.originalImage] {
            
            picker.dismiss(animated: true) {
                
                
                // Setup Crop View Controller
                
                var destinationVC = TOCropViewController(image: originalImage as! UIImage)
                
                destinationVC.delegate = self as TOCropViewControllerDelegate
                destinationVC.aspectRatioPreset = .preset16x9
                destinationVC.resetButtonHidden = true
                destinationVC.aspectRatioPickerButtonHidden = true
                destinationVC.aspectRatioLockEnabled = true
                
                self.present(destinationVC, animated: true, completion: nil)
            }
        }
    }
    
    
    func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        
        imageView.image = image
        blipView.bringSubviewToFront(imageView)
        
        currentBlipDict?["image"] = image.jpegData(compressionQuality: 1)
        
        imageView.alpha = 1
        webView.alpha = 1
        editImageButton.isHidden = true

        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated:true, completion:nil)
    }
}
