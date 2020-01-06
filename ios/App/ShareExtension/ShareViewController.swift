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
            loaderVisualEffectView.isHidden = true
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
        label.paddingInsets = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()
    
    var model: SendModel?
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Layout success label
        successLabel.isHidden = true
        view.addSubview(successLabel)
        NSLayoutConstraint.activate([
            successLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            successLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        // ------- 🔨 Test Configs 🔨 -------
//        let config = Config(fromText: nil, subjectMode: SubjectMode.custom, subjectText: nil, token1: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InFzZEBxc2QuZnIiLCJpYXQiOjE1NzgwNjY4NDF9.5HGZC_8Lp6OX7p_ztLv7S5kyySg23kWte4XNL38oPyU", token2: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InFzZEBxc2QuZnIiLCJpYXQiOjE1NzgwNjY4NDF9.5HGZC_8Lp6OX7p_ztLv7S5kyySg23kWte4XNL38oPyU")
//        let config = Config(fromText: nil, subjectMode: SubjectMode.custom, subjectText: nil, token1: nil, token2: nil)
        // ------- 🔨 Test Configs 🔨 -------
        
        let config = ConfigReader.loadConfig()
        
        // There's no point going further if there's no registered email.
        guard config.hasAtLeastOneEmail else {
            showError(message: SendError.noValidEmail.localizedDescription)
            return
        }

        // Retrieve the attachments from the context. Those are what we're going to send.
        guard let item = self.extensionContext?.inputItems.first as? NSExtensionItem,
          let attachments = item.attachments
          else {
            completeRequest()
            return
        }
        
        // Prepare the model
        model = SendModel(attachments: attachments, config: config, onSendingCompleted: { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Sending is finished so we can hide the loader
                self.loaderVisualEffectView.isHidden = true
                
                switch result {
                case .success(()):
                    self.successLabel.isHidden = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        self.completeRequest()
                    }
                case .failure(let error):
                    self.showError(message: error.localizedDescription)
                }
            }
        })
        
        if config.hasMultipleEmails {
            // Show email Selector
            presentEmailSelector(with: config) { selectedTokenIndex in
                self.model?.selectedTokenIndex = selectedTokenIndex
                self.start()
            }
        } else {
            // Since there are only one email, we can start immediately.
            start()
        }
    }
    
    
    
    private func presentEmailSelector(with config: Config, completionHandler: @escaping ((Int) -> ())) {
        /*
         If there aren't multiple emails, we complete with an index of 0.
         Meaning that we leave this method while selecting the first email.
         */
        guard config.hasMultipleEmails else { completionHandler(0) ; return }
        
        let selectionSheet = UIAlertController(title: "Select email address", message: nil, preferredStyle: .actionSheet)
        
        config.emailTokens.enumerated().forEach({ index, token in
            selectionSheet.addAction(
                UIAlertAction(
                    title: token.email,
                    style: .default,
                    handler: { action in
                        // The user selected an email, we return its index in the `email tokens` array.
                        completionHandler(index)
                    }
                )
            )
        })
        
        selectionSheet.addAction(
            UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: { action in
                    // The user chose to "cancel". The only choice left is therefore to leave the extension.
                    self.completeRequest()
                }
            )
        )
        
        present(selectionSheet, animated: true, completion: nil)
    }
    
    private func start() {
        model?.start()
        
        loaderVisualEffectView.isHidden = false
        loaderVisualEffectView.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.loaderVisualEffectView.alpha = 1
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.completeRequest()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    
}
