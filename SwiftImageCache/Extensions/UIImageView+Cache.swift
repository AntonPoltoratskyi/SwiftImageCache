//
//  UIImageView+Cache.swift
//  SwiftImageCache
//
//  Created by Anton Poltoratskyi on 15.07.2018.
//  Copyright © 2018 Anton Poltoratskyi. All rights reserved.
//

import UIKit

extension UIImageView {
    
    typealias ProgressHandler = (CGFloat) -> Void
    typealias CompletionHandler = (URL, UIImage) -> Void
    
    func setImage(with url: URL,
                  placeholder: UIImage? = nil,
                  progressHandler: ProgressHandler? = nil,
                  completionHandler: CompletionHandler? = nil) {
        
        
    }
}
