//
//  ImagePickerViewController.swift
//  VSpace
//
//  Instagram 스타일 커스텀 사진 피커
//  첫 번째 셀: 카메라 버튼, 나머지 셀: PHAsset 그리드 (4열)
//

import UIKit
import Photos
import SnapKit
import RxSwift
import RxRelay

// MARK: - Cell

private final class CameraCell: UICollectionViewCell {
    static let identifier = "CameraCell"

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "camera.fill",
                           withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium))
        iv.tintColor = .vsSecondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .vsInputBg
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

private final class PhotoCell: UICollectionViewCell {
    static let identifier = "PhotoCell"

    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    var requestId: PHImageRequestID?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        if let id = requestId {
            PHImageManager.default().cancelImageRequest(id)
        }
        imageView.image = nil
        requestId = nil
    }
}

// MARK: - ImagePickerViewController

final class ImagePickerViewController: UIViewController {

    // MARK: - Output

    let imageSelected = PublishRelay<UIImage>()

    // MARK: - Properties

    private var assets: [PHAsset] = []
    private let imageManager = PHCachingImageManager()
    private var thumbnailSize: CGSize = .zero
    private let disposeBag = DisposeBag()

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 2
        let columns: CGFloat = 4
        let side = (UIScreen.main.bounds.width - spacing * (columns - 1)) / columns
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.itemSize = CGSize(width: side, height: side)
        layout.sectionInset = .zero
        thumbnailSize = CGSize(width: side * UIScreen.main.scale, height: side * UIScreen.main.scale)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .vsSurface
        cv.register(CameraCell.self, forCellWithReuseIdentifier: CameraCell.identifier)
        cv.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()
        requestPhotoAuthorization()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = NSLocalizedString("image.picker.title", comment: "")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissPicker)
        )
        navigationItem.leftBarButtonItem?.tintColor = .vsPrimary
    }

    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Authorization

    private func requestPhotoAuthorization() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self?.loadAssets()
                default:
                    self?.showPermissionDeniedAlert()
                }
            }
        }
    }

    private func loadAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var fetched: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in fetched.append(asset) }
        assets = fetched
        collectionView.reloadData()
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("image.picker.permission.title", comment: ""),
            message: NSLocalizedString("image.picker.permission.message", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("alert.default.cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("image.picker.permission.settings", comment: ""), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Camera

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraUnavailableAlert()
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                guard granted else {
                    self?.showCameraUnavailableAlert()
                    return
                }
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.allowsEditing = true
                picker.delegate = self
                self?.present(picker, animated: true)
            }
        }
    }

    private func showCameraUnavailableAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("camera.unavailable.title", comment: ""),
            message: NSLocalizedString("camera.unavailable.message", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("alert.default.cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("image.picker.permission.settings", comment: ""), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Actions

    @objc private func dismissPicker() {
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension ImagePickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count + 1  // +1 for camera cell
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CameraCell.identifier, for: indexPath)
            return cell
        }

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoCell.identifier,
            for: indexPath
        ) as? PhotoCell else { return UICollectionViewCell() }

        let asset = assets[indexPath.item - 1]
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic

        cell.requestId = imageManager.requestImage(
            for: asset,
            targetSize: thumbnailSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            cell.imageView.image = image
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ImagePickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            openCamera()
            return
        }

        let asset = assets[indexPath.item - 1]
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, _ in
            guard let self, let image else { return }
            DispatchQueue.main.async {
                // delegate(PlaneCaptureVC)가 CircularCropVC를 push하므로 dismiss 하지 않음
                self.imageSelected.accept(image)
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ImagePickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        // UIImagePickerController(카메라)만 dismiss, ImagePickerVC 자체는 delegate가 push로 이어감
        picker.dismiss(animated: true) { [weak self] in
            guard let self, let image else { return }
            self.imageSelected.accept(image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
