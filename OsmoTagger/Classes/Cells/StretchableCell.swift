//
//  StretchableCellTableViewCell.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 20.09.2023.
//

import UIKit

class StretchableCell: UITableViewCell {
    private var label: UILabel = {
        let rv = UILabel()
        rv.numberOfLines = 0
        rv.translatesAutoresizingMaskIntoConstraints = false
        return rv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstrains()
    }
        
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstrains() {
        contentView.addSubview(label)
        let spacing: CGFloat = 5
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -spacing),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
        ])
    }
    
    func configure(_ text: String) {
        label.text = text
    }
    
    override func prepareForReuse() {
        label.text = nil
    }
}
