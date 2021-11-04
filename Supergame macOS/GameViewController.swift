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
import Foundation
import ClientRuntime
import AWSClientRuntime
import AWSS3

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
        
        let motdTask = Task { () in
            print("**** In motd task")
            let motd = await self.readTextFile("motd.txt")
            if (motd != "") {
                setMOTD(motd)
            }
            print("**** Exiting motd task")
        }
        print("Exiting viewDidLoad")
    }
    
    
    /// Read the text file from Amazon S3 whose path matches the one given.
    ///
    /// - Parameter name: The path of the file to read
    /// - Returns:              A `String` containing the entire contents of the specified file.
    ///                         If the MOTD file isn't found or an error occurs, returns an empty
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

        // Read the file
        
        let motdInput = GetObjectInput(bucket: "supergame-datastore", key: "text/\(name)")
        do {
            let output = try await s3.getObject(input: motdInput)
            
            if let bytes = output.body?.toBytes() {
                text = String(decoding: bytes.toData(), as: UTF8.self)
            }
        } catch {
            dump(error, name: "Attempting to read the file \"\(name)\"")
        }
        /*
        s3.getObject(input: motdInput) { (result) in
            switch(result) {
            case .success(let output):
                if let bytes = output.body?.toBytes() {
                    text = String(decoding: bytes.toData(), as: UTF8.self)
                }
            case .failure(let error):
                dump(error, name: "Attempting to load MOTD text file from S3")
            }
        }
        */

        return text
    }
    
    /// Set the contents of the Message of the Day text box in the scene to the given string.
    /// - Parameter motd: The text to show in the MOTD box
    ///
    func setMOTD(_ motd: String) {
        let motdLabel = skScene?.childNode(withName: "//motdLabel") as? SKLabelNode
        motdLabel?.text = motd
    }
}

