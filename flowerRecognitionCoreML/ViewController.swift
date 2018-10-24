//
//  ViewController.swift
//  flowerRecognitionCoreML
//
//  Created by Marisha Deroubaix on 12/09/18.
//  Copyright © 2018 Marisha Deroubaix. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage
import SVProgressHUD
import ColorThiefSwift

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
  
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var imageViewOutlet: UIImageView!
  @IBOutlet weak var flowerDescriptionTextView: UITextView!
  @IBOutlet weak var cameraButton: UIBarButtonItem!
  @IBOutlet weak var toolBar: UIToolbar!
  
  let wikipediaURl = "https://en.wikipedia.org/w/api.php"
  let imagePicker = UIImagePickerController()
  var pickedImage : UIImage!
  
  
  override func viewWillAppear(_ animated: Bool) {
    cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
  }
  
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    if let userPickedImage = info[.originalImage] as? UIImage {
      
      imagePicker.dismiss(animated: true, completion: nil)
      
      guard let ciImage = CIImage(image: userPickedImage) else {
        fatalError("Could not convert UIImage to CIImage")
      }
      
      pickedImage = userPickedImage
      detect(image: ciImage)
    }
    
    imagePicker.dismiss(animated: true, completion: nil)
    
  }
  
  
  func detect(image: CIImage) {
    
    guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
      fatalError("Error loading coreML")
    }
    
    let request = VNCoreMLRequest(model: model) { (request, error) in
      guard let classification = request.results?.first as? VNClassificationObservation else {
        fatalError("Model failed to process image")
      }
      self.navigationItem.title = classification.identifier.capitalized
      self.requestInfo(flowerName: classification.identifier)
    }
    
    let handler = VNImageRequestHandler(ciImage: image)
    
    do {
      try handler.perform([request])
    } catch {
      print(error)
    }
  }
  
  func requestInfo(flowerName: String) {
    
    SVProgressHUD.show()
    
    let parameters : [String:String] = [
      "format" : "json",
      "action" : "query",
      "prop" : "extracts|pageimages",
      "exintro" : "",
      "explaintext" : "",
      "titles" : flowerName,
      "indexpageids" : "",
      "redirects" : "1",
      "pithumbsize" : "500"
    ]
    
    Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
      if response.result.isSuccess {
        
        //        print(JSON(response.result.value!))
        
        let flowerJSON : JSON = JSON(response.result.value!)
        let pageid = flowerJSON["query"]["pageids"][0].stringValue
        let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
        let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
        self.flowerDescriptionTextView.text = flowerDescription
        
        self.imageViewOutlet.sd_setImage(with: URL(string: flowerImageURL), completed : {(image, error, cache, url) in
          SVProgressHUD.dismiss()
          
          if let currentImage = self.imageViewOutlet.image {
            
            guard let dominantColor = ColorThief.getColor(from: currentImage) else {
              fatalError("Can't get dominant color from image")
            }
            DispatchQueue.main.async {
              self.navigationController?.navigationBar.isTranslucent = true
              self.navigationController?.navigationBar.barTintColor = dominantColor.makeUIColor()
              self.toolBar.barTintColor = dominantColor.makeUIColor()
              self.toolBar.isTranslucent = true
            }
          } else {
            self.imageViewOutlet.image = self.pickedImage
            self.flowerDescriptionTextView.text = "Could not get info from Wikipedia."
          }
        })
      } else {
        self.flowerDescriptionTextView.text = "Connection Issues."
      }
    }
  }
  
  func sourceTypePicked(source: UIImagePickerController.SourceType) {
    imagePicker.delegate = self
    imagePicker.sourceType = source
    present(imagePicker, animated: true, completion: nil)
  }
  
  @IBAction func albumPressed(_ sender: UIBarButtonItem) {
    imagePicker.allowsEditing = true
    sourceTypePicked(source: .photoLibrary)
  }
  
  @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
    imagePicker.allowsEditing = true
    sourceTypePicked(source: .camera)
  }
}



