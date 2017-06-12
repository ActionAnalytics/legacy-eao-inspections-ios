//
//  UploadPhotoController.swift
//  EAO
//
//  Created by Micha Volin on 2017-03-15.
//  Copyright © 2017 FreshWorks. All rights reserved.
//
import MapKit
import Parse
class UploadPhotoController: UIViewController, KeyboardDelegate{
	var isReadOnly = false
	var photo: PFPhoto!
	var observation: PFObservation!
	var uploadPhotoAction: ((_ photo: PFPhoto?)-> Void)?
    fileprivate var locationManager = CLLocationManager()
	fileprivate var date: Date?{
		didSet{
			timestampLabel.text = date?.timeStampFormat()
		}
	}
	fileprivate var location: CLLocation?{
		didSet{
			gpsLabel.text = locationManager.coordinateAsString() ?? "unavailable"
		}
	}
	//MARK: -
	@IBOutlet fileprivate var indicator: UIActivityIndicatorView!
    @IBOutlet fileprivate var scrollView: UIScrollView!
    @IBOutlet fileprivate var timestampLabel: UILabel!
    @IBOutlet fileprivate var gpsLabel: UILabel!
    @IBOutlet fileprivate var imageView: UIImageView!
    @IBOutlet fileprivate var uploadButton : UIButton!
    @IBOutlet fileprivate var uploadLabel  : UILabel!
	@IBOutlet fileprivate var captionTextView: UITextView!
	
	//MARK: -
    @IBAction fileprivate func save(_ sender: UIBarButtonItem) {
		if !validate() { return }
		sender.isEnabled = false
		indicator.startAnimating()
		if photo == nil{
			photo = PFPhoto()
		} else {
			photo.caption = captionTextView.text
			photo.pinInBackground(block: { (success, error) in
				if success && error == nil{
					_ = self.navigationController?.popViewController(animated: true)
				} else{
					AlertView.present(on: self, with: "Error occured while updating caption text")
					self.indicator.stopAnimating()
					sender.isEnabled = true
				}
			})
			return
		}
		if photo.observationId == nil{
			photo.observationId = observation.id 
		}
		if photo.id == nil{
			photo.id = UUID().uuidString
		}
		photo.caption = captionTextView.text
		photo.timestamp = date
		photo.coordinate = PFGeoPoint(location: location)
		if let data = imageView.image?.scale(width: UIScreen.width)?.toData(quality: .medium){
			photo.image = UIImage(data: data)
			do{
				try data.write(to: FileManager.directory.appendingPathComponent(photo.id!, isDirectory: true))
				photo.pinInBackground { (success, error) in
					if success && error == nil{
						self.uploadPhotoAction?(self.photo)
						_ = self.navigationController?.popViewController(animated: true)
					} else{
						AlertView.present(on: self, with: "Error occured while saving image to local storage")
					}
					self.indicator.stopAnimating()
					sender.isEnabled = true
				}
			} catch {
				AlertView.present(on: self, with: "Error occured while saving image to local storage")
				self.indicator.stopAnimating()
				sender.isEnabled = true
			}
		} else{
			AlertView.present(on: self, with: "Error occured while compressing image")
			self.indicator.stopAnimating()
			sender.isEnabled = true
		}
    }
    
    @IBAction fileprivate func photoTapped(_ sender: UIButton) {
        let alert = cameraOptionsController()
        present(controller: alert)
    }
    
    //MARK: -
    override func viewDidLoad() {
        addDismissKeyboardOnTapRecognizer(on: view)
		populate()
		if isReadOnly{
			navigationItem.rightBarButtonItem = nil
			uploadButton.isEnabled = false
			uploadButton.alpha = 0
			uploadLabel.alpha = 0
			captionTextView.isEditable = false
		}
    }

	override func viewDidAppear(_ animated: Bool) {
		addKeyboardObservers()
	}

	override func viewWillDisappear(_ animated: Bool) {
		removeKeyboardObservers()
	}

	func keyboardWillShow(with height: NSNumber) {
		scrollView.contentInset.bottom = CGFloat(height.intValue + 40)
	}

	func keyboardWillHide() {
		scrollView.contentInset.bottom = 0
	}

	//MARK: -
	fileprivate func populate(){
		guard let photo = photo else { return }
		uploadButton.isEnabled = false
		uploadButton.alpha = 0
		uploadLabel.alpha = 0
		indicator.startAnimating()
		if let id = photo.id{
			let url = URL(fileURLWithPath: FileManager.directory.absoluteString).appendingPathComponent(id, isDirectory: true)
			imageView.image = UIImage(contentsOfFile: url.path)
		}
		captionTextView.text = photo.caption
		timestampLabel.text = photo.timestamp?.timeStampFormat()
		gpsLabel.text = photo.coordinate?.toString()
		indicator.stopAnimating()
	}
}

 
//MARK: -
extension UploadPhotoController{
	fileprivate func validate()->Bool{
		if imageView.image == nil{
			present(controller: Alerts.error)
			return false
		}
		return true
	}
}

extension UploadPhotoController: UITextViewDelegate{
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		var length = textView.text?.characters.count ?? 0
		length += text.characters.count
		length -= range.length
		return length < EAO.Constants.textViewLenght
	}
}

//MARK: -
extension UploadPhotoController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
			imageView.image = image
            uploadButton.alpha = 0.25
            uploadLabel.alpha = 0
			date = Date()
			location = locationManager.location
        }
		 self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func media(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true, completion: nil)
    }
}

//MARK: -
extension UploadPhotoController{
    fileprivate func cameraOptionsController() -> UIAlertController{
        let alert   = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Take Picture", style: .default, handler: { (_) in
            self.media(sourceType: .camera)
        })
        let library = UIAlertAction(title: "Photo Library", style: .default, handler: { (_) in
            self.media(sourceType: .photoLibrary)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addActions([camera,library,cancel])
        return alert
    }
}

//MARK: -
extension UploadPhotoController{
	struct Alerts{
		static let error = UIAlertController(title: "Picture Required", message: "Please provide a picture to save")
	}
}









