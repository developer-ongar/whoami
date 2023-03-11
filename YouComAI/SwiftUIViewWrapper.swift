class SwiftUIViewWrapper: UIViewRepresentable {

    typealias UIViewType = UIView

    func makeUIView(context: Context) -> UIView {
        return UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let swiftUIView = SwiftUIView()
        let host = UIHostingController(rootView: swiftUIView)

        addChild(host)
        uiView.addSubview(host.view)
        host.didMove(toParent: self)
    }
}


//class MyViewController: UIViewController {

    //override func viewDidLoad() {
        //super.viewDidLoad()

        //let swiftUIViewWrapper = SwiftUIViewWrapper()
        //view.addSubview(swiftUIViewWrapper)
        //swiftUIViewWrapper.frame = view.bounds
    //}
//}



