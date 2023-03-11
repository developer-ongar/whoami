import SwiftUI
import RealityKit

struct YouComAIARKitTutorView : View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let sphere = MeshResource.generateSphere(radius: 0.1)
        let material = SimpleMaterial(color: .red, isMetallic: true)
        let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
        let anchorEntity = AnchorEntity(plane: .horizontal)
        anchorEntity.addChild(sphereEntity)
        arView.scene.addAnchor(anchorEntity)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct YouComAIARKitTutorView_Previews : PreviewProvider {
    static var previews: some View {
        YouComAIARKitTutorView()
    }
}
