import AVFoundation
import Photos
import PhotosUI
import SwiftUI

struct NewWorkoutView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var cameraImage: UIImage?
    @State private var selectedImages: [UIImage] = []
    @State private var showDeniedAlert = false
    @State private var deniedAlertMessage = ""
    @State private var showReview = false
    @State private var showManualEntry = false

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

                    Button {
                        showManualEntry = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.pencil")
                            Text("Add Workout")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.brand)
                        .cornerRadius(.rMD)
                    }
                    .padding(.top, 8)
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
                ReviewWorkoutView(images: selectedImages) {
                    dismiss()
                }
            }
            .navigationDestination(isPresented: $showManualEntry) {
                ReviewWorkoutView {
                    dismiss()
                }
            }
            .fullScreenCover(isPresented: $showCamera, onDismiss: handleCameraDismiss) {
                ImagePicker(sourceType: .camera, selectedImage: $cameraImage)
                    .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showPhotoPicker, onDismiss: handlePhotosDismiss) {
                MultiImagePicker(selectedImages: $selectedImages)
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

    private func handleCameraDismiss() {
        if let image = cameraImage {
            selectedImages = [image]
            cameraImage = nil
            showReview = true
        }
    }

    private func handlePhotosDismiss() {
        if !selectedImages.isEmpty {
            showReview = true
        }
    }

    // MARK: - Permission handling

    private func handleCameraAction() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraImage = nil
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    cameraImage = nil
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
        selectedImages = []
        showPhotoPicker = true
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

// MARK: - MultiImagePicker (PHPickerViewController wrapper)

struct MultiImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiImagePicker

        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else {
                parent.dismiss()
                return
            }

            var loadedImages = Array<UIImage?>(repeating: nil, count: results.count)
            let lock = NSLock()
            let group = DispatchGroup()

            for (index, result) in results.enumerated() {
                guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        lock.lock()
                        loadedImages[index] = image
                        lock.unlock()
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.parent.selectedImages = loadedImages.compactMap { $0 }
                self.parent.dismiss()
            }
        }
    }
}
