//
//  ImageCache.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 15.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

public final class ImageCache: ImageCacheInput {

    private let config: Config
    
    private let memoryCache: MemoryCache<NSURL, UIImage>
    
    private let fileResolver: FileResolver
    
    private let imageEncoder: ImageEncoder

    private let imageDecoder: ImageDecoder
    
    private let fileManager: FileManager
    
    private let diskQueue = DispatchQueue(label: "com.polant.SwiftImageCache.ImageCache", qos: .default)
    
    public var maxMemoryCost: Int? {
        get { return memoryCache.maxMemoryCost }
        set { memoryCache.maxMemoryCost = newValue }
    }
    
    public var maxMemoryCount: Int? {
        get { return memoryCache.maxMemoryCount }
        set { memoryCache.maxMemoryCount = newValue }
    }
    
    public var diskCacheSize: Int {
        return 0 // TODO: calculate cache size on the disk
    }
    
    public var discCacheCount: Int {
        return 0 // TODO: calculate cache count on the disk
    }
    
    
    // MARK: - Init
    
    public init(config: Config, dependencies: Dependencies) {
        self.config = config
        self.memoryCache = MemoryCache(config: .init(), costResolver: ImageCacheCostResolver())
        self.fileResolver = dependencies.fileResolver
        self.imageEncoder = dependencies.imageEncoder
        self.imageDecoder = dependencies.imageDecoder
        self.fileManager = .default
        
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
    
    public func image(forKey key: ImageCacheKey) -> UIImage? {
        if let image = imageFromMemory(forKey: key) {
            return image
        }
        return imageFromDisk(forKey: key).map { image in
            saveImageToMemory(image, forKey: key)
            return image
        }
    }
    
    public func removeImage(forKey key: ImageCacheKey) {
        removeImageFromMemory(forKey: key)
        diskQueue.async {
            try? self.removeImageFromDisk(forKey: key)
        }
    }
    
    public func addImage(_ image: UIImage, forKey key: ImageCacheKey) {
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
            let url = self.config.directoryURL
            try? self.fileManager.removeItem(at: url)
            try? self.fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    
    // MARK: - Notifications
    
    @objc private func applicationDidEnterBackground() {
        // delete old files in background asynchronously
        deleteExpiredFiles()
    }
    
    @objc private func applicationWillTerminate() {
        deleteExpiredFiles()
    }
    
    private func deleteExpiredFiles() {
        // TODO: delete old files
    }
}

// MARK: - Utils

extension ImageCache {
    
    private func cacheFilename(forKey key: ImageCacheKey) -> String {
        return fileResolver.filename(for: key)
    }
    
    private func cacheURL(for filename: String) -> URL {
        return config.directoryURL.appendingPathComponent(filename)
    }
    
    private func imageFromMemory(forKey key: ImageCacheKey) -> UIImage? {
        guard config.isMemoryCacheEnabled else {
            return nil
        }
        return memoryCache.object(forKey: key as NSURL)
    }
    
    private func imageFromDisk(forKey key: ImageCacheKey) -> UIImage? {
        let filename = cacheFilename(forKey: key)
        let fileURL = cacheURL(for: filename)
        do {
            let data = try Data(contentsOf: fileURL)
            return imageDecoder.image(from: data)
        } catch {
            return nil
        }
    }
    
    private func saveImageToMemory(_ image: UIImage, forKey key: ImageCacheKey) {
        if config.isMemoryCacheEnabled {
            memoryCache.setObject(image, forKey: key as NSURL)
        }
    }
    
    private func saveImageToDisk(_ image: UIImage, forKey key: ImageCacheKey) throws {
        guard let data = imageEncoder.encode(image: image) else {
            return
        }
        let filename = cacheFilename(forKey: key)
        try saveImageDataToDisk(data, filename: filename)
    }
    
    private func saveImageDataToDisk(_ data: Data, filename: String) throws {
        let cacheContainerURL = config.directoryURL
        if !fileManager.fileExists(atPath: cacheContainerURL.path) {
            try fileManager.createDirectory(atPath: cacheContainerURL.path, withIntermediateDirectories: true, attributes: nil)
        }
        var url = cacheURL(for: filename)
        try data.write(to: url)
        
        if config.isExcludedFromBackup {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        }
    }
    
    private func removeImageFromMemory(forKey key: ImageCacheKey) {
        memoryCache.removeObject(forKey: key as NSURL)
    }
    
    private func removeImageFromDisk(forKey key: ImageCacheKey) throws {
        let filename = cacheFilename(forKey: key)
        let fileURL = cacheURL(for: filename)
        try fileManager.removeItem(at: fileURL)
    }
}

// MARK: - Config

extension ImageCache {
    
    public struct Config {
        public let directoryURL: URL
        public let isMemoryCacheEnabled: Bool
        public let isExcludedFromBackup: Bool
        
        public init(directoryURL: URL, isMemoryCacheEnabled: Bool, isExcludedFromBackup: Bool) {
            self.directoryURL = directoryURL
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
