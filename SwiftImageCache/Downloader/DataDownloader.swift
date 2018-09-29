//
//  DataDownloader.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 29.09.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

final class DataDownloader: NSObject {
    
    typealias ProgressHandler = (Double) -> Void
    
    typealias CompletionHandler = (URL?) -> Void
    
    
    // MARK: - Dependencies
    
    private var urlSession: URLSession!
    
    
    // MARK: - Properties
    
    private var tasks: [DataTask] = []
    
    
    // MARK: - Init
    
    override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    
    // MARK: - Download
    
    func download(at url: URL, progress: @escaping ProgressHandler, completion: @escaping CompletionHandler) {
        let task = DataTask(task: urlSession.dataTask(with: url))
        task.resume()
    }
}

// MARK: - URLSessionDelegate

extension DataDownloader: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
    }
}
