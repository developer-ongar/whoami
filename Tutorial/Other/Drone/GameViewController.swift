import UIKit
import SceneKit
import ARKit
import SpriteKit

class GameViewController: UIViewController {
    
    // MARK: - LocalConstants
    
    private struct LocalConstants {
        static let joystickSize = CGSize(width: 160, height: 150)
        static let joystickPoint = CGPoint(x: 0, y: 0)
        static let environmentalMap = ""
        static let buttonTitle = "".uppercased()
        static let disarmTitle = "".uppercased()
    }
    
    // MARK: - Private Properties
    
    private lazy var padView1: SKView = {
        let view = SKView(frame: CGRect(x:40, y: 20, width:140, height: 140))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var padView2: SKView = {
        let view = SKView(frame: CGRect(x:660, y: UIScreen.main.bounds.height - 140, width:140, height: 140))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
//    private let droneQueue = DispatchQueue(label: "com.froleeyo.dronequeue")
    
    private lazy var armMissilesButton: UIButton = {
        let button = UIButton()
        button.setTitle(LocalConstants.buttonTitle, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.black)
        button.frame = CGRect(origin: CGPoint(x:670, y: UIScreen.main.bounds.height - 190), size: CGSize(width: 140, height: 40))
        button.layer.borderColor = UIColor.red.cgColor
        button.backgroundColor = UIColor.red
        button.layer.borderWidth = 3
        return button
    }()
    
    private var session: ARSession {
        return sceneView.session
    }
    
    @IBOutlet private weak var sceneView: GameSceneView!
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DeviceOrientation.shared.set(orientation: .landscapeRight)
        UIApplication.shared.isIdleTimerDisabled = true
        setupTracking()
        sceneView.setup()
        DispatchQueue.main.asyncAfter(deadline: .now() +  1) { [self] in
            sceneView.addSubview(padView1)
            sceneView.addSubview(padView2)
            setupPadScene()
            sceneView.positionHUD()
            sceneView.addSubview(armMissilesButton)
            armMissilesButton.addTarget(self, action: #selector(didTapUIButton), for: .touchUpInside)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - Private Methods
    
    private func setupTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        let sceneReconstruction: ARWorldTrackingConfiguration.SceneReconstruction = .meshWithClassification
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(sceneReconstruction) {
            configuration.sceneReconstruction = sceneReconstruction
        }
        configuration.frameSemantics = .sceneDepth
        sceneView.automaticallyUpdatesLighting = false
        if let environmentMap = UIImage(named: LocalConstants.environmentalMap) {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func setupPadScene() {
        let scene = JoystickScene()
        scene.point = LocalConstants.joystickPoint
        scene.size = LocalConstants.joystickSize
        scene.joystickDelegate = self
        scene.stickNum = 2
        padView1.presentScene(scene)
        padView1.ignoresSiblingOrder = true
        let scene2 = JoystickScene()
        scene2.point = LocalConstants.joystickPoint
        scene2.size = LocalConstants.joystickSize
        scene2.joystickDelegate = self
        scene2.stickNum = 1
        padView2.presentScene(scene2)
        padView2.ignoresSiblingOrder = true
    }
    
    // MARK: - Actions
    
    @objc func didTapUIButton() {
        sceneView.toggleArmMissiles()
        let title = sceneView.missilesArmed() ? LocalConstants.disarmTitle : LocalConstants.buttonTitle
        armMissilesButton.setTitle(title, for: .normal)
    }
}

extension GameViewController: ARSCNViewDelegate {
   
}

// MARK: - JoystickSceneDelegate

extension GameViewController: JoystickSceneDelegate {
    
    func update(xValue: Float, stickNum: Int) {
        if stickNum == 1 {
            let scaled = (xValue) * 0.00025
            sceneView.rotate(value: scaled)
        } else if stickNum == 2 {
            let scaled = (xValue) * 0.5
            sceneView.moveSides(value: scaled)
        }
    }
    
    func update(yValue: Float, stickNum: Int) {
        if stickNum == 1 {
            let scaled = (yValue) * 0.5
            sceneView.moveForward(value: scaled)
        } else if stickNum == 2 {
            let scaled = (yValue) * 0.5
            sceneView.changeAltitude(value: scaled)
        }
    }
    
    func tapped() {
        sceneView.shootMissile()
    }
}
