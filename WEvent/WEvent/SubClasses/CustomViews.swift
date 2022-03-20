//
//  CustomTextField.swift
//  WEvent
//
//  Created by Toby Gamble on 2/28/22.
//

import Foundation
import UIKit

class FloatingLabel: UILabel {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.layer.cornerRadius = 4
        self.layer.masksToBounds = true
    }
}

class CustomTextField: UITextField {
//    private var __maxLengths = [UITextField: Int]()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.layer.cornerRadius = 6
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor(red: 194/255, green: 231/255, blue: 250/255, alpha: 1).cgColor
        self.layer.masksToBounds = true
    }
    
//    @IBInspectable var maxLength: Int {
//        get {
//            guard let l = __maxLengths[self]
//            else {
//                return 150 // (global default-limit. or just, Int.max)
//            }
//            
//            return l
//        }
//        
//        set {
//            __maxLengths[self] = newValue
//            addTarget(self, action: #selector(fix), for: .editingChanged)
//        }
//    }
//    
//    @objc func fix(textField: UITextField) {
//        if let str = textField.text?.prefix(maxLength) {
//            let range = NSRange(location: 0, length: textField.text!.count)
//
//            print("\(str.count) | \(range.length)")
//            guard range.length <= str.count
//            else {
//                textField.text = String(textField.text!.dropLast(1))
//                print(textField.text?.count)
//                return
//            }
//            
//            textField.text = String(str)
//        }
//    }
}

class CustomImageView: UIImageView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.layer.cornerRadius = self.layer.bounds.height / 2
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor(red: 238/255, green: 106/255, blue: 68/255, alpha: 1).cgColor
    }
}

class CustomShadowView: UIView {
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

class CustomActivityIndicatorView: UIView {
    
//    @IBOutlet weak var activityIndicator: CustomActivityIndicator!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLbl: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        
        // Create a blur effect to be applied to view when gameOverView is displayed.
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.insertSubview(blurEffectView, at: 0)
    }
}

//class CustomActivityIndicator: UIView {
//
//    let icon1 = UIImageView()
//    let icon2 = UIImageView()
//    let icon3 = UIImageView()
//
//    var icons = [UIImageView]()
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder:aDecoder)
//
//        for icon in icons {
//            icon.image = UIImage(named: "logo_stamp")
//        }
//
//        icons = [icon1, icon2, icon3]
//    }
//
//    func startAnimating() {
//        var delay: Double = 0
//
//        for icon in icons {
//            animateIcon(icon, delay: delay)
//            delay += 0.95
//        }
//    }
//
//    func stopAnimating() {
//        for icon in icons {
//            icon.stopAnimating()
//        }
//    }
//
//    func animateIcon(_ icon: UIImageView, delay: Double) {
//        UIImageView.animate(withDuration: 0.8, delay: delay, options: .curveLinear, animations: {
//            icon.alpha = 1
//            icon.frame = CGRect(x: 35, y: 5, width: 30, height: 30)
//        }) { (completed) in
//            UIImageView.animate(withDuration: 0.8, delay: delay, options: .curveLinear, animations: {
//                icon.frame = CGRect(x: 85, y: 5, width: 30, height: 30)
//            }) { (completed) in
//                UIImageView.animate(withDuration: 0.8, delay: delay, options: .curveLinear, animations: {
//                    icon.alpha = 0
//                    icon.frame = CGRect(x: 140, y: 5, width: 30, height: 30)
//                }) { (completed) in
//                    icon.frame = CGRect(x: -20, y: 5, width: 30, height: 30)
//                    self.animateIcon(icon, delay: 0)
//                }
//            }
//        }
//    }
//}
