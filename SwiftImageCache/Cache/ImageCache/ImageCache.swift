//
//  ImageCache.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 15.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

/// A facade for memory and disk cache.
public final class ImageCache: ImageCacheInput {

    private let config: Config
    
    private let memoryCache: MemoryCache<NSURL, UIImage>
    
    private let fileManager: FileManager
    
    private let fileResolver: FileResolver
    
    private let imageEncoder: ImageEncoder

    private let imageDecoder: ImageDecoder
    
    private let diskQueue = DispatchQueue(label: "com.polant.SwiftImageCache.ImageCache", qos: .default)
    
    private var cacheDirectoryURL: URL {
        return config.directoryURL
    }
    
    public var maxMemoryCost: Int? {
        get { return memoryCache.maxMemoryCost }
        set { memoryCache.maxMemoryCost = newValue }
    }
    
    public var maxMemoryCount: Int? {
        get { return memoryCache.maxMemoryCount }
        set { memoryCache.maxMemoryCount = newValue }
    }
    
    public var diskCacheSize: Int {
        var cacheSize = 0
        diskQueue.sync {
            cacheSize = self.calculateDiskCacheSize()
        }
        return cacheSize
    }
    
    public var diskCacheCount: Int {
        var count = 0
        diskQueue.sync {
            count = self.calculateDiskCacheItemsCount()
        }
        return count
    }
    
    
    // MARK: - Init
    
    public init(config: Config, dependencies: Dependencies) {
        self.config = config
        self.memoryCache = MemoryCache(config: .default, memoryCostResolver: ImageCostResolver())
        self.fileManager = .default
        self.fileResolver = dependencies.fileResolver
        self.imageEncoder = dependencies.imageEncoder
        self.imageDecoder = dependencies.imageDecoder
        
        let center = NotificationCenter.default
        
        center.addObserver(self,
                           selector: #selector(applicationWillTerminate),
                           name: .UIApplicationWillTerminate,
                           object: nil)
        
        center.addObserver(self,
                           selector: #selector(applicationDidEnterBackground),
                           name: .UIApplicationDidEnterBackground,
                           object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Public API
    
    public func image(forKey key: ImageKey) -> UIImage? {
        if let image = imageFromMemory(forKey: key) {
            return image
        }
        return imageFromDisk(forKey: key).map { image in
            saveImageToMemory(image, forKey: key)
            return image
        }
    }
    
    public func removeImage(forKey key: ImageKey) {
        removeImageFromMemory(forKey: key)
        diskQueue.async {
            try? self.removeImageFromDisk(forKey: key)
        }
    }
    
    public func addImage(_ image: UIImage, forKey key: ImageKey) {
        saveImageToMemory(image, forKey: key)
        diskQueue.async {
            try? self.saveImageToDisk(image, forKey: key)
        }
    }
    
    public func clearMemory() {
        memoryCache.removeAll()
    }
    
    public func clearDisk() {
        diskQueue.async {
            let url = self.cacheDirectoryURL
            try? self.fileManager.removeItem(at: url)
            try? self.fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    
    // MARK: - Notifications
    
    /// Delete old files in background asynchronously
    @objc private func applicationDidEnterBackground() {
        let application = UIApplication.shared
        var taskIdentifier: UIBackgroundTaskIdentifier?
        
        func finishTask() {
            guard let task = taskIdentifier else {
                return
            }
            application.endBackgroundTask(task)
            taskIdentifier = nil
        }
        
        taskIdentifier = application.beginBackgroundTask {
            finishTask()
        }
        deleteExpiredFiles {
            finishTask()
        }
    }
    
    /// Delete old files before terminate
    @objc private func applicationWillTerminate() {
        deleteExpiredFiles()
    }
}

// MARK: - Utils

extension ImageCache {
    
    private func diskFilename(forKey key: ImageKey) -> String {
        return fileResolver.filename(for: key)
    }
    
    private func diskURL(for filename: String) -> URL {
        return cacheDirectoryURL.appendingPathComponent(filename)
    }
    
    private func imageFromMemory(forKey key: ImageKey) -> UIImage? {
        guard config.isMemoryCacheEnabled else {
            return nil
        }
        return memoryCache.object(forKey: key as NSURL)
    }
    
    private func imageFromDisk(forKey key: ImageKey) -> UIImage? {
        let filename = diskFilename(forKey: key)
        let fileURL = diskURL(for: filename)
        do {
            let data = try Data(contentsOf: fileURL)
            return imageDecoder.image(from: data)
        } catch {
            return nil
        }
    }
    
    private func saveImageToMemory(_ image: UIImage, forKey key: ImageKey) {
        if config.isMemoryCacheEnabled {
            memoryCache.setObject(image, forKey: key as NSURL)
        }
    }
    
    private func saveImageToDisk(_ image: UIImage, forKey key: ImageKey) throws {
        guard let data = imageEncoder.encode(image: image) else {
            return
        }
        let filename = diskFilename(forKey: key)
        try saveImageDataToDisk(data, filename: filename)
    }
    
    private func saveImageDataToDisk(_ data: Data, filename: String) throws {
        if !fileManager.fileExists(atPath: cacheDirectoryURL.path) {
            try fileManager.createDirectory(atPath: cacheDirectoryURL.path, withIntermediateDirectories: true, attributes: nil)
        }
        var url = diskURL(for: filename)
        try data.write(to: url)
        
        if config.isExcludedFromBackup {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        }
    }
    
    private func removeImageFromMemory(forKey key: ImageKey) {
        memoryCache.removeObject(forKey: key as NSURL)
    }
    
    private func removeImageFromDisk(forKey key: ImageKey) throws {
        let filename = diskFilename(forKey: key)
        let fileURL = diskURL(for: filename)
        try fileManager.removeItem(at: fileURL)
    }
    
    private func deleteExpiredFiles(completion: (() -> Void)? = nil) {
        diskQueue.async {
            let expirationKey = self.config.expirationResourceKey
            let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, expirationKey, .totalFileAllocatedSizeKey]
            
            guard let fileEnumerator = self.fileManager.enumerator(
                at: self.cacheDirectoryURL,
                includingPropertiesForKeys: Array(resourceKeys),
                options: .skipsHiddenFiles,
                errorHandler: nil) else {
                    return
            }
            
            let expirationDate = Date(timeIntervalSinceNow: -self.config.maxDiskCacheAge)
            
            var cache: [URL: URLResourceValues] = [:]
            var currentCacheSize = 0
            
            var expiredURLs = [URL]()
            
            // 1. Delete expired files
            
            for url in fileEnumerator {
                guard let url = url as? URL else { continue }
                do {
                    let resourceValues = try url.resourceValues(forKeys: resourceKeys)
                    if let isDirectory = resourceValues.isDirectory, isDirectory {
                        continue
                    }
                    if let modifiedDate = resourceValues.date(for: self.config.diskFileExpirationType),
                        modifiedDate < expirationDate {
                        expiredURLs.append(url)
                        continue
                    }
                    
                    if let totalSize = resourceValues.totalFileAllocatedSize {
                        currentCacheSize += totalSize
                        cache[url] = resourceValues
                    }
                } catch {
                    debugPrint(error)
                }
            }
            
            for url in expiredURLs {
                try? self.fileManager.removeItem(at: url)
            }
            
            // 2. Reduce cache size if current size > max size
            self.reduceDiskCacheSize(in: cache, currentCacheSize: currentCacheSize)
            
            completion?()
        }
    }
    
    private func reduceDiskCacheSize(in cache: [URL: URLResourceValues], currentCacheSize: Int) {
        guard let maxCacheSize = config.maxDiskCacheSize, currentCacheSize > maxCacheSize else {
            return
        }
        let sortedFiles = cache.sorted {
            guard let lhs = $0.value.contentModificationDate, let rhs = $1.value.contentModificationDate else {
                return false
            }
            return lhs < rhs
        }
        
        let desiredCacheSize = maxCacheSize / 2
        var currentCacheSize = currentCacheSize
        
        for (url, resourceValue) in sortedFiles {
            do {
                try fileManager.removeItem(at: url)
                guard let size = resourceValue.totalFileAllocatedSize else {
                    continue
                }
                currentCacheSize -= size
                guard currentCacheSize > desiredCacheSize else {
                    break
                }
            } catch {
                debugPrint(error)
            }
        }
    }
    
    private func calculateDiskCacheItemsCount() -> Int {
        guard let fileEnumerator = fileManager.enumerator(atPath: cacheDirectoryURL.path) else {
            return 0
        }
        return fileEnumerator.allObjects.count
    }
    
    private func calculateDiskCacheSize() -> Int {
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .totalFileAllocatedSizeKey]
        
        guard let fileEnumerator = fileManager.enumerator(
            at: cacheDirectoryURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: .skipsHiddenFiles,
            errorHandler: nil) else {
                return 0
        }
        
        var cacheSize = 0
        
        for url in fileEnumerator {
            guard let url = url as? URL else {
                continue
            }
            do {
                let resourceValues = try url.resourceValues(forKeys: resourceKeys)
                if let isDirectory = resourceValues.isDirectory, isDirectory {
                    continue
                }
                if let totalSize = resourceValues.totalFileAllocatedSize {
                    cacheSize += totalSize
                }
            } catch {
                debugPrint(error)
            }
        }
        
        return cacheSize
    }
}

// MARK: - Config

extension ImageCache {
    
    public struct Config {
        
        public enum DiskFileExpirationType {
            case accessDate
            case modificationDate
        }
        
        public let directoryURL: URL
        public let diskFileExpirationType: DiskFileExpirationType
        public let maxDiskCacheAge: TimeInterval
        public let maxDiskCacheSize: Int?
        public let isMemoryCacheEnabled: Bool
        public let isExcludedFromBackup: Bool
        
        public init(directoryURL: URL,
                    diskFileExpirationType: DiskFileExpirationType,
                    isMemoryCacheEnabled: Bool,
                    maxDiskCacheAge: TimeInterval = 60 * 60 * 24 * 7,
                    maxDiskCacheSize: Int? = nil,
                    isExcludedFromBackup: Bool) {
            self.directoryURL = directoryURL
            self.diskFileExpirationType = diskFileExpirationType
            self.maxDiskCacheAge = maxDiskCacheAge
            self.maxDiskCacheSize = maxDiskCacheSize
            self.isMemoryCacheEnabled = isMemoryCacheEnabled
            self.isExcludedFromBackup = isExcludedFromBackup
        }
    }
    
    public struct Dependencies {
        public let fileResolver: FileResolver
        public let imageEncoder: ImageEncoder
        public let imageDecoder: ImageDecoder
        
        public init(fileResolver: FileResolver, imageEncoder: ImageEncoder, imageDecoder: ImageDecoder) {
            self.fileResolver = fileResolver
            self.imageEncoder = imageEncoder
            self.imageDecoder = imageDecoder
        }
    }
}

// MARK: - Extensions

private extension ImageCache.Config {
    
    var expirationResourceKey: URLResourceKey {
        switch diskFileExpirationType {
        case .accessDate:
            return .contentAccessDateKey
        case .modificationDate:
            return .contentModificationDateKey
        }
    }
}

private extension URLResourceValues {
    
    func date(for expirationType: ImageCache.Config.DiskFileExpirationType) -> Date? {
        switch expirationType {
        case .accessDate:
            return contentAccessDate
        case .modificationDate:
            return contentModificationDate
        }
    }
}
