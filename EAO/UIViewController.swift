//
//  UIViewController.swift
//  EAO
//
//  Created by Micha Volin on 2017-05-15.
//  Copyright © 2017 FreshWorks. All rights reserved.
//

extension UIViewController{
	func showSuccessImageView(){
		let imageView = UIImageView()
		imageView.image = #imageLiteral(resourceName: "icon_success")
		imageView.alpha = 0
		imageView.frame.size = CGSize(width: 128, height: 128)
		imageView.center = CGPoint(x: view.frame.width/2, y: view.frame.height/2)
		view.addSubview(imageView)
		UIView.animate(withDuration: 0.25, animations: {
			imageView.alpha = 1
		}) { (_) in
			UIView.animate(withDuration: 0.1, delay: 0.3, options: .curveLinear, animations: {
				imageView.alpha = 0
			}, completion: { (_) in
				imageView.removeFromSuperview()
			})
		}
	}
	///sets navigationItem right bar button as 'eye' image for read only mode.
	func setNavigationRightItemAsEye(){
		navigationItem.rightBarButtonItem = UIBarButtonItem(customView: UIImageView(image: #imageLiteral(resourceName: "icon_eye")))
	}
	
	 
}
