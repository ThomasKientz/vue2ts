//
//  PaddingLabel.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 17/12/2019.
//
// Thanks to: https://stackoverflow.com/a/32368958/4802021

import UIKit

@IBDesignable class PaddingLabel: UILabel {

    @IBInspectable var paddingInsets: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: paddingInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + paddingInsets.left + paddingInsets.right,
                      height: size.height + paddingInsets.top + paddingInsets.bottom)
    }
}
