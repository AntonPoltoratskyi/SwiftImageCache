//
//  DataTask.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 29.09.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import Foundation

final class DataTask {
    
    private let task: URLSessionDataTask
    
    var expectedContentLength: Int64 = 0
    
    var data = Data()
    
    var completion: (() -> Void)?
    
    var progress: ((Double) -> Void)?
    
    init(task: URLSessionDataTask) {
        self.task = task
    }
    
    func resume() {
        task.resume()
    }
    
    func cancel() {
        task.cancel()
    }
}
