import SwiftSoup
import WebAPI
import TVSetKit
import RxSwift

class KinoTochkaDataSource: DataSource {
  let service = KinoTochkaService.shared

  override open func load(params: Parameters) throws -> Observable<[Any]> {
    var items: Observable<[Any]> = Observable.just([])

    let selectedItem = params["selectedItem"] as? MediaItem

    var episodes = [KinoTochkaAPI.Episode]()

    var request = params["requestType"] as! String
    let currentPage = params["currentPage"] as? Int ?? 1

    if selectedItem?.type == "serie" {
      request = "Seasons"
    }
    else if selectedItem?.type == "season" {
      request = "Episodes"
    }

    switch request {
    case "Bookmarks":
      if let bookmarksManager = params["bookmarksManager"] as? BookmarksManager,
         let bookmarks = bookmarksManager.bookmarks {
        let data = bookmarks.getBookmarks(pageSize: 60, page: currentPage)

        items = Observable.just(adjustItems(data))
      }

    case "History":
      if let historyManager = params["historyManager"] as? HistoryManager,
         let history = historyManager.history {
        let data = history.getHistoryItems(pageSize: 60, page: currentPage)

        items = Observable.just(adjustItems(data))
      }

    case "All Movies":
      if let data = try service.getAllMovies(page: currentPage)["movies"] as? [Any] {
        items = Observable.just(adjustItems(data))
      }

    case "New Movies":
      if let data = try service.getNewMovies(page: currentPage)["movies"] as? [Any] {
        items = Observable.just(adjustItems(data))
      }

    case "All Series":
      if let data = try service.getAllSeries(page: currentPage)["movies"] as? [Any] {
        items = Observable.just(adjustItems(data))
      }

    case "Animations":
      if let data = try service.getAnimations(page: currentPage)["movies"] as? [Any] {
        items = Observable.just(adjustItems(data))
      }

    case "Anime":
      if let data = try service.getAnime(page: currentPage)["movies"] as? [Any] {
        items = Observable.just(adjustItems(data))
      }

    case "Shows":
      if let data = try service.getTvShows(page: currentPage)["movies"] as? [Any] {
        items = Observable.just(adjustItems(data))
      }

    case "Seasons":
      if let selectedItem = selectedItem,
         let path = selectedItem.id {
        let seasons = try service.getSeasons(path, selectedItem.thumb) as! [[String: String]]

        if seasons.count == 1 {
          let path = seasons[0]["id"]!

          let files = try service.getUrls(path)

          if files.count > 0 {
            var episodes = [KinoTochkaAPI.Episode]()
            episodes.append(service.buildEpisode(comment: selectedItem.name!, files: files))

            items = Observable.just(adjustItems(episodes, selectedItem: selectedItem))
          }
          else {
            items = Observable.just(adjustItems(seasons, selectedItem: selectedItem))
          }
        }
        else {
          items = Observable.just(adjustItems(seasons, selectedItem: selectedItem))
        }
      }

    case "Episodes":
      if let selectedItem = selectedItem,
         let path = selectedItem.id {
        let playlistUrl = try service.getSeasonPlaylistUrl(path)

        var pageSize = params["pageSize"] as! Int

        let episodes = try service.getEpisodes(playlistUrl, path: "")

        var episodesOnPage: [KinoTochkaAPI.Episode] = []

        for (index, item) in episodes.enumerated() {
          if index >= (currentPage - 1) * pageSize && index < currentPage * pageSize {
            episodesOnPage.append(item)
          }
        }

        items = Observable.just(adjustItems(episodesOnPage, selectedItem: selectedItem))
      }

    case "Search":
      if let query = params["query"] as? String {
        if !query.isEmpty {
          if let data = try service.search(query, page: currentPage)["movies"] as? [Any] {
            items = Observable.just(adjustItems(data))
          }
        }
      }

    default:
      items = Observable.just([])
    }

    return items
  }

  func adjustItems(_ items: [Any], selectedItem: MediaItem?=nil) -> [Item] {
    var newItems = [Item]()

    if let items = items as? [HistoryItem] {
      newItems = transform(items) { item in
        createHistoryItem(item as! HistoryItem)
      }
    }
    else if let items = items as? [BookmarkItem] {
      newItems = transform(items) { item in
        createBookmarkItem(item as! BookmarkItem)
      }
    }
    else if let items = items as? [KinoTochkaAPI.Season] {
      newItems = transformWithIndex(items) { (index, item) in
        let seasonNumber = String(index+1)
        
        return createSeasonItem(item as! KinoTochkaAPI.Season, selectedItem: selectedItem!, seasonNumber: seasonNumber)
      }
    }
    else if let items = items as? [KinoTochkaAPI.Episode] {
      newItems = transform(items) { item in
        createEpisodeItem(item as! KinoTochkaAPI.Episode, selectedItem: selectedItem!)
      }
    }
    else if let items = items as? [[String: Any]] {
      newItems = transform(items) { item in
        createMediaItem(item as! [String: Any])
      }
    }
    else if let items = items as? [Item] {
      newItems = items
    }

    return newItems
  }

  func createHistoryItem(_ item: HistoryItem) -> Item {
    let newItem = KinoTochkaMediaItem(data: ["name": ""])

    newItem.name = item.item.name
    newItem.id = item.item.id
    newItem.description = item.item.description
    newItem.thumb = item.item.thumb
    newItem.type = item.item.type

    return newItem
  }

  func createBookmarkItem(_ item: BookmarkItem) -> Item {
    let newItem = KinoTochkaMediaItem(data: ["name": ""])

    newItem.name = item.item.name
    newItem.id = item.item.id
    newItem.description = item.item.description
    newItem.thumb = item.item.thumb
    newItem.type = item.item.type

    return newItem
  }

    func createSeasonItem(_ item: KinoTochkaAPI.Season, selectedItem: MediaItem, seasonNumber: String) -> Item {
    let newItem = KinoTochkaMediaItem(data: ["name": ""])

    newItem.name = item.name
    
    if let path = selectedItem.id {
      newItem.id = path
    }
    
    newItem.type = "season"
    
    if let thumb = selectedItem.thumb {
      newItem.thumb = thumb
    }
    
    newItem.seasonNumber = seasonNumber
    newItem.episodes = item.playlist

    return newItem
  }

    func createEpisodeItem(_ item: KinoTochkaAPI.Episode, selectedItem: MediaItem) -> Item {
    let newItem = KinoTochkaMediaItem(data: ["name": ""])

    newItem.name = item.name
    newItem.id = item.files[0]
    newItem.type = "episode"
    newItem.files = item.files
        
    if let thumb = selectedItem.thumb {
      newItem.thumb = thumb
    }

    return newItem
  }

  func createMediaItem(_ item: [String: Any]) -> Item {
    let newItem = KinoTochkaMediaItem(data: ["name": ""])

    if let dict = item as? [String: String] {
      newItem.name = dict["name"]
      newItem.id = dict["id"]
      newItem.type = dict["type"]
      newItem.thumb = dict["thumb"]
    }

    return newItem
  }

}
