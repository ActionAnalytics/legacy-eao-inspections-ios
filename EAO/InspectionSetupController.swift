//
//  InspectionSetupController.swift
//  EAO
//
//  Created by Micha Volin on 2017-03-30.
//  Copyright © 2017 FreshWorks. All rights reserved.
//
import Parse
final class InspectionSetupController: UIViewController{
	var inspection: PFInspection?

	fileprivate var isNew = false
	fileprivate var dates = [String: Date]()
	
	//MARK: - IB Outlets
	@IBOutlet fileprivate var button	 : UIButton!
	@IBOutlet fileprivate var indicator  : UIActivityIndicatorView!
	@IBOutlet fileprivate var scrollView : UIScrollView!
	@IBOutlet fileprivate var linkProjectButton : UIButton!
	@IBOutlet fileprivate var titleTextField	: UITextField!
	@IBOutlet fileprivate var subtitleTextField : UITextField!
	@IBOutlet fileprivate var subtextTextField  : UITextField!
	@IBOutlet fileprivate var numberTextField   : UITextField!
	@IBOutlet fileprivate var startDateButton   : UIButton!
	@IBOutlet fileprivate var endDateButton     : UIButton!
	
	@IBOutlet fileprivate var arrow_1: UIImageView!
	@IBOutlet fileprivate var arrow_2: UIImageView!
	@IBOutlet fileprivate var arrow_3: UIImageView!
 
	//MARK: - IB Actions
	@IBAction fileprivate func linkProjectTapped(_ sender: UIButton) {
		let projectListController = ProjectListController.storyboardInstance() as! ProjectListController
		projectListController.result = { (title) in
			guard let title = title else { return }
			self.navigationItem.rightBarButtonItem?.isEnabled = true
			sender.setTitle(title, for: .normal)
		}
		push(controller: projectListController)
	}
	
	//sender: tag 10 is start date button, tag 11 is end date button
	@IBAction fileprivate func dateTapped(_ sender: UIButton) {
		DatePickerController.present(on: self, minimum: nil) { [weak self] (date) in
			guard let date = date else { return }
			self?.navigationItem.rightBarButtonItem?.isEnabled = true
			sender.setTitle(date.datePickerFormat(), for: .normal)
			self?.dates[sender.tag == 10 ? "start" : "end"] = date
		}
	}
	
	@IBAction fileprivate func saveTapped(_ sender: UIControl) {
		sender.isEnabled = false
		indicator.startAnimating()
		validate { (inspection) in
			guard let inspection = inspection else {
				sender.isEnabled = true
				self.indicator.stopAnimating()
				return
			}
			inspection.isSubmitted = false
			inspection.pinInBackground(block: { (success, error) in
				guard success, error == nil else{
					self.indicator.stopAnimating()
					sender.isEnabled = true
					self.present(controller: UIAlertController(title: "ERROR!", message: "Inspection failed to save"))
					return
				}
				if self.isNew{
					Notification.post(name: .insertByDate, inspection)
				} else{
					Notification.post(name: .reload)
				}
				if self.isNew{
					self.isNew = false
					let inspectionFormController = InspectionFormController.storyboardInstance() as! InspectionFormController
					inspectionFormController.inspection = inspection
					if inspection.id != nil {
						inspectionFormController.submit = {
							if let index = InspectionsController.reference?.inspections[0]?.index(of: inspection){
								InspectionsController.reference?.submit(inspection: self.inspection!, indexPath: IndexPath(row: index, section: 0))
							}
						}
						self.push(controller: inspectionFormController)
						self.navigationController?.viewControllers.remove(at: 1)
						self.setMode()
					}
				}
				self.indicator.stopAnimating()
				self.showSuccessImageView()
			})
		}
	}

	//MARK: -
	override func viewDidLoad() {
		addDismissKeyboardOnTapRecognizer(on: scrollView)
		if inspection == nil{
			subtextTextField.text = PFUser.current()?.username
			isNew = true
		} else{
			button.isHidden = true
		}
		setMode()
		populate()
	}

	override func viewDidAppear(_ animated: Bool) {
		addKeyboardObservers()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		removeKeyboardObservers()
	}
	
	fileprivate func setMode(){
		if isReadOnly{
			linkProjectButton.isEnabled = false
			titleTextField.isEnabled    = false
			subtitleTextField.isEnabled = false
			subtextTextField.isEnabled  = false
			numberTextField.isEnabled   = false
			startDateButton.isEnabled   = false
			endDateButton.isEnabled     = false
			navigationItem.rightBarButtonItem = nil
			arrow_1.isHidden = true
			arrow_2.isHidden = true
			arrow_3.isHidden = true 
		} else if isNew{
			//new
			navigationItem.rightBarButtonItem = nil
		} else{
			//modifying
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped(_:)))
			navigationItem.rightBarButtonItem?.isEnabled = false
		}
	}
	
	//MARK: -
	func populate(){
		guard let inspection = inspection else { return }
		linkProjectButton.setTitle(inspection.project, for: .normal)
		startDateButton.setTitle(inspection.start?.datePickerFormat(), for: .normal)
		endDateButton.setTitle(inspection.end?.datePickerFormat() ?? "Inspection End Date", for: .normal)
		titleTextField.text = inspection.title
		subtitleTextField.text = inspection.subtitle
		subtextTextField.text = inspection.subtext
		numberTextField.text = inspection.number
		dates["start"] = inspection.start
		dates["end"] = inspection.end
	}
}

//MARK: -
extension InspectionSetupController: KeyboardDelegate{
	func keyboardWillShow(with height: NSNumber) {
		scrollView.contentInset.bottom = CGFloat(height)
	}
	func keyboardWillHide() {
		scrollView.contentInset.bottom = 0
	}
}


//MARK: -
extension InspectionSetupController: UITextFieldDelegate{
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		navigationItem.rightBarButtonItem?.isEnabled = true
		var length = textField.text?.characters.count ?? 0
		length += string.characters.count
		length -= range.length
		return length < Constants.textFieldLenght
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}

//MARK: -
extension InspectionSetupController{
	func validate(completion: @escaping (_ inspection : PFInspection?)->Void){
		if linkProjectButton.title(for: .normal) == "Link Project" || titleTextField.text?.isEmpty() == true || subtitleTextField.text?.isEmpty() == true || subtextTextField.text?.isEmpty() == true || numberTextField.text?.isEmpty() == true || dates["start"] == nil{
			present(controller: Alerts.fields)
			completion(nil)
			return
		}
		if !validateDates() {
			present(controller: Alerts.dates)
			completion(nil)
			return
		}
		if self.isNew {
			inspection = PFInspection()
			inspection?.userId = PFUser.current()?.objectId
			inspection?.id = UUID().uuidString

		}
		inspection?.project = linkProjectButton.title(for: .normal)
		inspection?.title = titleTextField.text
		inspection?.subtitle = subtitleTextField.text
		inspection?.subtext = subtextTextField.text
		inspection?.number = numberTextField.text
		inspection?.start = dates["start"]
		inspection?.end = dates["end"]
		completion(inspection)
	}
	
	func validateDates() -> Bool{
		guard let startDate = dates["start"],
			let endDate = dates["end"] else {
			return dates["start"] != nil
		}
		return startDate <= endDate
	}
}

//MARK: -
extension InspectionSetupController{
	fileprivate var isReadOnly: Bool{
		return inspection?.isSubmitted?.boolValue == true
	}
}

//MARK: -
extension InspectionSetupController{
	struct Alerts{
		static let fields = UIAlertController(title: "Incomplete", message: "Please fill out all fields")
		static let dates = UIAlertController(title: "Dates", message: "Please make sure end date goes after start date")
		static let error = UIAlertController(title: "ERROR!", message: "Inspection failed to be saved,\nPlease try again")
	}
}





