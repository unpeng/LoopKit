//
//  DeliveryLimitSettingsTableViewController.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import UIKit


public protocol DeliveryLimitSettingsTableViewControllerDelegate: AnyObject {
    func deliveryLimitSettingsTableViewControllerDidUpdateMaximumBasalRatePerHour(_ vc: DeliveryLimitSettingsTableViewController)

    func deliveryLimitSettingsTableViewControllerDidUpdateMinimumBasalRatePerHour(_ vc: DeliveryLimitSettingsTableViewController)

    func deliveryLimitSettingsTableViewControllerDidUpdateMaximumBolus(_ vc: DeliveryLimitSettingsTableViewController)
}


public enum DeliveryLimitSettingsResult {
    case success(maximumBasalRatePerHour: Double, minimumBasalRatePerHour: Double, maximumBolus: Double)
    case failure(Error)
}


public protocol DeliveryLimitSettingsTableViewControllerSyncSource: AnyObject {
    func syncDeliveryLimitSettings(for viewController: DeliveryLimitSettingsTableViewController, completion: @escaping (_ result: DeliveryLimitSettingsResult) -> Void)

    func syncButtonTitle(for viewController: DeliveryLimitSettingsTableViewController) -> String

    func syncButtonDetailText(for viewController: DeliveryLimitSettingsTableViewController) -> String?

    func deliveryLimitSettingsTableViewControllerIsReadOnly(_ viewController: DeliveryLimitSettingsTableViewController) -> Bool
}


public class DeliveryLimitSettingsTableViewController: UITableViewController {

    public weak var delegate: DeliveryLimitSettingsTableViewControllerDelegate?

    public weak var syncSource: DeliveryLimitSettingsTableViewControllerSyncSource? {
        didSet {
            isReadOnly = syncSource?.deliveryLimitSettingsTableViewControllerIsReadOnly(self) ?? false

            if isViewLoaded {
                tableView.reloadData()
            }
        }
    }

    public var maximumBasalRatePerHour: Double? {
        didSet {
            if isViewLoaded, let cell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.maxBasalRate.rawValue)) as? TextFieldTableViewCell {
                if let maximumBasalRatePerHour = maximumBasalRatePerHour {
                    cell.textField.text = valueNumberFormatter.string(from:  maximumBasalRatePerHour)
                    self.isSaved = false
                } else {
                    cell.textField.text = nil
                }
            }
        }
    }

    public var minimumBasalRatePerHour: Double? {
        didSet {
            if isViewLoaded, let cell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.minBasalRate.rawValue)) as? TextFieldTableViewCell {
                if let mimimumBasalRatePerHour = minimumBasalRatePerHour {
                    cell.textField.text = valueNumberFormatter.string(from:  mimimumBasalRatePerHour)
                    self.isSaved = false
                } else {
                    cell.textField.text = nil
                }
            }
        }
    }

    public var maximumBolus: Double? {
        didSet {
            if isViewLoaded, let cell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.maxBolus.rawValue)) as? TextFieldTableViewCell {
                if let maximumBolus = maximumBolus {
                    cell.textField.text = valueNumberFormatter.string(from: maximumBolus)
                    self.isSaved = false
                } else {
                    cell.textField.text = nil
                }
            }
        }
    }

    public var isReadOnly = false

    private var isSyncInProgress = false {
        didSet {
            for cell in tableView.visibleCells {
                switch cell {
                case let cell as TextButtonTableViewCell:
                    cell.isEnabled = !isSyncInProgress
                    cell.isLoading = isSyncInProgress
                case let cell as TextFieldTableViewCell:
                    cell.textField.isEnabled = !isReadOnly && !isSyncInProgress
                default:
                    break
                }
            }

            for item in navigationItem.rightBarButtonItems ?? [] {
                item.isEnabled = !isSyncInProgress
            }

            navigationItem.hidesBackButton = isSyncInProgress
        }
    }

    private var everythingIsSet: Bool {
        return maximumBasalRatePerHour != nil && minimumBasalRatePerHour != nil && maximumBolus != nil
    }

    private lazy var valueNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()

        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1

        return formatter
    }()

    @objc private func cancel(_ sender: Any?) {
        self.navigationController?.popViewController(animated: true)
    }

    private var isSaved = false {
        didSet {
            setCancelButton()
        }
    }

    // MARK: -

    fileprivate func setCancelButton() {
        if isSaved == false && syncSource != nil {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(TextFieldTableViewCell.nib(), forCellReuseIdentifier: TextFieldTableViewCell.className)
        tableView.register(TextButtonTableViewCell.self, forCellReuseIdentifier: TextButtonTableViewCell.className)
        setCancelButton()
    }

    // MARK: - Table view data source

    private enum Section: Int {
        case maxBasalRate
        case minBasalRate
        case maxBolus
        case sync
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return syncSource == nil ? 3 : 4
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .maxBasalRate:
            let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldTableViewCell.className, for: indexPath) as! TextFieldTableViewCell

            if let maximumBasalRatePerHour = maximumBasalRatePerHour {
                cell.textField.text = valueNumberFormatter.string(from: maximumBasalRatePerHour)
            } else {
                cell.textField.text = nil
            }
            cell.textField.keyboardType = .decimalPad
            cell.textField.placeholder = isReadOnly ? LocalizedString("Enter a rate in units per hour", comment: "The placeholder text instructing users how to enter a maximum basal rate") : nil
            cell.textField.isEnabled = !isReadOnly && !isSyncInProgress
            cell.unitLabel?.text = LocalizedString("U/hour", comment: "The unit string for units per hour")

            cell.delegate = self

            return cell
        case .minBasalRate:
            let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldTableViewCell.className, for: indexPath) as! TextFieldTableViewCell

            if let minimumBasalRatePerHour = minimumBasalRatePerHour {
                cell.textField.text = valueNumberFormatter.string(from: minimumBasalRatePerHour)
            } else {
                cell.textField.text = nil
            }
            cell.textField.keyboardType = .decimalPad
            cell.textField.placeholder = isReadOnly ? LocalizedString("Enter a rate in units per hour", comment: "The placeholder text instructing users how to enter a minimum basal rate") : nil
            cell.textField.isEnabled = !isReadOnly && !isSyncInProgress
            cell.unitLabel?.text = LocalizedString("U/hour", comment: "The unit string for units per hour")

            cell.delegate = self

            return cell
        case .maxBolus:
            let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldTableViewCell.className, for: indexPath) as! TextFieldTableViewCell
            if let maximumBolus = maximumBolus {
                cell.textField.text = valueNumberFormatter.string(from: maximumBolus)
            } else {
                cell.textField.text = nil
            }
            cell.textField.keyboardType = .decimalPad
            cell.textField.placeholder = isReadOnly ? LocalizedString("Enter a number of units", comment: "The placeholder text instructing users how to enter a maximum bolus") : nil
            cell.textField.isEnabled = !isReadOnly && !isSyncInProgress
            cell.unitLabel?.text = LocalizedString("Units", comment: "The unit string for units")

            cell.delegate = self

            return cell
        case .sync:
            let cell = tableView.dequeueReusableCell(withIdentifier: TextButtonTableViewCell.className, for: indexPath) as! TextButtonTableViewCell

            cell.textLabel?.text = syncSource?.syncButtonTitle(for: self)
            cell.isEnabled = !isSyncInProgress && everythingIsSet
            cell.isLoading = isSyncInProgress

            return cell
        }
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .maxBasalRate:
            return LocalizedString("Maximum Basal Rate", comment: "The title text for the maximum basal rate value")
        case .minBasalRate:
            return LocalizedString("Minimum Basal Rate", comment: "The title text for the minimum basal rate value")
        case .maxBolus:
            return LocalizedString("Maximum Bolus", comment: "The title text for the maximum bolus value")
        case .sync:
            return nil
        }
    }

    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .maxBasalRate, .minBasalRate, .maxBolus:
            return nil
        case .sync:
            return syncSource?.syncButtonDetailText(for: self)
        }
    }

    public override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .maxBasalRate, .minBasalRate, .maxBolus:
            if let cell = tableView.cellForRow(at: indexPath) as? TextFieldTableViewCell {
                if cell.textField.isFirstResponder {
                    cell.textField.resignFirstResponder()
                } else {
                    cell.textField.becomeFirstResponder()
                }
            }
        case .sync:
            tableView.endEditing(true)

            guard let syncSource = syncSource, !isSyncInProgress else {
                break
            }
            guard maximumBasalRatePerHour != nil && minimumBasalRatePerHour != nil && maximumBolus != nil else {
                break
            }

            isSyncInProgress = true
            syncSource.syncDeliveryLimitSettings(for: self) { (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(maximumBasalRatePerHour: let maxBasal, minimumBasalRatePerHour: let minBasal, maximumBolus: let maxBolus):
                        self.maximumBasalRatePerHour = maxBasal
                        self.minimumBasalRatePerHour = minBasal
                        self.maximumBolus = maxBolus

                        self.delegate?.deliveryLimitSettingsTableViewControllerDidUpdateMaximumBasalRatePerHour(self)
                        self.delegate?.deliveryLimitSettingsTableViewControllerDidUpdateMinimumBasalRatePerHour(self)
                        self.delegate?.deliveryLimitSettingsTableViewControllerDidUpdateMaximumBolus(self)

                        self.isSyncInProgress = false
                        self.isSaved = true
                    case .failure(let error):
                        let alert = UIAlertController(with: error)
                        self.present(alert, animated: true) {
                            self.isSyncInProgress = false
                        }
                    }
                }
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}


extension DeliveryLimitSettingsTableViewController: TextFieldTableViewCellDelegate {
    public func textFieldTableViewCellDidBeginEditing(_ cell: TextFieldTableViewCell) {
    }

    public func textFieldTableViewCellDidEndEditing(_ cell: TextFieldTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }

        let value = valueNumberFormatter.number(from: cell.textField.text ?? "")?.doubleValue

        switch Section(rawValue: indexPath.section)! {
        // XXX use supportedBasalRates() and roundToSupportedBolusVolume() here??
        case .maxBasalRate:
            maximumBasalRatePerHour = value
            if syncSource == nil {
                delegate?.deliveryLimitSettingsTableViewControllerDidUpdateMaximumBasalRatePerHour(self)
            }
        case .minBasalRate:
            minimumBasalRatePerHour = value
            if syncSource == nil {
                delegate?.deliveryLimitSettingsTableViewControllerDidUpdateMinimumBasalRatePerHour(self)
            }
        case .maxBolus:
            maximumBolus = value
            if syncSource == nil {
                delegate?.deliveryLimitSettingsTableViewControllerDidUpdateMaximumBolus(self)
            }
        case .sync:
            break
        }
    }
}
