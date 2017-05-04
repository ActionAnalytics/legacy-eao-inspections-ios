//
//  ProjectListCell.swift
//  EAO
//
//  Created by Micha Volin on 2017-03-30.
//  Copyright © 2017 FreshWorks. All rights reserved.
//

class ProjectListCell: UITableViewCell{
	@IBOutlet var titleLabel: UILabel!
	
	func setData(title: NSAttributedString?){
		self.titleLabel.attributedText = title
	}
}
