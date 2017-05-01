//
//  UIViewController.swift
//  Vmee
//
//  Created by Micha Volin on 2016-12-18.
//  Copyright © 2016 Vmee. All rights reserved.
//
 
extension UIViewController{
   
   
   ///Make sure storyboard file has same name as the class name
   public static func storyboardInstance() -> UIViewController?{
      let storyboard = UIStoryboard(name: String(describing: self), bundle: Bundle(for: self))
      let controller = storyboard.instantiateInitialViewController()
      return controller
   }
   
   public func present(controller: UIViewController?){
      
      guard let controller = controller else{
         return
      }
      
      present(controller, animated: true, completion: nil)
   }
 
   ///Adds tap gesture recognizer to root view that dismissess keyboard on tap
    public func addDismissKeyboardOnTapRecognizer(on view: UIView){
        let tapRec = UITapGestureRecognizer()
        tapRec.cancelsTouchesInView = false
        tapRec.addTarget(self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapRec)
    }
   
   public func dismissKeyboard(){
      view.endEditing(true)
   }
    
   
   
}


extension UIViewController{
	public func push(controller: UIViewController?){
		if let controller = controller{
			navigationController?.pushViewController(controller, animated: true)
		}
	}
	
	public func pop(){
		_ = navigationController?.popViewController(animated: true)
	}
}







