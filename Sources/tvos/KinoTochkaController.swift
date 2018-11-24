import UIKit
import TVSetKit
import PageLoader

open class KinoTochkaController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  let CellIdentifier = "KinoTochkaCell"

  let localizer = Localizer(KinoTochkaService.BundleId, bundleClass: KinoTochkaSite.self)

  let service = KinoTochkaService()

  var pageLoader = PageLoader()
  
  private var items = Items()

  override open func viewDidLoad() {
    super.viewDidLoad()

    self.clearsSelectionOnViewWillAppear = false

    setupLayout()

    pageLoader.loadData(onLoad: getMenuItems) { result in
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

  func getMenuItems() throws -> [Any] {
    return [
      MediaName(name: "Bookmarks", imageName: "Star"),
      MediaName(name: "History", imageName: "Bookmark"),
      MediaName(name: "All Movies", imageName: "Retro TV"),
      MediaName(name: "New Movies", imageName: "Retro TV"),
      MediaName(name: "All Series", imageName: "Retro TV"),
      MediaName(name: "Russian Animations", imageName: "Retro TV"),
      MediaName(name: "Foreign Animations", imageName: "Retro TV"),
      MediaName(name: "Anime", imageName: "Retro TV"),
      MediaName(name: "Shows", imageName: "Briefcase"),
      MediaName(name: "Collections", imageName: "Briefcase"),
      MediaName(name: "User Collections", imageName: "Briefcase"),
      MediaName(name: "Settings", imageName: "Engineering"),
      MediaName(name: "Search", imageName: "Search")
    ]
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
    if let view = gesture.view as? UICollectionViewCell {
      if let indexPath = collectionView?.indexPath(for: view) {
        let mediaItem = items.getItem(for: indexPath)

        switch mediaItem.name! {
        case "Collections":
          performSegue(withIdentifier: CollectionsController.SegueIdentifier, sender: view)

        case "User Collections":
          performSegue(withIdentifier: UserCollectionsController.SegueIdentifier, sender: view)

        case "Settings":
          performSegue(withIdentifier: "Settings", sender: view)

        case "Search":
          performSegue(withIdentifier: SearchController.SegueIdentifier, sender: view)

        default:
          performSegue(withIdentifier: MediaItemsController.SegueIdentifier, sender: view)
        }
      }
    }
  }

  // MARK: - Navigation

  override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let identifier = segue.identifier {
      switch identifier {
        case MediaItemsController.SegueIdentifier:
          if let destination = segue.destination.getActionController() as? MediaItemsController,
             let view = sender as? MediaNameCell,
             let indexPath = collectionView?.indexPath(for: view) {

            let mediaItem = items.getItem(for: indexPath)

            destination.params["requestType"] = mediaItem.name
            destination.params["parentName"] = localizer.localize(mediaItem.name!)
            destination.configuration = service.getConfiguration()

            destination.collectionView?.collectionViewLayout = service.buildLayout()!
          }

        case SearchController.SegueIdentifier:
          if let destination = segue.destination.getActionController() as? SearchController {
            destination.params["requestType"] = "Search"
            destination.params["parentName"] = localizer.localize("Search Results")

            destination.configuration = service.getConfiguration()
          }

        default:
          break
      }
    }
  }

}
