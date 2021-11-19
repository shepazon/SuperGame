//
// GameViewController.swift
// 
//
// Creation date: 10/26/21
// Creator: Shepherd, Eric
//

import Cocoa
import SpriteKit
import GameplayKit

class GameViewController: NSViewController {
    var skScene: SKScene? = nil
    var skView: SKView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        skScene = GameScene.newGameScene()
        
        // Present the scene
        skView = self.view as? SKView
        skView?.presentScene(skScene)
        
        skView?.ignoresSiblingOrder = true
        
        skView?.showsFPS = true
        skView?.showsNodeCount = true
    }
}

