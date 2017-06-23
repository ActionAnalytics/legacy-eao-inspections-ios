//
//  LoginController.swift
//  EAO
//
//  Created by Micha Volin on 2017-04-07.
//  Copyright © 2017 FreshWorks. All rights reserved.
//
import Parse
import Alamofire
///This enum represents errors that might occur during log in
enum LoginError: Error{
	case noUsername
	case noPassword
	var message: String{
		switch self {
		case .noUsername:
			return "Please enter registered username"
		case .noPassword:
			return "Please enter password"
		}
	}
}
//MARK: -
final class LoginController: UIViewController{
	//MARK: IB Outleys
	@IBOutlet fileprivate var usernameField: UITextField!
	@IBOutlet fileprivate var passwordField: UITextField!
	@IBOutlet fileprivate var scrollView: UIScrollView!
	@IBOutlet fileprivate var indicator: UIActivityIndicatorView!
	//MARK: IB Actions
	@IBAction fileprivate func loginTapped(_ sender: UIButton) {
		do{
			let credentials = try validateCredentials()
			if !Reachability.isConnectedToNetwork(){
				present(controller: UIAlertController.noInternet)
				return
			}
			sender.isEnabled = false
			indicator.startAnimating()
			PFUser.logInWithUsername(inBackground: credentials.0, password: credentials.1) { (user, error) in
				guard let _ = user, error == nil else{
					let code = (error! as NSError).code
					switch code{
					case 101:
						self.present(controller: UIAlertController(title: "Couldn't log in", message: "Entered credentials are not valid"))
					default:
						self.present(controller: UIAlertController(title: "Couldn't log in", message: "Error code is \(code)"))
					}
					sender.isEnabled = true
					self.indicator.stopAnimating()
					return
				}
				PFInspection.loadAndPin {
					self.load(completion: {
						self.clearTextFields()
						self.present(controller: InspectionsController.storyboardInstance())
						self.indicator.stopAnimating()
						sender.isEnabled = true
					})
				}
			}
		} catch{
			self.present(controller: UIAlertController(title: "Couldn't log in", message: (error as? LoginError)?.message))
		}
	}

	@IBAction fileprivate func forgotPasswordTapped(_ sender: UIButton) {
		present(controller: UIAlertController(title: "Please contact Geoff McDonald to change your user credentials.", message: nil))
	}

	@IBAction fileprivate func signupTapped(_ sender: UIButton) {
		present(controller: UIAlertController(title: "This feature is not available yet", message: nil))
	}

	//MARK: Initialization
	override func viewDidLoad() {
		addDismissKeyboardOnTapRecognizer(on: scrollView)
		perform(#selector(presentMainScreen), with: nil, afterDelay: 0)
	}

	func presentMainScreen(){
		if PFUser.current() != nil{
			clearTextFields()
			let inspectionsController = InspectionsController.storyboardInstance()
			self.present(controller: inspectionsController)
		}
	}

	///This function caches projects on every login
	fileprivate func load(completion: @escaping ()->()){
		Alamofire.request(String.projects_API).responseJSON { response in
			guard let objects = response.result.value as? [Any] else{
				completion()
				return
			}
			var projects = [String?]()
			for case let object as [String: Any] in objects {
				guard let title = object[.name] as? String else { continue }
				projects.append(title)
			}
			let array = NSArray(array: projects.flatMap({$0}))
			array.write(to: FileManager.directory.appendingPathComponent(.projects), atomically: true)
			completion()
		}
	}
}

extension LoginController{
	fileprivate func clearTextFields(){
		self.usernameField.text = ""
		self.passwordField.text = ""
	}
}

//MARK: - Validation
extension LoginController{
	///Return: (Username, Password)
	func validateCredentials() throws -> (String,String){
		guard let username = usernameField.text?.trimWhiteSpace(), !username.isEmpty() else {
			throw LoginError.noUsername
		}
		guard let password = passwordField.text?.trimWhiteSpace(), !password.isEmpty() else {
			throw LoginError.noPassword
		}
		return (username, password)
	}
}

//MARK: - UITextFieldDelegate
extension LoginController: UITextFieldDelegate{
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		dismissKeyboard()
		return true
	}
}



