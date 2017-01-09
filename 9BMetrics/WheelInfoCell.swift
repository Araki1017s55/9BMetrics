//
//  WheelInfoCell.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 9/1/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//

import UIKit

class WheelInfoCell: UITableViewCell {

    @IBOutlet weak var fTitle: UILabel!
    @IBOutlet weak var fSubtitle: UILabel!
    @IBOutlet weak var fDistance: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
