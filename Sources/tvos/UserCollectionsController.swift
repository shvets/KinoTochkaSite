import UIKit
import TVSetKit
import PageLoader

class UserCollectionsController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  static let SegueIdentifier = "User Collections"
  let CellIdentifier = "UserCollectionsCell"

#if os(tvOS)
    public let activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
#endif

  let localizer = Localizer(KinoTochkaService.BundleId, bundleClass: KinoTochkaSite.self)

  let service = KinoTochkaService()

  let pageLoader = PageLoader()

  private var items = Items()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.clearsSelectionOnViewWillAppear = false

    setupLayout()

#if os(tvOS)
    collectionView?.backgroundView = activityIndicatorView
    pageLoader.spinner = PlainSpinner(activityIndicatorView)
#endif

    func load() throws -> [Any] {
      var params = Parameters()
      params["requestType"] = "User Collections"

      return try self.service.dataSource.load(params: params)
    }

    pageLoader.loadData(onLoad: load) { result in
      if let items = result as? [Item] {
        self.items.items = items

        self.collectionView?.reloadData()
      }
    }
  }

  func setupLayout() {
    let layout = UICollectionViewFlowLayout()

    layout.itemSize = CGSize(width: 450, height: 150)
    layout.sectionInset = UIEdgeInsets(top: 150.0, left: 20.0, bottom: 50.0, right: 20.0)
    layout.minimumInteritemSpacing = 20.0
    layout.minimumLineSpacing = 100.0

    collectionView?.collectionViewLayout = layout
  }

  // MARK: UICollectionViewDataSource

  override open func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return items.count
  }

  override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as? MediaNameCell {
      if let item = items[indexPath.row] as? MediaName {
        cell.configureCell(item: item, localizedName: localizer.getLocalizedName(item.name), target: self)
      }

      CellHelper.shared.addTapGestureRecognizer(view: cell, target: self, action: #selector(self.tapped(_:)))

      return cell
    }
    else {
      return UICollectionViewCell()
    }
  }

  @objc open func tapped(_ gesture: UITapGestureRecognizer) {
    if let location = gesture.view as? UICollectionViewCell {
      navigate(from: location)
    }
  }

  override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if let location = collectionView.cellForItem(at: indexPath) {
      navigate(from: location)
    }
  }

  func navigate(from view: UICollectionViewCell, playImmediately: Bool=false) {
    performSegue(withIdentifier: MediaItemsController.SegueIdentifier, sender: view)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let identifier = segue.identifier {
      switch identifier {
      case MediaItemsController.SegueIdentifier:
        if let destination = segue.destination.getActionController() as? MediaItemsController,
           let view = sender as? MediaNameCell,
           let indexPath = collectionView?.indexPath(for: view) {

          destination.params["requestType"] = "User Collection"
          destination.params["selectedItem"] = items.getItem(for: indexPath)
          destination.configuration = service.getConfiguration()

          destination.collectionView?.collectionViewLayout = service.buildLayout()!
        }

      default: break
      }
    }
  }

}
