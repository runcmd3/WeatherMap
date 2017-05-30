//
//  TableViewCell.swift
//  WeatherMap
//
//  Created by David Argilan on 5/29/17.
//  Copyright © 2017 David Argilan. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {
    var longitude:Double!
    var latitude:Double!
    
    //custom table
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var myImage: UIImageView!
    @IBOutlet weak var condition: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
