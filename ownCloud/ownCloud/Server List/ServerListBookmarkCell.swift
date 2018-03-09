//
//  ServerListBookmarkCell.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
//  Copyright © 2018 ownCloud. All rights reserved.
//

import UIKit

class ServerListBookmarkCell: UITableViewCell {
	public var titleLabel : UILabel = UILabel()
	public var detailLabel : UILabel = UILabel()
	public var iconView : UIImageView = UIImageView()

	public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		prepareViewAndConstraints()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func prepareViewAndConstraints() {
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		detailLabel.translatesAutoresizingMaskIntoConstraints = false
		iconView.translatesAutoresizingMaskIntoConstraints = false
		
		titleLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
		detailLabel.font = UIFont.systemFont(ofSize: 14)
		
		detailLabel.textColor = UIColor.gray

		self.addSubview(titleLabel)
		self.addSubview(detailLabel)
		self.addSubview(iconView)
		
		iconView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20).isActive = true
		iconView.rightAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: -20).isActive = true
		iconView.rightAnchor.constraint(equalTo: detailLabel.leftAnchor, constant: -20).isActive = true
		
		titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20).isActive = true
		detailLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20).isActive = true
		
		iconView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
		iconView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 20).isActive = true
		
		titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
		titleLabel.bottomAnchor.constraint(equalTo: detailLabel.topAnchor, constant: -5).isActive = true
		detailLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20).isActive = true
		
		iconView.widthAnchor.constraint(equalToConstant: 40).isActive = true
		iconView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
		
		iconView.setContentHuggingPriority(UILayoutPriority.defaultLow, for: UILayoutConstraintAxis.vertical)
		titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.vertical)
		detailLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.vertical)
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}

}