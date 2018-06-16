import UIKit
import TVSetKit
import PageLoader
class GenresGroupController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  static let SegueIdentifier = "Genres Group"
  let CellIdentifier = "GenreGroupCell"

  let localizer = Localizer(KinoTochkaService.BundleId, bundleClass: KinoTochkaSite.self)

  let service = KinoTochkaService()
  
  let pageLoader = PageLoader()

  private var items = Items()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.clearsSelectionOnViewWillAppear = false

    setupLayout()

    pageLoader.loadData(onLoad: loadGenresGroupMenu) { result in
      if let items = result as? [Item] {
        self.items.items = items

        self.collectionView?.reloadData()
      }
    }
  }

  func setupLayout() {
    let layout = UICollectionViewFlowLayout()

    layout.itemSize = CGSize(width: 450, height: 150)
    layout.sectionInset = UIEdgeInsets(top: 100.0, left: 20.0, bottom: 50.0, right: 20.0)
    layout.minimumInteritemSpacing = 10.0
    layout.minimumLineSpacing = 100.0

    collectionView?.collectionViewLayout = layout
  }

  func loadGenresGroupMenu() throws -> [Any] {
    return [
      MediaName(name: "Movies"),
      MediaName(name: "Series"),
      MediaName(name: "Anime")
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
      performSegue(withIdentifier: GenresController.SegueIdentifier, sender: view)
    }
  }

  // MARK: - Navigation

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let identifier = segue.identifier {
      switch identifier {
        case GenresController.SegueIdentifier:
          if let destination = segue.destination as? GenresController,
             let selectedCell = sender as? MediaNameCell,
             let indexPath = collectionView?.indexPath(for: selectedCell) {

            let mediaItem = items.getItem(for: indexPath)

            switch mediaItem.name! {
              case "Movies":
                destination.parentId = "film"

              case "Series":
                destination.parentId = "series"
              
              case "Anime":
                destination.parentId = "animes"
              
              default: break
            }
          }

        default: break
      }
    }
  }
}
