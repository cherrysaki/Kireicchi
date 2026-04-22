import SwiftUI

struct CaptureView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ZStack {
            // 全画面カメラプレビュー
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .ignoresSafeArea()
                .overlay(
                    VStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 100))
                            .foregroundColor(.white.opacity(0.7))
                        Text("カメラプレビュー")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                        Text("部屋全体が見えるように撮影してください")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                )
                .onTapGesture {
                    showImagePicker = true
                }
            
            VStack {
                // 左上: ✕ボタン
                HStack {
                    Button(action: {
                        navigationRouter.navigateBack()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // 中央下: ズーム表示（「1×」）
                Text("1×")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(16)
                
                Spacer().frame(height: 40)
                
                // 最下部中央: 円形シャッターボタン
                Button(action: {
                    // 仮の画像で解析画面に遷移
                    let dummyImage = UIImage(systemName: "photo") ?? UIImage()
                    let imageData = dummyImage.pngData() ?? Data()
                    navigationRouter.navigate(to: .analyzing(imageData: imageData))
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 64, height: 64)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if let image = newValue {
                let imageData = image.pngData() ?? Data()
                navigationRouter.navigate(to: .analyzing(imageData: imageData))
            }
        }
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        CaptureView()
            .environmentObject(NavigationRouter())
    }
}