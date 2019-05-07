//
//  GroupSharingTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 10.04.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class GroupSharingTableViewController: StaticTableViewController, UISearchResultsUpdating, UISearchBarDelegate, OCRecipientSearchControllerDelegate {

	// MARK: - Instance Variables
	var shares : [OCShare] = [] {
		didSet {
			let meShares = shares.filter { (share) -> Bool in
				if share.recipient?.user?.userName == core?.connection.loggedInUser?.userName && share.canShare {
					return true
				} else if share.itemOwner?.userName == core?.connection.loggedInUser?.userName && share.canShare {
					return true
				}
				return false
			}
			if meShares.count > 0 {
				meCanShareItem = true
			}
		}
	}
	var core : OCCore?
	var item : OCItem? {
		didSet {
			if item?.isShareable ?? false {
				if item?.isSharedWithUser == false {
					meCanShareItem = true
				} else if item?.isSharedWithUser ?? false, core?.connection.capabilities?.sharingResharing == true {
					meCanShareItem = true
				}
			}
		}
	}
	var searchController : UISearchController?
	var recipientSearchController : OCRecipientSearchController?
	var meCanShareItem : Bool = false
	var messageView : MessageView?
	var shareQuery : OCShareQuery?

	// MARK: - Init

	override func viewDidLoad() {
		super.viewDidLoad()

		guard let item = item else { return }

		if meCanShareItem {
			searchController = UISearchController(searchResultsController: nil)
			searchController?.searchResultsUpdater = self
			searchController?.hidesNavigationBarDuringPresentation = true
			searchController?.dimsBackgroundDuringPresentation = false
			searchController?.searchBar.placeholder = "Search User, Group, Remote".localized
			searchController?.searchBar.delegate = self
			navigationItem.hidesSearchBarWhenScrolling = false
			navigationItem.searchController = searchController
			definesPresentationContext = true
			searchController?.searchBar.applyThemeCollection(Theme.shared.activeCollection)
			recipientSearchController = core?.recipientSearchController(for: item)
			recipientSearchController?.delegate = self
		}

		messageView = MessageView(add: self.view)

		self.navigationItem.title = "Sharing".localized
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissView))

		shareQuery = core!.sharesWithReshares(for: item, initialPopulationHandler: { (sharesWithReshares) in
			if sharesWithReshares.count > 0 {
				self.shares = sharesWithReshares.filter { (OCShare) -> Bool in
					if OCShare.type != .link {
						return true
					}
					return false
				}
				self.addShareSections()
			}
			_ = self.core!.sharesSharedWithMe(for: item, initialPopulationHandler: { (sharesWithMe) in
				if sharesWithMe.count > 0 {
					var shares : [OCShare] = []
					shares.append(contentsOf: sharesWithMe)
					shares.append(contentsOf: sharesWithReshares)
					self.shares = shares
					self.removeShareSections()
					self.addShareSections()
				}
			})
		})

		shareQuery?.refreshInterval = 2
		shareQuery?.changesAvailableNotificationHandler = { query in
			let sharesWithReshares = query.queryResults.filter { (OCShare) -> Bool in
				if OCShare.type != .link {
					return true
				}
				return false
			}
			self.shares = sharesWithReshares
			self.removeShareSections()
			self.addShareSections()
			self.handleEmptyShares()
		}
	}

	@objc func dismissView() {
		if let query = self.shareQuery {
			self.core?.stop(query)
		}
		dismissAnimated()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		handleEmptyShares()
	}

	// MARK: - Sharing UI

	func addSectionFor(type: OCShareType, with title: String) {
		var shareRows: [StaticTableViewRow] = []

		let user = shares.filter { (OCShare) -> Bool in
			if OCShare.type == type {
				return true
			}
			return false
		}

		if user.count > 0 {
			for share in user {
				let resharedUsers = shares.filter { (OCShare) -> Bool in
					if OCShare.owner == share.recipient?.user {
						return true
					}
					return false
				}
				if canEdit(share: share) {
					shareRows.append( StaticTableViewRow(rowWithAction: { (_, _) in
						let editSharingViewController = GroupSharingEditUserGroupsTableViewController(style: .grouped)
						editSharingViewController.share = share
						editSharingViewController.reshares = resharedUsers
						editSharingViewController.core = self.core
						self.navigationController?.pushViewController(editSharingViewController, animated: true)
					}, title: share.recipient!.displayName!, subtitle: share.permissionDescription(), accessoryType: .disclosureIndicator) )
				} else {
					shareRows.append( StaticTableViewRow(rowWithAction: nil, title: share.recipient!.displayName!, subtitle: share.permissionDescription(), accessoryType: .none) )
				}
			}
			let sectionType = "share-section-\(String(type.rawValue))"
			if let section = self.sectionForIdentifier(sectionType) {
				self.removeSection(section)
			}

			let section : StaticTableViewSection = StaticTableViewSection(headerTitle: title, footerTitle: nil, identifier: sectionType, rows: shareRows)
			self.addSection(section)
		}
	}

	func addShareSections() {
		OnMainThread {
			self.addSectionFor(type: .userShare, with: "Users".localized)
			self.addSectionFor(type: .groupShare, with: "Groups".localized)
			self.addSectionFor(type: .remote, with: "Remote Users".localized)
		}
	}

	func removeShareSections() {
		OnMainThread {
			let types : [OCShareType] = [.userShare, .groupShare, .remote]
			for type in types {
				let identifier = "share-section-\(String(type.rawValue))"
				if let section = self.sectionForIdentifier(identifier) {
					self.removeSection(section)
				}
			}
		}
	}

	func resetTable(showShares : Bool) {
		removeShareSections()
		if let section = self.sectionForIdentifier("search-results") {
			self.removeSection(section)
		}
		if shares.count > 0 && showShares {
			messageView?.message(show: false)
			self.addShareSections()
		} else {
			messageView?.message(show: true, imageName: "icon-search", title: "Search Recipients".localized, message: "Start typing to search users, groups and remote users.".localized)
		}
	}

	func handleEmptyShares() {
		if shares.count == 0 {
			OnMainThread {
				self.resetTable(showShares: false)
				self.searchController?.searchBar.becomeFirstResponder()
			}
		}
	}

	// MARK: - Sharing Helper

	func share(at indexPath : IndexPath) -> OCShare? {
		var type : OCShareType?
		switch indexPath.section {
		case 0:
			type = .userShare
		case 1:
			type = .groupShare
		case 2:
			type = .remote
		default:
			break
		}

		if type != nil {
			let shares = self.shares.filter { (OCShare) -> Bool in
				if OCShare.type == type {
					return true
				}
				return false
			}
			if shares.indices.contains(indexPath.row) {
				return shares[indexPath.row]
			}
		}

		return nil
	}

	func canEdit(share: OCShare) -> Bool {
		if core?.connection.loggedInUser?.userName == share.owner?.userName || core?.connection.loggedInUser?.userName == share.itemOwner?.userName {
			return true
		}

		return false
	}

	// MARK: - UISearchResultsUpdating Delegate

	func updateSearchResults(for searchController: UISearchController) {
		guard let text = searchController.searchBar.text else { return }
		if text.count > core?.connection.capabilities?.sharingSearchMinLength?.intValue ?? 1 {
			recipientSearchController?.searchTerm = text
			recipientSearchController?.search()
		} else if searchController.isActive {
			resetTable(showShares: false)
		}
	}

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		self.resetTable(showShares: true)
		self.searchController?.searchBar.isLoading = false
	}

	func searchControllerHasNewResults(_ searchController: OCRecipientSearchController, error: Error?) {
		OnMainThread {
			guard let recipients = searchController.recipients else {
				self.messageView?.message(show: true, imageName: "icon-search", title: "No matches".localized, message: "There is no results for this search".localized)
				return
			}

			self.messageView?.message(show: false)
			var rows : [StaticTableViewRow] = []
			for recipient in recipients {

				guard let itemPath = self.item?.path else { continue }
				var title = ""
				if recipient.type == .user {
					guard let user = recipient.user, let name = user.displayName else { continue }
					title = name
				} else {
					guard let group = recipient.group, let name = group.name else { continue }
					let groupTitle = "(Group)".localized
					title = "\(name) \(groupTitle)"
				}

				rows.append(
					StaticTableViewRow(rowWithAction: { (_, _) in
						var defaultPermissions : OCSharePermissionsMask = .read
						if let capabilitiesDefaultPermission = self.core?.connection.capabilities?.sharingDefaultPermissions {
							defaultPermissions = capabilitiesDefaultPermission
						}

						let share = OCShare(recipient: recipient, path: itemPath, permissions: defaultPermissions, expiration: nil)

						OnMainThread {
							self.searchController?.searchBar.text = ""
							self.searchController?.dismiss(animated: true, completion: nil)
						}
						self.core?.createShare(share, options: nil, completionHandler: { (error, _) in
							if error == nil {
								OnMainThread {
									let editSharingViewController = GroupSharingEditUserGroupsTableViewController(style: .grouped)
									editSharingViewController.share = share
									editSharingViewController.core = self.core
									self.navigationController?.pushViewController(editSharingViewController, animated: true)

									self.resetTable(showShares: true)
								}
							} else {
								if let shareError = error {
									OnMainThread {
										self.resetTable(showShares: true)
										let alertController = UIAlertController(with: "Adding User to Share failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
										self.present(alertController, animated: true)
									}
								}
							}
						})
					}, title: title)
				)
			}
			self.removeShareSections()
			if let section = self.sectionForIdentifier("search-results") {
				self.removeSection(section)
			}

			self.addSection(
				StaticTableViewSection(headerTitle: "Select Share Recipient".localized, footerTitle: nil, identifier: "search-results", rows: rows)
			)
		}
	}

	func searchController(_ searchController: OCRecipientSearchController, isWaitingForResults isSearching: Bool) {
		if isSearching {
			self.searchController?.searchBar.isLoading = true
		} else {
			self.searchController?.searchBar.isLoading = false
		}
	}

	// MARK: TableView Delegate

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		if let shareAtPath = share(at: indexPath), self.canEdit(share: shareAtPath) {
			return [
				UITableViewRowAction(style: .destructive, title: "Delete".localized, handler: { (_, _) in
					var presentationStyle: UIAlertController.Style = .actionSheet
					if UIDevice.current.isIpad() {
						presentationStyle = .alert
					}

					let alertController = UIAlertController(title: "Delete Recipient".localized,
															message: nil,
															preferredStyle: presentationStyle)
					alertController.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))

					alertController.addAction(UIAlertAction(title: "Delete".localized, style: .destructive, handler: { (_) in
						if let core = self.core {
							core.delete(shareAtPath, completionHandler: { (error) in
								OnMainThread {
									if error == nil {
										self.navigationController?.popViewController(animated: true)
									} else {
										if let shareError = error {
											let alertController = UIAlertController(with: "Delete Recipient failed".localized, message: shareError.localizedDescription, okLabel: "OK".localized, action: nil)
											self.present(alertController, animated: true)
										}
									}
								}
							})
						}
					}))

					self.present(alertController, animated: true, completion: nil)
				})
			]
		}

		return []
	}
}