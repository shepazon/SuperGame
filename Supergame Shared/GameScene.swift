//
// GameScene.swift
// 
//
// Creation date: 10/26/21
// Creator: Shepherd, Eric
//

import SpriteKit
import Foundation
import ClientRuntime
import AWSClientRuntime
import AWSS3

class GameScene: SKScene {
    fileprivate var label : SKLabelNode?
    fileprivate var spinnyNode : SKShapeNode?

    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        return scene
    }
    
    /// Set up the scene by starting animations and setting contents of variable nodes
    /// 
    func setUpScene() {
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 4.0
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
            
            #if os(watchOS)
                // For watch we just periodically create one of these and let it spin
                // For other platforms we let user touch/mouse events create these
                spinnyNode.position = CGPoint(x: 0.0, y: 0.0)
                spinnyNode.strokeColor = SKColor.red
                self.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 2.0),
                                                                   SKAction.run({
                                                                       let n = spinnyNode.copy() as! SKShapeNode
                                                                       self.addChild(n)
                                                                   })])))
            #endif
        }
        
        updateMOTD()
        //getMOTD2()
    }

    #if os(watchOS)
    override func sceneDidLoad() {
        self.setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    #endif

    func makeSpinny(at pos: CGPoint, color: SKColor) {
        if let spinny = self.spinnyNode?.copy() as! SKShapeNode? {
            spinny.position = pos
            spinny.strokeColor = color
            self.addChild(spinny)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }

    /// Load the message of the day from the file on S3 and display it in
    /// the MOTD label box.
    ///
    func updateMOTD() {
        Task() {
            var motd: String = ""
            
            do {
                let s3 = try S3Client()
                
                let motdInput = GetObjectInput(bucket: "supergame-datastore", key: "text/motd.txt")
                let output = try await s3.getObject(input: motdInput)
                
                if let bytes = output.body?.toBytes() {
                    motd = String(decoding: bytes.toData(), as: UTF8.self)
                }
            } catch {
                motd = ""
            }
            
            setMOTD(motd)
        }
    }

    /// Read the text file from Amazon S3 whose key matches the one given.
    ///
    /// - Parameter name: The key of the file to read
    /// - Returns:              A `String` containing the entire contents of the specified file.
    ///                         If the text file isn't found or an error occurs, returns an empty
    ///                         string.
    ///
    func readTextFile(_ name: String) async -> String {
        let s3Config: S3Client.S3ClientConfiguration
        var text: String = ""
        
        /// Set up the configuration to log requests and responses and
        /// create the new S3 client object, `s3`.
        
        do {
            s3Config = try S3Client.S3ClientConfiguration()
            s3Config.clientLogMode = ClientLogMode.requestAndResponse
        } catch {
            dump(error, name: "Creating configuration object")
            exit(1)
        }
        let s3 = S3Client(config: s3Config)

        // Read the file from S3
        
        let motdInput = GetObjectInput(bucket: "supergame-datastore", key: name)
        do {
            let output = try await s3.getObject(input: motdInput)
            
            if let bytes = output.body?.toBytes() {
                text = String(decoding: bytes.toData(), as: UTF8.self)
            }
        } catch {
            dump(error, name: "Attempting to read the file \"\(name)\"")
        }

        return text
    }
    
    /// Set the contents of the Message of the Day text box in the scene to the given string.
    /// - Parameter motd: The text to show in the MOTD box
    ///
    func setMOTD(_ motd: String) {
        let motdLabel = self.childNode(withName: "//motdLabel") as? SKLabelNode
        motdLabel?.text = motd
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.green)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.blue)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.red)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.makeSpinny(at: t.location(in: self), color: SKColor.red)
        }
    }
    
   
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        self.makeSpinny(at: event.location(in: self), color: SKColor.green)
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.blue)
    }
    
    override func mouseUp(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.red)
    }

}
#endif

