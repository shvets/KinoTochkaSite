import SwiftSoup
import MediaApis
import TVSetKit

class KinoTochkaDataSource: DataSource {
  let service = KinoTochkaService.shared

  override open func load(params: Parameters) throws -> [Any] {
    var items: [Any] = []

    let selectedItem = params["selectedItem"] as? MediaItem

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
        bookmarks.load()
        let data = bookmarks.getBookmarks(pageSize: 60, page: currentPage)

        items = adjustItems(data)
      }

    case "History":
      if let historyManager = params["historyManager"] as? HistoryManager,
         let history = historyManager.history {
        history.load()
        let data = history.getHistoryItems(pageSize: 60, page: currentPage)

        items = adjustItems(data)
      }

    case "All Movies":
      let data = try service.getAllMovies(page: currentPage).items
      
      items = adjustItems(data)

    case "New Movies":
      let data = try service.getNewMovies(page: currentPage).items
      
      items = adjustItems(data)
      

    case "All Series":
      let data = try service.getAllSeries(page: currentPage).items
      
      items = adjustItems(data)

    case "Russian Animations":
      let data = try service.getRussianAnimations(page: currentPage).items
      
      items = adjustItems(data)

    case "Foreign Animations":
      let data = try service.getForeignAnimations(page: currentPage).items
      
      items = adjustItems(data)
      
    case "Anime":
      let data = try service.getAnime(page: currentPage).items
      
      items = adjustItems(data)

    case "Shows":
      let data = try service.getTvShows(page: currentPage).items
      
      items = adjustItems(data)

    case "Seasons":
      if let selectedItem = selectedItem,
         let path = selectedItem.id {
        let seasons = try service.getSeasons(path, selectedItem.thumb)

        if seasons.count == 1 {
          let path = seasons[0]["id"]!

          let files = try service.getUrls(path)

          if files.count > 0 {
            var episodes = [KinoTochkaAPI.Episode]()
            episodes.append(service.buildEpisode(comment: selectedItem.name!, files: files))

            items = adjustItems(episodes, selectedItem: selectedItem)
          }
          else {
            items = adjustItems(seasons, selectedItem: selectedItem)
          }
        }
        else {
          items = adjustItems(seasons, selectedItem: selectedItem)
        }
      }

    case "Episodes":
      if let selectedItem = selectedItem,
         let path = selectedItem.id {
        let newPath = KinoTochkaAPI.getURLPathOnly(path, baseUrl: KinoTochkaAPI.SiteUrl)
        
        let playlistUrl = try service.getSeasonPlaylistUrl(newPath)

        let pageSize = params["pageSize"] as! Int

        let episodes = try service.getEpisodes(playlistUrl)
        let paginatedEpisodes = paginated(items: episodes, currentPage: currentPage, pageSize: pageSize)

        items = adjustItems(paginatedEpisodes, selectedItem: selectedItem)
      }

    case "Collections":
      let collections = try service.getCollections()

      items = adjustItems(collections)

    case "Collection":
      if let selectedItem = selectedItem,
         let path = selectedItem.id {
        let data = try service.getCollection(path, page: currentPage).items
        
        items = adjustItems(data)
      }

    case "User Collections":
      let collections = try service.getUserCollections()

      items = adjustItems(collections)

    case "User Collection":
      if let selectedItem = selectedItem,
         let path = selectedItem.id {
        let data = try service.getUserCollection(path, page: currentPage).items
        
        items = adjustItems(data)
      }

    case "Search":
      if let query = params["query"] as? String {
        if !query.isEmpty {
          let data = try service.search(query, page: currentPage).items
         
          items = adjustItems(data)
        }
      }

    default:
      items = []
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
