//
//  UITableView.swift
//  Vmee
//
//  Created by Micha Volin on 2017-01-29.
//  Copyright © 2017 Vmee. All rights reserved.
//

extension UITableView{
   
   public func register(nibName:String){
      let nib = UINib(nibName: nibName, bundle: nil)
      register(nib, forCellReuseIdentifier: nibName)
   }
   
   
   public func dequeue(identifier: String) -> UITableViewCell?{
      return dequeueReusableCell(withIdentifier: identifier)
   }
   
}
