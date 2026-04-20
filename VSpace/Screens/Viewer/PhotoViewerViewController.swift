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
        setupScrollView()
        setupDoubleTapGesture()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard scrollView.zoomScale == scrollView.minimumZoomScale else { return }
        updateImageLayout()
    }

    // MARK: - Setup

    private func setupScrollView() {
        scrollView.delegate = self
        imageView.image = image

        view.addSubview(scrollView)
        scrollView.addSubview(imageView)

        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    /// scrollView의 bounds가 확정된 후 imageView의 frame과 contentSize를 설정합니다.
    /// auto layout 대신 frame 기반으로 배치해 UIScrollView 내 center 오류를 방지합니다.
    private func updateImageLayout() {
        let boundsSize = scrollView.bounds.size
        guard boundsSize.width > 0, boundsSize.height > 0,
              image.size.width > 0, image.size.height > 0 else { return }

        let widthRatio  = boundsSize.width  / image.size.width
        let heightRatio = boundsSize.height / image.size.height
        let fitScale    = min(widthRatio, heightRatio)
        let fittedSize  = CGSize(
            width:  image.size.width  * fitScale,
            height: image.size.height * fitScale
        )

        imageView.frame        = CGRect(origin: .zero, size: fittedSize)
        scrollView.contentSize = fittedSize
        scrollView.isScrollEnabled = false
        centerImageInScrollView()
    }

    /// imageView를 scrollView 중앙에 배치하는 contentInset을 계산합니다.
    /// 콘텐츠가 scrollView보다 작을 때는 여백으로 중앙 정렬하고,
    /// 클 때는 inset을 0으로 설정해 자유롭게 스크롤됩니다.
    private func centerImageInScrollView() {
        let offsetX = max((scrollView.bounds.width  - scrollView.contentSize.width)  / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
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
        centerImageInScrollView()
        scrollView.isScrollEnabled = scrollView.zoomScale > scrollView.minimumZoomScale
    }
}
