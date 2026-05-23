import AVFoundation
import Photos
import SwiftUI

struct NewWorkoutView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var capturedImage: UIImage?
    @State private var showDeniedAlert = false
    @State private var deniedAlertMessage = ""
    @State private var showReview = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.brand)
                    Text("New Workout")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.textPri)
                    Text("Tap + to scan a workout image")
                        .font(.system(size: 14))
                        .foregroundColor(.textTer)
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBG, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.brand)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            handleCameraAction()
                        } label: {
                            Label("Take a Picture", systemImage: "camera")
                        }
                        Button {
                            handlePhotosAction()
                        } label: {
                            Label("Choose from Photos", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.brand)
                    }
                }
            }
            .navigationDestination(isPresented: $showReview) {
                if let image = capturedImage {
                    ReviewWorkoutView(image: image) {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera, onDismiss: navigateIfImageCaptured) {
                ImagePicker(sourceType: .camera, selectedImage: $capturedImage)
                    .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showPhotoPicker, onDismiss: navigateIfImageCaptured) {
                ImagePicker(sourceType: .photoLibrary, selectedImage: $capturedImage)
            }
            .alert("Permission Required", isPresented: $showDeniedAlert) {
                Button("No", role: .cancel) { }
                Button("Yes") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text(deniedAlertMessage)
            }
        }
    }

    // MARK: - Navigation

    private func navigateIfImageCaptured() {
        if capturedImage != nil {
            showReview = true
        }
    }

    // MARK: - Permission handling

    private func handleCameraAction() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            capturedImage = nil
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    capturedImage = nil
                    showCamera = true
                }
            }
        case .denied, .restricted:
            deniedAlertMessage = "Allow FitLog to access your camera to take workout photos?"
            showDeniedAlert = true
        @unknown default:
            break
        }
    }

    private func handlePhotosAction() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            capturedImage = nil
            showPhotoPicker = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    capturedImage = nil
                    showPhotoPicker = true
                }
            }
        case .denied, .restricted:
            deniedAlertMessage = "Allow FitLog to access your photos to import workout images?"
            showDeniedAlert = true
        @unknown default:
            break
        }
    }
}

// MARK: - ImagePicker (UIImagePickerController wrapper)

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
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
