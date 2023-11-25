import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {

    // Sprites
    var player     = PlayerSprite()        // Physics category - Player
    var wallPair   = SKNode()
    var scoreLabel = SKLabelNode()
    
    // Sprite Actions
    var moveAndRemove = SKAction()
    
    // Game State
    var gameStarted = Bool()
    var score       = Int()
    
    // Sound Effects
    var scoreSoundEffect: AVAudioPlayer?
    
    private func endGame(_ debugMessage: String = "Player hit Wall") {
//        gameStarted = false
        print("End: \(debugMessage)")
        setScore(to: 0)
    }
    
    private func setScore(to points: Int) {
        self.score = points
        print("Score: \(points)")
        scoreLabel.text = "\(points)x"
    }
    
    private func addScore(_ points: Int = 1) {
        let newScore = self.score + points
        setScore(to: newScore)
        scoreSoundEffect?.play()
    }
    
    private func loadSoundEffects() {
        if let path = Bundle.main.path(forResource: "sfx_point", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            do {
                scoreSoundEffect = try AVAudioPlayer(contentsOf: url)
            } catch {
                print("Construction of AVAudioPlayer for \"sfx_point.mp3\" threw an exception")
            }
        } else {
            print("sfx_point.mp3 not found in bundle")
        }
    }
    
    private func createScoreLabel() -> SKLabelNode {
        let label = SKLabelNode()
        let frameWidthHalved  = frame.width / 2
        let frameHeightHalved = frame.height / 2
        
        let posX = if UIDevice.isPhone() {
            CGPoint(
                x: frame.midX - (frameWidthHalved  * 0.6),
                y: frame.midY + (frameHeightHalved * 0.7)
            )
        } else {
            CGPoint(
                x: frame.midX,
                y: frame.midY + (frameHeightHalved * 0.2)
            )
        }
        
        label.text = ""
        label.fontColor = UIColor.yellow
        label.fontSize = 65
        label.fontName = "SF Pro"
        label.position = posX
        label.zPosition = 4
        
        return label
    }
    
    private func calculateCloudPosition() -> CGPoint {
        let frameHeightHalved = frame.height / 2
        let yMultiplier = if UIDevice.isPhone() {
            0.95
        } else {
            0.35
        }
        
        return CGPoint(
            x: frame.midX,
            y: frame.midY + (frameHeightHalved * yMultiplier)
        )
    }
    
    private func calculateGroundPosition() -> CGPoint {
        let frameHeightHalved = frame.height / 2
        let yMultiplier = if UIDevice.isPhone() {
            0.95
        } else {
            0.35
        }
        
        return CGPoint(
            x: frame.midX,
            y: frame.midY - (frameHeightHalved * yMultiplier)
        )
    }
    
    private func createWalls() {
        wallPair = SKNode()
        
        let topWall   = SKSpriteNode(imageNamed: "PipeTop")
        let btmWall   = SKSpriteNode(imageNamed: "PipeBottom")
        let scoreNode = SKSpriteNode(imageNamed: "Coin")
        
        let frameHeightHalved = frame.height / 2
        let frameWidthHalved  = frame.width / 2
        let wallX             = frame.midX + (frameWidthHalved  * 0.9)
        let topWallY          = frame.midY + (frameHeightHalved * 0.65)
        let btmWallY          = frame.midY - (frameHeightHalved * 0.6)
        
        topWall.position = CGPoint(x: wallX, y: topWallY)
        btmWall.position = CGPoint(x: wallX, y: btmWallY)
        topWall.setScale(0.6)
        btmWall.setScale(0.6)
        
        let randomPositions = [0.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0]
        let random = randomPositions.randomElement() ?? 0.0
        btmWall.position.y = btmWall.position.y + random
        
     // let scoreNodeX = wallX + (btmWall.frame.width / 2) // If the score needs to be at the end of the pipe
        
        scoreNode.size = CGSize(width: 50, height: 50)
        scoreNode.position = CGPoint(x: wallX, y: 30)
        
        // Wall Physics Bodies
        topWall.physicsBody = SKPhysicsBody(rectangleOf: topWall.size)
        topWall.physicsBody?.categoryBitMask    = PhysicsCategory.Wall
        topWall.physicsBody?.collisionBitMask   = PhysicsCategory.Player
        topWall.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        topWall.physicsBody?.isDynamic = false
        topWall.physicsBody?.affectedByGravity = false
        
        btmWall.physicsBody = SKPhysicsBody(rectangleOf: btmWall.size)
        btmWall.physicsBody?.categoryBitMask    = PhysicsCategory.Wall
        btmWall.physicsBody?.collisionBitMask   = PhysicsCategory.Player
        btmWall.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        btmWall.physicsBody?.isDynamic = false
        btmWall.physicsBody?.affectedByGravity = false
        
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: 250))
        scoreNode.physicsBody?.categoryBitMask    = PhysicsCategory.Score
        scoreNode.physicsBody?.collisionBitMask   = 0
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        scoreNode.physicsBody?.affectedByGravity = false
        scoreNode.physicsBody?.isDynamic = false
        
        wallPair.addChild(topWall)
        wallPair.addChild(btmWall)
        wallPair.addChild(scoreNode)
        wallPair.run(moveAndRemove)
        
        self.addChild(wallPair)
    }
    
    // GameScene Functions
    override func didMove(to view: SKView) {
        self.backgroundColor = UIColor.cyan
        self.physicsWorld.contactDelegate = self
        
        loadSoundEffects()
        
        // Static Sprites
        let background = SKSpriteNode(imageNamed: "Background")
        background.scale(to: frame.size)
        background.zPosition = -1
        
        let cloud = CloudSprite(width: frame.width, height: 100)
        cloud.position = calculateCloudPosition()
        
        let ground = GroundSprite(width: frame.width, height: 100)
        ground.position = calculateGroundPosition()

        // Dynamic Sprites
        scoreLabel = createScoreLabel()
        player.position = CGPoint(x: frame.midX, y: frame.midY)
        
        addChild(background)
        addChild(scoreLabel)
        addChild(cloud)
        addChild(ground)
        addChild(player)
    }
    
    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        if (!gameStarted) {
            player.physicsBody?.affectedByGravity = true
            gameStarted = true
            
            let spawn = SKAction.run({
                () in
                
                self.createWalls()
            })
            let delay          = SKAction.wait(forDuration: 3.5)
            let spawnDelay     = SKAction.sequence([spawn, delay])
            let spawnDelayLoop = SKAction.repeatForever(spawnDelay)
            
            self.run(spawnDelayLoop)
            
            let distance = CGFloat(self.frame.width + wallPair.frame.width)
            let movePipes = SKAction.moveBy(x: -distance, y: 0, duration: TimeInterval(0.008 * distance))
            let removePipes = SKAction.removeFromParent()
            
            moveAndRemove = SKAction.sequence([movePipes, removePipes])
            
            player.flap()
        } else {
            player.flap()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    // From SKPhysicsContactDelegate
    // Collision between two bodies
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        let maskA = bodyA.categoryBitMask
        let maskB = bodyB.categoryBitMask
        
        if ((maskA == PhysicsCategory.Player && maskB == PhysicsCategory.Wall) || (maskB == PhysicsCategory.Player && maskA == PhysicsCategory.Wall)) {
            endGame("Player hit Wall")
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } else if ((maskA == PhysicsCategory.Player && maskB == PhysicsCategory.Boundary) || (maskB == PhysicsCategory.Player && maskA == PhysicsCategory.Boundary)) {
            endGame("Player hit Ground")
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else if ((maskA == PhysicsCategory.Player && maskB == PhysicsCategory.Score) || (maskB == PhysicsCategory.Player && maskA == PhysicsCategory.Score)) {
            addScore()
            
            if (maskA == PhysicsCategory.Score) {
                bodyA.node?.removeFromParent()
            } else if (maskB == PhysicsCategory.Score){
                bodyB.node?.removeFromParent()
            }
        }
    }
}
