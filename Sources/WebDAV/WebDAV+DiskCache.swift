//
//  WebDAV+DiskCache.swift
//  WebDAV-Swift
//
//  Created by Isaac Lyons on 4/7/21.
//

import UIKit

//MARK: Public

public extension WebDAV {
    
    //MARK: Data
    
    /// Get the local cached data URL for the item at the specified path.
    ///
    /// Gives the URL the data would be cached at wether or not there is any data cached there.
    /// - Parameters:
    ///   - path: The path that would be used to download the data.
    ///   - account: The WebDAV account that would be used to download the data.
    /// - Returns: The URL where the data is or would be cached.
    func cachedDataURL(forItemAtPath path: String) -> URL? {
        guard let encodedDescription = UnwrappedAccount(account: account)?.encodedDescription,
              let caches = cacheFolder else { return nil }
        let trimmedPath = path.trimmingCharacters(in: AccountPath.slash)
        
        if trimmedPath.isEmpty {
            return caches
                .appendingPathComponent(encodedDescription)
        } else {
            return caches
                .appendingPathComponent(encodedDescription)
                .appendingPathComponent(trimmedPath)
        }
    }
    
    /// Get the local cached data URL for the item at the specified path if there is cached data there.
    /// - Parameters:
    ///   - path: The path used to download the data.
    ///   - account: The WebDAV account used to download the data.
    /// - Returns: The URL of the cached data, if it exists.
    func cachedDataURLIfExists(forItemAtPath path: String) -> URL? {
        guard let url = cachedDataURL(forItemAtPath: path) else { return nil }
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
    /// Delete the cached data for the item at the specified path from the disk cache.
    /// - Parameters:
    ///   - path: The path used to download the data.
    ///   - account: The WebDAV account used to download the data.
    /// - Throws: An error if the file couldn't be deleted.
    func deleteCachedDataFromDisk(forItemAtPath path: String) throws {
        guard let url = cachedDataURLIfExists(forItemAtPath: path) else { return }
        try FileManager.default.removeItem(at: url)
    }
    
    /// Delete all cached data from the disk cache.
    /// - Throws: An error if the files couldn't be deleted.
    func deleteAllDiskCachedData() throws {
        guard let url = cacheFolder else { return }
        let fm = FileManager.default
        let filesCachePath = filesCacheURL?.path
        for item in try fm.contentsOfDirectory(atPath: url.path) where item != filesCachePath {
            try fm.removeItem(at: url.appendingPathComponent(item))
        }
    }
    
    //MARK: Thumbnails
    
    /// Get the local cached thumbnail URL for the image at the specified path.
    ///
    /// Gives the URL the thumbnail would be cached at wether or not there is any data cached there.
    /// - Parameters:
    ///   - path: The path that would be used to download the thumbnail.
    ///   - account: The WebDAV account that would be used to download the thumbnail.
    ///   - properties: The properties of the thumbnail.
    /// - Returns: The URL where the thumbnail is or would be cached.
    func cachedThumbnailURL(forItemAtPath path: String, with properties: ThumbnailProperties) -> URL? {
        guard let imageURL = cachedDataURL(forItemAtPath: path) else { return nil }
        
        // If the query is stored in the URL as an actual query, it won't be included when
        // saving to a file, so we have to manually add the query to the filename here.
        let directory = imageURL.deletingLastPathComponent()
        var filename = imageURL.lastPathComponent
        if let query = nextcloudPreviewQuery(at: path, properties: properties)?.dropFirst() {
            filename = query.reduce(filename + "?") { $0 + ($0.last == "?" ? "" : "&") + $1.description}
        }
        return directory.appendingPathComponent(filename)
    }
    
    /// Get the local cached thumbnail URL for the image at the specified path if there is a cached thumbnail there.
    /// - Parameters:
    ///   - path: The path used to download the thumbnail.
    ///   - account: The WebDAV account used to download the thumbnail.
    ///   - properties: The properties of the thumbnail.
    /// - Returns: The URL of the cached thumbnail, if it exists.
    func cachedThumbnailURLIfExists(forItemAtPath path: String, with properties: ThumbnailProperties) -> URL? {
        guard let url = cachedThumbnailURL(forItemAtPath: path, with: properties) else { return nil }
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
    /// Get the URLs of the cached thumbnails for the image at the specified path from the disk cache.
    /// - Parameters:
    ///   - path: The path used to download the thumbnails.
    ///   - account: The WebDAV account used to download the thumbnails.
    /// - Throws: An error if the caches directory couldn't be listed.
    func getAllCachedThumbnailURLs(forItemAtPath path: String) throws -> [URL]? {
        let fm = FileManager.default
        guard let url = cachedDataURL(forItemAtPath: path) else { return nil }
        
        let filename = url.lastPathComponent
        let directory = url.deletingLastPathComponent()
        guard fm.fileExists(atPath: directory.path) else { return nil }
        
        return try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: []).filter { $0.lastPathComponent != filename && $0.lastPathComponent.starts(with: filename) }
    }
    
    /// Delete the cached thumbnail for the image at the specified path from the disk cache.
    /// - Parameters:
    ///   - path: The path used to download the thumbnail.
    ///   - account: The WebDAV account used to download the thumbnail.
    ///   - properties: The properties of the thumbnail.
    /// - Throws: An error if the file couldn't be deleted.
    func deleteCachedThumbnailFromDisk(forItemAtPath path: String, with properties: ThumbnailProperties) throws {
        guard let url = cachedThumbnailURLIfExists(forItemAtPath: path, with: properties) else { return }
        try FileManager.default.removeItem(at: url)
    }
    
    /// Delete the cached thumbnails for the image at the specified path from the disk cache.
    /// - Parameters:
    ///   - path: The path used to download the thumbnails.
    ///   - account: The WebDAV account used to download the thumbnails.
    /// - Throws: An error if the files couldn't be deleted.
    func deleteAllCachedThumbnailsFromDisk(forItemAtPath path: String) throws {
        try getAllCachedThumbnailURLs(forItemAtPath: path)?.forEach { try FileManager.default.removeItem(at: $0) }
    }
    
}

//MARK: Internal

extension WebDAV {
    
    var cacheFolder: URL? {
        let fm = FileManager.default
        guard let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let directory = caches.appendingPathComponent(WebDAV.domain, isDirectory: true)

        if !fm.fileExists(atPath: directory.path) {
            do {
                try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                NSLog("\(error)")
                return nil
            }
        }
        return directory
    }
    
    //MARK: Data Cache
    
    func loadCachedValueFromDisk<Value: Equatable>(cache: Cache<AccountPath, Value>, forItemAtPath path: String, valueFromData: @escaping (_ data: Data) -> Value?) -> Value? {
        guard let url = cachedDataURL(forItemAtPath: path),
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let value = valueFromData(data) else { return nil }
        cache[AccountPath(account: account, path: path)] = value
        return value
    }
    
    func saveDataToDiskCache(_ data: Data, url: URL) throws {
        let directory = url.deletingLastPathComponent()
        
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try data.write(to: url)
    }
    
    func saveDataToDiskCache(_ data: Data, forItemAtPath path: String) throws {
        guard let url = cachedDataURL(forItemAtPath: path) else { return }
        try saveDataToDiskCache(data, url: url)
    }
    
    func cleanupDiskCache(at path: String, files: [WebDAVFile]) throws {
        let fm = FileManager.default
        guard let url = cachedDataURL(forItemAtPath: path),
              fm.fileExists(atPath: url.path) else { return }
        
        let goodFilePaths = files.compactMap { cachedDataURL(forItemAtPath: $0.path)?.path }
        
        let infoPlist = filesCacheURL?.path
        for path in try fm.contentsOfDirectory(atPath: url.path).map({ url.appendingPathComponent($0).path })
        where !goodFilePaths.contains(where: { path.starts(with: $0) })
            && path != infoPlist {
            try fm.removeItem(atPath: path)
        }
    }
    
    //MARK: Thumbnail Cache
    
    func loadCachedThumbnailFromDisk(forItemAtPath path: String, with properties: ThumbnailProperties) -> UIImage? {
        guard let url = cachedThumbnailURL(forItemAtPath: path, with: properties),
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let thumbnail = UIImage(data: data) else { return nil }
        saveToMemoryCache(thumbnail: thumbnail, forItemAtPath: path, with: properties)
        return thumbnail
    }
    
    func loadAllCachedThumbnailsFromDisk(forItemAtPath path: String) throws -> [ThumbnailProperties: UIImage]? {
        guard let urls = try getAllCachedThumbnailURLs(forItemAtPath: path) else { return nil }
        let thumbnails = try urls.compactMap { url -> (ThumbnailProperties, UIImage)? in
            // Load the thumbnail
            let data = try Data(contentsOf: url)
            guard let thumbnail = UIImage(data: data) else { return nil }
            
            // Decode the thumbnail properties
            let properties: ThumbnailProperties
            var contentMode = ThumbnailProperties.ContentMode.fit
            
            let fileName = url.lastPathComponent
            let range = NSRange(location: 0, length: fileName.utf16.count)
            if fileName.range(of: "[?&]a=1", options: .regularExpression) != nil {
                contentMode = .fill
            }
            
            let regex = try NSRegularExpression(pattern: "[?&]x=([0-9]*)&y=([0-9]*)")
            if let match = regex.matches(in: fileName, options: [], range: range).last,
               let xRange = Range(match.range(at: 1), in: fileName),
               let yRange = Range(match.range(at: 2), in: fileName),
               let x = Int(fileName[xRange]),
               let y = Int(fileName[yRange]) {
                properties = ThumbnailProperties((width: x, height: y), contentMode: contentMode)
            } else {
                properties = ThumbnailProperties(contentMode: contentMode)
            }
            
            return (properties, thumbnail)
        }
        
        // Save loaded thumbnails to memory cache
        
        let accountPath = AccountPath(account: account, path: path)
        var cachedThumbnails = thumbnailCache[accountPath] ?? [:]
        cachedThumbnails.merge(thumbnails, uniquingKeysWith: { current, _ in current })
        thumbnailCache[accountPath] = cachedThumbnails
        
        return cachedThumbnails
    }
    
    func saveThumbnailToDiskCache(data: Data, forItemAtPath path: String, with properties: ThumbnailProperties) throws {
        guard let url = cachedThumbnailURL(forItemAtPath: path, with: properties) else { return }
        try saveDataToDiskCache(data, url: url)
    }
    
    //MARK: Files Cache
    
    var filesCacheURL: URL? {
        cacheFolder?.appendingPathComponent("files.plist")
    }
    
    func saveFilesCacheToDisk() {
        guard let fileURL = filesCacheURL else { return }
        do {
            let data = try PropertyListEncoder().encode(filesCache)
            try data.write(to: fileURL)
        } catch {
            NSLog("Error saving files cache: \(error)")
        }
    }
    
    func loadFilesCacheFromDisk() {
        guard let fileURL = filesCacheURL,
              FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let files = try PropertyListDecoder().decode([AccountPath: [WebDAVFile]].self, from: data)
            filesCache.merge(files) { current, _ in current}
        } catch {
            NSLog("Error loading files cache: \(error)")
        }
    }
    
    public func clearFilesDiskCache() {
        guard let fileURL = filesCacheURL,
              FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            NSLog("Error removing files disk cache: \(error)")
        }
    }
    
    public func clearFilesCache() {
        clearFilesMemoryCache()
        clearFilesDiskCache()
    }
    
}
