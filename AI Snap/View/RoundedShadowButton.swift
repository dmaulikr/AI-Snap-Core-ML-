//
//  RoundedShadowButton.swift
//  AI Snap
//
//  Created by Timothy Barrett on 7/16/17.
//  Copyright © 2017 Timothy Barrett. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedShadowButton: UIButton {

  override func prepareForInterfaceBuilder() {
    
    createModifiedView()
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    createModifiedView()
  }
  
  func createModifiedView() {
    layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1).cgColor
    layer.shadowRadius = 15
    layer.shadowOpacity = 0.75
    layer.cornerRadius = frame.height / 2
  }
}
