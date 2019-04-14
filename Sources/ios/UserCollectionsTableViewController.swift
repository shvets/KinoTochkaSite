import UIKit
import TVSetKit
import PageLoader

class UserCollectionsTableViewController: UITableViewController {
  static let SegueIdentifier = "User Collections"

  let CellIdentifier = "UserCollectionsTableCell"

#if os(iOS)
  public let activityIndicatorView = UIActivityIndicatorView(style: .gray)
#endif

  let localizer = Localizer(KinoTochkaService.BundleId, bundleClass: KinoTochkaSite.self)

  let service = KinoTochkaService(true)

  let pageLoader = PageLoader()

  private var items = Items()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.clearsSelectionOnViewWillAppear = false

#if os(iOS)
    tableView?.backgroundView = activityIndicatorView
    pageLoader.spinner = PlainSpinner(activityIndicatorView)
#endif

    func load() throws -> [Any] {
      var params = Parameters()
      params["requestType"] = "User Collections"

      return try self.service.dataSource.loadAndWait(params: params)
    }

    pageLoader.loadData(onLoad: load) { result in
      if let items = result as? [Item] {
        self.items.items = items

        self.tableView?.reloadData()
      }
    }
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

//      let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed(_:)))
//      tableView.addGestureRecognizer(longPressRecognizer)

      return cell
    }
    else {
      return UITableViewCell()
    }
  }

  override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let view = tableView.cellForRow(at: indexPath) {
      performSegue(withIdentifier: MediaItemsController.SegueIdentifier, sender: view)
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let identifier = segue.identifier {
      switch identifier {
      case MediaItemsController.SegueIdentifier:
        if let destination = segue.destination.getActionController() as? MediaItemsController,
           let view = sender as? MediaNameTableCell,
           let indexPath = tableView?.indexPath(for: view) {

          destination.params["requestType"] = "User Collection"
          destination.params["selectedItem"] = items.getItem(for: indexPath)

          destination.configuration = service.getConfiguration()
        }

      default: break
      }
    }
  }

}
