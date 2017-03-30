//
//  StoreInfo.swift
//  Maps
//
//  Created by HuangShih-Hsuan on 29/03/2017.
//  Copyright © 2017 HuangShih-Hsuan. All rights reserved.
//

import UIKit

class StoreInfo: NSObject {
    
    let name: String?
    let rating: Double?
    let number: String?
    let distance: String?
    let arrivalTime: String?
    let address: String?
    let image: URL?
    
    init(result: [String: Any], completionHandler: @escaping (StoreInfo?, Error?) -> Void) {
        name = result["name"] as! String
        rating = result["rating"] as! Double
        number = result["phone"] as! String
        distance = ""
        arrivalTime = ""
        address = result["address"] as? String
        image = URL(string: "\(result["photo"] as! String)")
    }

}
