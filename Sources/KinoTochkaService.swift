import WebAPI
import TVSetKit

public class KinoTochkaService {
  static let shared: KinoTochkaAPI = {
    return KinoTochkaAPI()
  }()

  static let bookmarksFileName = NSHomeDirectory() + "/Library/Caches/kinotochka-bookmarks.json"
  static let historyFileName = NSHomeDirectory() + "/Library/Caches/kinotochka-history.json"

  public static let StoryboardId = "KinoTochka"
  public static let BundleId = "com.rubikon.KinoTochkaSite"

  lazy var bookmarks = Bookmarks(KinoTochkaService.bookmarksFileName)
  lazy var history = History(KinoTochkaService.historyFileName)

  lazy var bookmarksManager = BookmarksManager(bookmarks)
  lazy var historyManager = HistoryManager(history)

  var dataSource = KinoTochkaDataSource()

  let mobile: Bool

  public init(_ mobile: Bool=false) {
    self.mobile = mobile
  }

  func buildLayout() -> UICollectionViewFlowLayout? {
    let layout = UICollectionViewFlowLayout()

    layout.itemSize = CGSize(width: 180*1.6, height: 248*1.6) // 180 x 248
    layout.sectionInset = UIEdgeInsets(top: 40.0, left: 40.0, bottom: 120.0, right: 40.0)
    layout.minimumInteritemSpacing = 40.0
    layout.minimumLineSpacing = 85.0

    layout.headerReferenceSize = CGSize(width: 500, height: 75)

    return layout
  }

  func getDetailsImageFrame() -> CGRect? {
    return CGRect(x: 40, y: 40, width: 180*2.7, height: 248*2.7)
  }

  func getConfiguration() -> [String: Any] {
    var conf = [String: Any]()

    conf["pageSize"] = 20

    if mobile {
      conf["rowSize"] = 1
    }
    else {
      conf["rowSize"] = 5
    }

    conf["mobile"] = mobile

    conf["bookmarksManager"] = bookmarksManager
    conf["historyManager"] = historyManager
    conf["dataSource"] = dataSource
    conf["storyboardId"] = KinoTochkaService.StoryboardId
    conf["bundleId"] = KinoTochkaService.BundleId
    conf["detailsImageFrame"] = getDetailsImageFrame()
    conf["buildLayout"] = buildLayout()

    return conf
  }
}
