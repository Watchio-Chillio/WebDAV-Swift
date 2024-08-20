//
//  WebDAVFile.swift
//  WebDAV-Swift
//
//  Created by Isaac Lyons on 11/16/20.
//

import Foundation
import SWXMLHash

public struct WebDAVFile: Identifiable, Codable, Equatable, Hashable {
    
    //MARK: Properties
    
    /// The path of the file.
    public private(set) var path: String
    public private(set) var size: Int
    public private(set) var isDirectory: Bool
    
    public private(set) var lastModified: Date?
    public private(set) var creationDate: Date?
    public private(set) var id: String?
    public private(set) var etag: String?
    
    public init(path: String, id: String?, isDirectory: Bool, lastModified: Date?, size: Int, etag: String?, creationDate: Date?) {
        self.path = path
        self.id = id
        self.isDirectory = isDirectory
        self.lastModified = lastModified
        self.size = size
        self.etag = etag
        self.creationDate = creationDate
    }
    
    init?(xml: XMLIndexer, baseURL: String?) {
        let properties = xml["propstat"][0]["prop"]
        guard var path = xml["href"].element?.text else { return nil }
        
        var date:Date? = nil
        if let dateString = properties["getlastmodified"].element?.text {
            date = WebDAVFile.rfc1123Formatter.date(from: dateString)
        }
        
        var creationdate:Date? = nil
        if let dateString = properties["creationdate"].element?.text {
            creationdate = ISO8601DateFormatter().date(from: dateString)
        }
        
        let id = properties["fileid"].element?.text
        
        var size = 0
        if let sizeString = properties["getcontentlength"].element?.text {
            size = Int(sizeString) ?? 0
        }
        
        let etag = properties["getetag"].element?.text
        let isDirectory = properties["getcontenttype"].element?.text == nil
        
        if let decodedPath = path.removingPercentEncoding {
            path = decodedPath
        }
        
        if let baseURL = baseURL {
            path = WebDAVFile.removing(endOf: baseURL, from: path)
        }
        
        if path.first == "/" {
            path.removeFirst()
        }
        
        self.init(path: path, id: id, isDirectory: isDirectory, lastModified: date, size: size, etag: etag, creationDate: creationdate)
    }
    
    //MARK: Static
    
    static let rfc1123Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return formatter
    }()
        
    private static func removing(endOf string1: String, from string2: String) -> String {
        guard let first = string2.first else { return string2 }
        
        for (i, c) in string1.enumerated() {
            guard c == first else { continue }
            let end = string1.dropFirst(i)
            if string2.hasPrefix(end) {
                return String(string2.dropFirst(end.count))
            }
        }
        
        return string2
    }
    
    public var fileURL: URL {
        URL(fileURLWithPath: path)
    }
    
    /// The file name including extension.
    public var fileName: String {
        return fileURL.lastPathComponent
    }
    
    /// The file extension.
    public var `extension`: String {
        fileURL.pathExtension
    }
    
    /// The name of the file without its extension.
    public var name: String {
        isDirectory ? fileName : fileURL.deletingPathExtension().lastPathComponent
    }
    
}

extension WebDAVFile : CustomStringConvertible {
    public var description: String {
        var desc = "WebDAVFile(path: \(path)"
        if id != nil {
            desc += ", id: " + id!
        }
        desc += ", isDirectory: \(isDirectory)"
        if lastModified != nil {
            desc += ", lastModified: \(WebDAVFile.rfc1123Formatter.string(from: lastModified!))"
        }
        if creationDate != nil {
            desc += ", creationDate: \(WebDAVFile.rfc1123Formatter.string(from: creationDate!))"
        }
        desc += ", size: \(size)"
        if etag != nil {
            desc += ", etag: " + etag!
        }
        return desc
    }

}

