//
//  PhotoViewerViewController.swift
//  VSpace
//
//  원본 이미지 전체화면 뷰어 — pinch-to-zoom · double tap 줌 토글
//

import UIKit
import SnapKit

final class PhotoViewerViewController: BaseViewController {

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 4.0
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.bouncesZoom = true
        return sv
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // MARK: - Properties

    private let image: UIImage

    // MARK: - Init

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupScrollView()
        setupDoubleTapGesture()
    }


    // MARK: - Setup

    private func setupScrollView() {
        scrollView.delegate = self
        imageView.image = image

        view.addSubview(scrollView)
        scrollView.addSubview(imageView)

        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // imageView 크기를 화면에 맞춤
        let screenSize = UIScreen.main.bounds.size
        let imageSize = image.size
        let widthRatio = screenSize.width / imageSize.width
        let heightRatio = screenSize.height / imageSize.height
        let fitScale = min(widthRatio, heightRatio)
        let fittedSize = CGSize(
            width: imageSize.width * fitScale,
            height: imageSize.height * fitScale
        )

        imageView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(fittedSize.width)
            make.height.equalTo(fittedSize.height)
        }
        scrollView.contentSize = fittedSize
    }

    private func setupDoubleTapGesture() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    // MARK: - Gesture

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let tapPoint = gesture.location(in: imageView)
            let zoomRect = CGRect(
                x: tapPoint.x - imageView.bounds.width / 4,
                y: tapPoint.y - imageView.bounds.height / 4,
                width: imageView.bounds.width / 2,
                height: imageView.bounds.height / 2
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension PhotoViewerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}
