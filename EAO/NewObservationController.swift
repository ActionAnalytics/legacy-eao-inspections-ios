//
//  ObservationElementController.swift
//  EAO
//
//  Created by Micha Volin on 2017-03-30.
//  Copyright © 2017 FreshWorks. All rights reserved.
//
import Parse
import MapKit

final class NewObservationController: UIViewController{
	let maximumNumberOfPhotos = 20
	fileprivate var locationManager = CLLocationManager()
	var saveAction  : ((PFObservation)->Void)?
	var inspection  : PFInspection!
	var observation : PFObservation!
	var photos		: [PFPhoto]?
	var didMakeChange = false

	//MARK: -
	@IBOutlet fileprivate var arrow_0: UIImageView!
	@IBOutlet fileprivate var descriptionTextView: UITextView!
	@IBOutlet fileprivate var indicator: UIActivityIndicatorView!
	@IBOutlet fileprivate var scrollView : UIScrollView!
	@IBOutlet fileprivate var titleTextField: UITextField!
	@IBOutlet fileprivate var requirementTextField: UITextField!
	@IBOutlet fileprivate var GPSLabel: UIButton!
	@IBOutlet fileprivate var collectionViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet fileprivate var collectionView: UICollectionView!
	@IBOutlet fileprivate var descriptionButton: UIButton!

	//MARK: -
	@IBAction func addVoiceTapped(_ sender: UIButton) {
		present(controller: UIAlertController(title: "This feature is coming soon", message: nil))
	}

	@IBAction func addVideoTapped(_ sender: UIButton) {
		present(controller: UIAlertController(title: "This feature is coming soon", message: nil))
	}

	@IBAction func backTapped(_ sender: UIBarButtonItem) {
		if isReadOnly{
			pop()
			return
		}
		if didMakeChange{
			present(controller: UIAlertController(title: "Would you like to save this observation element?", message: nil, yes: {
				self.saveTapped(sender)
			}, cancel: {
				self.pop()
			}))
		} else{
			pop()
		}
	}

	@IBAction fileprivate func saveTapped(_ sender: UIBarButtonItem) {
		if !validate() { return }
		indicator.startAnimating()
		saveAction?(self.observation)
		observation.title = titleTextField.text
		observation.requirement = requirementTextField.text
		observation.observationDescription = descriptionTextView.text
		if observation.coordinate == nil{
			observation.coordinate = PFGeoPoint(location: locationManager.location)
		}
		if observation.inspectionId == nil{
			observation.inspectionId = inspection.id
		}
		if observation.id == nil{
			observation.id = UUID().uuidString
		}
		observation.pinInBackground { (success, error) in
			if success && error == nil{
				if self.observation.pinnedAt == nil{
					self.observation.pinnedAt = Date()
				}
				_ = self.navigationController?.popViewController(animated: true)
			} else{
				AlertView.present(on: self, with: "Error occured while saving inspection to local storage")
			}
			self.indicator.stopAnimating()
		}
	}
 
	@IBAction func descriptionTapped(_ sender: UIButton) {
		let textViewController = TextViewController.storyboardInstance() as! TextViewController
		if self.descriptionTextView.text != "Tap to enter description"{
			textViewController.initialText = self.descriptionTextView.text
		}
		textViewController.title = "Element Description"
		textViewController.result = { (text) in
			if self.descriptionTextView.text == "Tap to enter description"{
				if let text = text, !text.isEmpty(){

					self.descriptionTextView.text = text
				}
			} else{
				if let text = text,!text.isEmpty() {
					self.descriptionTextView.text = text
				} else{

					self.descriptionTextView.text = "Tap to enter description"
				}
			}
		}
		push(controller: textViewController)
	}
	
	@IBAction fileprivate func addPhotoTapped(_ sender: UIButton) {
		if photos?.count == maximumNumberOfPhotos{
			present(controller: UIAlertController(title: "You've reached maximum number of photos per element", message: nil))
			return
		}
		sender.isEnabled = false
		if observation.id == nil{
			observation.id = UUID().uuidString
		}
		let uploadPhotoController = UploadPhotoController.storyboardInstance() as! UploadPhotoController
		uploadPhotoController.observation = observation
		uploadPhotoController.uploadPhotoAction = { (photo) in
			if let photo = photo{
				self.didMakeChange = true
				if self.photos == nil{
					self.photos = []
				}
				self.photos?.append(photo)
			}
			self.collectionViewHeightConstraint.constant = self.getConstraintHeight()
			self.view.layoutIfNeeded()
			self.collectionView.reloadData()
		}
		push(controller: uploadPhotoController)
		sender.isEnabled = true
	}
	
	//MARK: -
	override func viewDidLoad() {
		addDismissKeyboardOnTapRecognizer(on: scrollView)
		populate()
		if observation == nil{
			observation = PFObservation()
		}
		if isReadOnly{
			navigationItem.rightBarButtonItem = nil
			titleTextField.isEnabled = false
			requirementTextField.isEnabled = false
			descriptionButton.isEnabled = false
			arrow_0.isHidden = true
			view.addConstraint(NSLayoutConstraint(item: descriptionTextView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60))

		} else{
			view.addConstraint(NSLayoutConstraint(item: descriptionTextView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60))
		}
		view.layoutIfNeeded()
		GPSLabel.setTitle("GPS: \(observation?.coordinate?.toString() ?? locationManager.coordinateAsString() ?? "unavailable")", for: .normal)
	}

	//MARK: -
	fileprivate func populate(){
		guard let observation = observation else {
			self.photos = []
			self.collectionViewHeightConstraint.constant = Constants.cellWidth
			self.view.layoutIfNeeded()
			return
		}
		indicator.startAnimating()
		titleTextField.text = observation.title
		requirementTextField.text = observation.requirement
		descriptionTextView.text = observation.observationDescription
		loadPhotos()
	}
	
	fileprivate func loadPhotos(){
		guard let query = PFPhoto.query() else{
			indicator.stopAnimating()
			return
		}
		query.fromLocalDatastore()
		query.whereKey("observationId", equalTo: observation.id!)
		query.findObjectsInBackground(block: { (photos, error) in
			guard let photos = photos as? [PFPhoto], error == nil else {
				self.indicator.stopAnimating()
				AlertView.present(on: self, with: "Couldn't retrieve observation photos")
				return
			}
			if self.photos == nil{
				self.photos = []
			}
			for photo in photos{
				if let id = photo.id{
					let url = URL(fileURLWithPath: FileManager.directory.absoluteString).appendingPathComponent(id, isDirectory: true)
					photo.image = UIImage(contentsOfFile: url.path)
					self.photos?.append(photo)
				}
			}
			self.collectionViewHeightConstraint.constant = self.getConstraintHeight()
			self.view.layoutIfNeeded()
			self.collectionView.reloadData()
			self.indicator.stopAnimating()
		})
	}
	
	fileprivate func getConstraintHeight()->CGFloat{
		guard let photosCount = photos?.count else { return 0 }
		if photosCount == 0{
			return Constants.cellWidth
		}
		var numberOfRows = Double(photosCount+(isReadOnly ? 0 :1))
		numberOfRows	/= Double(Constants.itemsPerRow)
		numberOfRows	 = ceil(numberOfRows)
		var height = CGFloat(numberOfRows)
		height	  *= Constants.cellWidth
		height    += CGFloat(numberOfRows-1)*5
		return height
	}
}


extension NewObservationController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
	private func photoCell(indexPath: IndexPath) -> UICollectionViewCell{
		let cell = collectionView.dequeue(identifier: "PhotoCell", indexPath: indexPath) as! ObservationElementPhotoCell
		cell.setData(image: photos?[indexPath.row].image)
		return cell
	}
	
	private func addNewtPhotoCell(indexPath: IndexPath) -> UICollectionViewCell{
		let cell = collectionView.dequeue(identifier: "AddNewPhotoCell", indexPath: indexPath) as! ObservationElementAddNewPhotoCell
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if isReadOnly{
			return photos?.count ?? 0
		}
		return photos == nil ? 0 : photos!.count + 1
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if indexPath.row == photos?.count && !isReadOnly{
			return addNewtPhotoCell(indexPath: indexPath)
		}
		return photoCell(indexPath: indexPath)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if indexPath.row == photos?.count{
			return
		}
		let uploadPhotoController = UploadPhotoController.storyboardInstance() as! UploadPhotoController
		uploadPhotoController.isReadOnly = inspection.isSubmitted?.boolValue ?? false
		uploadPhotoController.observation = observation
		uploadPhotoController.photo = photos?[indexPath.row]
		push(controller: uploadPhotoController)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: Constants.cellWidth, height: Constants.cellWidth)
	}
}

extension NewObservationController{
	var isReadOnly: Bool{
		return inspection.isSubmitted?.boolValue == true
	}
}

extension NewObservationController: UITextFieldDelegate{
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}

	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		didMakeChange = true
		var length = textField.text?.characters.count ?? 0
		length += string.characters.count
		length -= range.length
		return length < EAO.Constants.textFieldLenght
	}
}

extension NewObservationController{
	fileprivate func validate() ->Bool{
		if titleTextField.text?.isEmpty() == true{
			present(controller: Alerts.fields)
			return false
		}
		if requirementTextField.text?.isEmpty() == true {
			present(controller: Alerts.fields)
			return false
		}
		if descriptionTextView.text == "Tap to enter description"{
			present(controller: Alerts.fields)
			return false
		}
		return true
	}
}

extension NewObservationController{
	enum Alerts{
		static let fields = UIAlertController(title: "All Fields Required", message: "Please fill out 'Title', 'Requirement', and 'Description' fields")
	}
}

extension NewObservationController{
	enum Constants{
		static let cellWidth = (UIScreen.width-25)/CGFloat(Constants.itemsPerRow)
		static let itemsPerRow = 4
	}
}





