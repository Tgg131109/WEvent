//
//  LinkLabel.swift
//  WEvent
//
//  Created by Toby Gamble on 2/28/22.
//

import UIKit

public protocol UILabelTapableLinksDelegate: NSObjectProtocol {
    func tapableLabel(_ label: UILabelTapableLinks, didTapUrl url: String, atRange range: NSRange)
}

public class UILabelTapableLinks: UILabel {

    private var links: [String: NSRange] = [:]
    private(set) var layoutManager = NSLayoutManager()
    private(set) var textContainer = NSTextContainer(size: CGSize.zero)
    private(set) var textStorage = NSTextStorage() {
        didSet {
            textStorage.addLayoutManager(layoutManager)
        }
    }

    public weak var delegate: UILabelTapableLinksDelegate?

    public override var attributedText: NSAttributedString? {
        didSet {
            if let attributedText = attributedText {
                textStorage = NSTextStorage(attributedString: attributedText)
                findLinksAndRange(attributeString: attributedText)
            } else {
                textStorage = NSTextStorage()
                links = [:]
            }
        }
    }

    public override var lineBreakMode: NSLineBreakMode {
        didSet {
            textContainer.lineBreakMode = lineBreakMode
        }
    }

    public override var numberOfLines: Int {
        didSet {
            textContainer.maximumNumberOfLines = numberOfLines
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        isUserInteractionEnabled = true
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines  = numberOfLines
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = bounds.size
    }

    private func findLinksAndRange(attributeString: NSAttributedString) {
        links = [:]
        let enumerationBlock: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void = { [weak self] value, range, isStop in
            guard let strongSelf = self else { return }
            if let value = value {
                let stringValue = "\(value)"
                strongSelf.links[stringValue] = range
            }
        }
        attributeString.enumerateAttribute(.link, in: NSRange(0..<attributeString.length), options: [.longestEffectiveRangeNotRequired], using: enumerationBlock)
        attributeString.enumerateAttribute(.attachment, in: NSRange(0..<attributeString.length), options: [.longestEffectiveRangeNotRequired], using: enumerationBlock)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let locationOfTouch = touches.first?.location(in: self) else {
            return
        }
        textContainer.size = bounds.size
        let indexOfCharacter = layoutManager.glyphIndex(for: locationOfTouch, in: textContainer)
        for (urlString, range) in links where NSLocationInRange(indexOfCharacter, range) {
            delegate?.tapableLabel(self, didTapUrl: urlString, atRange: range)
            return
        }
    }
}
