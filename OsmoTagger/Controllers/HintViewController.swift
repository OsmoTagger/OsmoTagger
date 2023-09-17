//
//  HintViewController.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 17.09.2023.
//

import UIKit

class HintViewController: UIViewController {
    
    var hint: String
    
    let label = UILabel()
    
    init(hint: String) {
        self.hint = hint
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let spacing: CGFloat = 6
        
        view.backgroundColor = .systemGray
        label.text = hint
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: spacing),
            label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: spacing),
            label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -spacing),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -spacing)
        ])
//        preferredContentSize = CGSize(width: 100, height: 100)
    }
    
    private func setupPopover(parent: UIViewController, sourceView: UIView) {
        modalPresentationStyle = .popover
        guard let presentationVC = popoverPresentationController else {return}
        presentationVC.delegate = self
        presentationVC.sourceView = sourceView
        parent.present(self, animated: true)
    }
    
    static func showHint(parent: UIViewController, sourceView: UIView, hint: String) {
        let rv = HintViewController(hint: hint)
        rv.setupPopover(parent: parent, sourceView: sourceView)
    }
    
}

extension HintViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for _: UIPresentationController, traitCollection _: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
