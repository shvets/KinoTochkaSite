import UIKit
import TVSetKit
import PageLoader

class SettingsTableController: UITableViewController {
  let CellIdentifier = "SettingTableCell"

  let localizer = Localizer(KinoTochkaService.BundleId, bundleClass: KinoTochkaSite.self)

  let service = KinoTochkaService(true)
  let pageLoader = PageLoader()
  private var items = Items()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.clearsSelectionOnViewWillAppear = false

    title = localizer.localize("Settings")

    pageLoader.loadData(onLoad: getSettingsMenu) { result in
      if let items = result as? [Item] {
        self.items.items = items

        self.tableView?.reloadData()
      }
    }
  }

  func getSettingsMenu() throws -> [Any] {
     return [
        MediaName(name: "Reset History"),
        MediaName(name: "Reset Bookmarks")
      ]
  }

 // MARK: UITableViewDataSource

  override open func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as? MediaNameTableCell {
      let item = items[indexPath.row]

      cell.configureCell(item: item, localizedName: localizer.getLocalizedName(item.name))

      return cell
    }
    else {
      return UITableViewCell()
    }
  }

  override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let view = tableView.cellForRow(at: indexPath),
       let indexPath = tableView.indexPath(for: view) {
        let mediaItem = items.getItem(for: indexPath)

        let settingsMode = mediaItem.name

        if settingsMode == "Reset History" {
          self.present(buildResetHistoryController(), animated: false, completion: nil)
        }
        else if settingsMode == "Reset Bookmarks" {
          self.present(buildResetQueueController(), animated: false, completion: nil)
        }
      }
  }

  func buildResetHistoryController() -> UIAlertController {
    let title = localizer.localize("History Will Be Reset")
    let message = localizer.localize("Please Confirm Your Choice")

    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
      let history = self.service.history

      history.clear()
      history.save()
    }

    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

    alertController.addAction(cancelAction)
    alertController.addAction(okAction)

    return alertController
  }

  func buildResetQueueController() -> UIAlertController {
    let title = localizer.localize("Bookmarks Will Be Reset")
    let message = localizer.localize("Please Confirm Your Choice")

    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
      let bookmarks = self.service.bookmarks

      bookmarks.clear()
      bookmarks.save()
    }

    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

    alertController.addAction(cancelAction)
    alertController.addAction(okAction)

    return alertController
  }

}
