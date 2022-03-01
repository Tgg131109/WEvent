//
//  CustomTextField.swift
//  WEvent
//
//  Created by Toby Gamble on 2/28/22.
//

import Foundation
import UIKit

class CustomTextField : UITextField {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.layer.cornerRadius = 6
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor(red: 194/255, green: 231/255, blue: 250/255, alpha: 1).cgColor
        self.layer.masksToBounds = true
    }
}

class CustomImageView : UIImageView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.layer.cornerRadius = self.layer.bounds.height / 2
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1).cgColor
    }
}

class CustomShadowView : UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.layer.cornerRadius = self.layer.bounds.height / 2
        self.layer.shadowColor = UIColor.systemGray.cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 3
        self.layer.masksToBounds = false
    }
}
