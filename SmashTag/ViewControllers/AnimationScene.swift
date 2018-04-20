//
//  AnimationScene.swift
//  SmashTag
//
//  Created by Bill on 4/19/18.
//
//

import SpriteKit

class AnimationScene: SKScene {
    var animationBackground: SKSpriteNode!
    var  addBubbles : Bool = true
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(size: CGSize ) {
        
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0, y: 1.0)
        animationBackground = SKSpriteNode(color: UIColor.white, size: size)
        animationBackground.anchorPoint = CGPoint(x: 0, y: 1.0)
        animationBackground.position = CGPoint(x: 0, y: 0)
        self.addChild(animationBackground)
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        if addBubbles { addBubble() }
        floatBubbles()
        removeExcessBubbles()
        print ("XXX")
        
    }
    
    func addBubble() {
        
       
        func getRandomColor() -> UIColor{
            
            var randomRed:CGFloat = CGFloat(drand48())
            
            var randomGreen:CGFloat = CGFloat(drand48())
            
            var randomBlue:CGFloat = CGFloat(drand48())
            
            return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
            
        }
        
        let bubble = SKShapeNode(circleOfRadius: CGFloat(arc4random_uniform(40))) //10
        bubble.strokeColor = getRandomColor()
        //let bubble = SKSpriteNode(color: UIColor.white, size: CGSize(width: 10, height: 10))
        animationBackground.addChild(bubble)
        let startingPoint = CGPoint(x: CGFloat(arc4random_uniform(UInt32(size.width))), y: (-1)*size.height)
        bubble.position = startingPoint
    }
    
    func floatBubbles() {
        for child in animationBackground.children {
            let xOffset: CGFloat = CGFloat(arc4random_uniform(40)) - 20.0
            let yOffset: CGFloat = 30.0
            let newLocation = CGPoint(x: child.position.x + xOffset, y: child.position.y + yOffset)
            let moveAction = SKAction.move(to: newLocation, duration: 0.2)
            child.run(moveAction)
        }
    }
    
    func removeExcessBubbles() {
        for child in animationBackground.children {
            if child.position.y > 0 {
                child.removeFromParent()
                addBubbles = false
                self.view?.removeFromSuperview()
            }
        }
    }
}
