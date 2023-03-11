import SwiftUI
import RealityKit

struct YouComAIARKitRenameView : View {
    @State var currentObjectIndex = 0
    var objectNames = ["sphere", "cube"]
    
    var body: some View {
        ARViewContainer(objectName: objectNames[currentObjectIndex]).edgesIgnoringSafeArea(.all)
            .onTapGesture {
                self.currentObjectIndex = (self.currentObjectIndex + 1) % self.objectNames.count
            }
    }
}

struct ARViewContainer: UIViewRepresentable {
    var objectName: String

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let mesh: MeshResource
        
        switch objectName {
        case "sphere":
            mesh = MeshResource.generateSphere(radius: 0.1)
        case "cube":
            mesh = MeshResource.generateBox(width: 0.1, height: 0.1, depth: 0.1)
        default:
            mesh = MeshResource.generateSphere(radius: 0.1)
        }

        let material = SimpleMaterial(color: .red, isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        let anchorEntity = AnchorEntity(plane: .horizontal)
        anchorEntity.addChild(entity)
        arView.scene.addAnchor(anchorEntity)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct YouComAIARKitRenameView_Previews : PreviewProvider {
    static var previews: some View {
       YouComAIARKitRenameView()
    }
}
