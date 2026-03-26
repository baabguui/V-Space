//
//  CircularCropViewController.swift
//  VSpace
//
//  사용자가 원형 크롭 영역 내 이미지 위치·크기를 pan/pinch로 조정하는 화면.
//  UIScrollView 기반 네이티브 제스처 지원.
//  결과 이미지: 300×300px PNG (투명 배경 원형)
//

import UIKit
import SnapKit
import RxRelay

// MARK: - CropOverlayView

private final class CropOverlayView: UIView {

    var circleDiameter: CGFloat = 0 {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let circleRect = CGRect(
            x: (rect.width - circleDiameter) / 2,
            y: (rect.height - circleDiameter) / 2,
            width: circleDiameter,
            height: circleDiameter
        )
        UIColor.black.withAlphaComponent(0.55).setFill()
        ctx.fill(rect)

        ctx.setBlendMode(.clear)
        ctx.fillEllipse(in: circleRect)

        ctx.setBlendMode(.normal)
        UIColor.white.withAlphaComponent(0.6).setStroke()
        ctx.setLineWidth(1.5)
        ctx.strokeEllipse(in: circleRect.insetBy(dx: 0.75, dy: 0.75))
    }
}

// MARK: - CircularCropViewController

final class CircularCropViewController: UIViewController {

    // MARK: - Output

    let cropConfirmed = PublishRelay<UIImage>()

    // MARK: - Properties

    private let image: UIImage
    private let cropDiameter: CGFloat
    private var isInitialLayoutDone = false

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 4.0
        sv.bouncesZoom = true
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.clipsToBounds = true
        return sv
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleToFill
        return iv
    }()

    private let overlayView = CropOverlayView()

    private let confirmButton = VLongButton(
        title: NSLocalizedString("form.button.complete", comment: ""),
        style: .black
    )

    // MARK: - Init

    init(image: UIImage, cropDiameter: CGFloat = UIScreen.main.bounds.width - 48) {
        self.image = image
        self.cropDiameter = cropDiameter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not available") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupNavigationBar()
        setupScrollView()
        setupOverlay()
        setupConfirmButton()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !isInitialLayoutDone else { return }
        isInitialLayoutDone = true
        setupImageViewLayout()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = NSLocalizedString("circular.crop.title", comment: "")
        navigationController?.navigationBar.tintColor = .vsWhite
    }

    private func setupScrollView() {
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(80)
        }
        imageView.image = image
        scrollView.addSubview(imageView)
    }

    private func setupOverlay() {
        overlayView.circleDiameter = cropDiameter
        view.addSubview(overlayView)
        overlayView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(80)
        }
    }

    private func setupConfirmButton() {
        view.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
    }

    private func setupImageViewLayout() {
        let scrollBounds = scrollView.bounds.size
        guard scrollBounds.width > 0, scrollBounds.height > 0 else { return }

        // 이미지가 스크롤 영역 전체와 크롭 원을 모두 채우는 최소 스케일
        let scale = max(
            scrollBounds.width / image.size.width,
            scrollBounds.height / image.size.height,
            cropDiameter / image.size.width,
            cropDiameter / image.size.height
        )

        let imageViewSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        imageView.frame = CGRect(origin: .zero, size: imageViewSize)
        scrollView.contentSize = imageViewSize

        // 초기 위치: 이미지 중앙이 크롭 원 중앙과 일치
        let offsetX = max(0, (imageViewSize.width - scrollBounds.width) / 2)
        let offsetY = max(0, (imageViewSize.height - scrollBounds.height) / 2)
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
    }

    // MARK: - Actions

    @objc private func confirmTapped() {
        cropConfirmed.accept(renderCroppedImage())
    }

    // MARK: - Render

    private func renderCroppedImage() -> UIImage {
        let outputSide: CGFloat = 300
        let outputSize = CGSize(width: outputSide, height: outputSide)

        // 크롭 원의 중심 (scrollView 좌표계 기준 가시 영역 중심)
        let visibleCenter = CGPoint(
            x: scrollView.bounds.midX,
            y: scrollView.bounds.midY
        )

        // imageView 좌표계로 변환 (줌, 스크롤 오프셋 반영)
        let centerInImageView = scrollView.convert(visibleCenter, to: imageView)

        // 크롭 반지름을 imageView 좌표계로 환산
        let halfCropInImageView = (cropDiameter / 2) / scrollView.zoomScale

        // imageView display 좌표 → 실제 이미지 픽셀 변환 비율
        let pixelScaleX = image.size.width / imageView.bounds.width
        let pixelScaleY = image.size.height / imageView.bounds.height

        let cropRect = CGRect(
            x: (centerInImageView.x - halfCropInImageView) * pixelScaleX,
            y: (centerInImageView.y - halfCropInImageView) * pixelScaleY,
            width: halfCropInImageView * 2 * pixelScaleX,
            height: halfCropInImageView * 2 * pixelScaleY
        )

        let drawScale = outputSide / cropRect.width
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0  // 출력 300×300px 고정
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)

        return renderer.image { ctx in
            ctx.cgContext.addEllipse(in: CGRect(origin: .zero, size: outputSize))
            ctx.cgContext.clip()
            image.draw(in: CGRect(
                x: -cropRect.minX * drawScale,
                y: -cropRect.minY * drawScale,
                width: image.size.width * drawScale,
                height: image.size.height * drawScale
            ))
        }
    }
}

// MARK: - UIScrollViewDelegate

extension CircularCropViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // 이미지가 스크롤 영역보다 작아질 경우 중앙 정렬 유지
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        imageView.center = CGPoint(
            x: scrollView.contentSize.width / 2 + offsetX,
            y: scrollView.contentSize.height / 2 + offsetY
        )
    }
}
