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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  @IBOutlet weak var imageViewOutlet: UIImageView!
  @IBOutlet weak var label: UILabel!
  
  let wikipediaURl = "https://en.wikipedia.org/w/api.php"
  let imagePicker = UIImagePickerController()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    imagePicker.delegate = self
    
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    if let userPickedImage = info[.editedImage] as? UIImage {
      imageViewOutlet.image = userPickedImage
      imagePicker.dismiss(animated: true, completion: nil)
      
      guard let ciImage = CIImage(image: userPickedImage) else {
        fatalError("Could not convert UIImage to CIImage")
      }
      detect(image: ciImage)
    }
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
    
    let parameters : [String:String] = [
      "format" : "json",
      "action" : "query",
      "prop" : "extracts",
      "exintro" : "",
      "explaintext" : "",
      "titles" : flowerName,
      "indexpageids" : "",
      "redirects" : "1",
      ]
    
    Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
      if response.result.isSuccess {
        print(JSON(response.result.value!))
        
        let flowerJSON : JSON = JSON(response.result.value!)
        let pageid = flowerJSON["query"]["pageids"][0].stringValue
        let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
        self.label.text = flowerDescription
      }
    }
  }


  @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
    
    imagePicker.allowsEditing = true
    imagePicker.sourceType = .camera
    present(imagePicker, animated: true, completion: nil)
  }
}

