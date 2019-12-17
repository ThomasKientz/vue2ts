//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Clément Cardonnel on 06/12/2019.
//

import UIKit

class ShareViewController: UIViewController {
    
    // MARK: - Properties

    @IBOutlet private weak var loaderVisualEffectView: UIVisualEffectView! {
        didSet {
            loaderVisualEffectView.layer.cornerRadius = 10
            loaderVisualEffectView.clipsToBounds = true
        }
    }
    
    private lazy var successLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textColor = .white
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 1
        label.text = "Boomerang sent!"
        label.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        label.paddingInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()
    
    var model: SendModel?
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        successLabel.isHidden = true
        view.addSubview(successLabel)
        NSLayoutConstraint.activate([
            successLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        guard let item = self.extensionContext?.inputItems.first as? NSExtensionItem,
          let attachments = item.attachments
          else {
            return
        }
        
        model = SendModel(attachments: attachments, onSendingCompleted: { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Sending is finished so we can hide the loader
                self.loaderVisualEffectView.isHidden = true
                
                switch result {
                case .success(()):
                    self.successLabel.isHidden = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                    }
                case .failure(let error):
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        })
    }
    
    
}
