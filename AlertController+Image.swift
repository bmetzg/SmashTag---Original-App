//
//  AlertControllwe+Image
//  SmashTag
//
//  Created by Bill on 4/18/18.
//
//

import UIKit

extension UIAlertController {
    
    func addPhoto ( image : UIImage ) {
        let imgAction = UIAlertAction(title: "", style: .default, handler: nil )
        imgAction.isEnabled = false
        imgAction.setValue ( image.withRenderingMode (.alwaysOriginal ) , forKey : "image" )
        self.addAction ( imgAction )
        
    }
}


