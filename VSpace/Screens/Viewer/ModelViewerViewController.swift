//
//  ModelViewerViewController.swift
//  VSpace
//
//  ARView(.nonAR) 기반 USDZ 3D 모델 뷰어
//  제스처: 1손가락 pan(회전) · pinch(스케일)
//  저장: 원형 가이드 오버레이 위에서 모델 조작 → snapshot → 원형 크롭 → onSave(croppedImage)
//

import UIKit
import RealityKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - CropGuideOverlay

private final class CropGuideOverlay: UIView {

    var diameter: CGFloat = 0 { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), diameter > 0 else { return }
        let circleRect = CGRect(
            x: (rect.width - diameter) / 2,
            y: (rect.height - diameter) / 2,
            width: diameter,
            height: diameter
        )
        UIColor.black.withAlphaComponent(0.45).setFill()
        ctx.fill(rect)
        ctx.setBlendMode(.clear)
        ctx.fillEllipse(in: circleRect)
        ctx.setBlendMode(.normal)
        UIColor.white.withAlphaComponent(0.6).setStroke()
        ctx.setLineWidth(1.5)
        ctx.strokeEllipse(in: circleRect.insetBy(dx: 0.75, dy: 0.75))
    }
}

// MARK: - ModelViewerViewController

@available(iOS 17.0, *)
final class ModelViewerViewController: BaseViewController {

    // MARK: - ViewerMode

    private enum ViewerMode {
        case capture(onSave: (UIImage) -> Void, onResume: () -> Void)
        case viewerOnly
    }

    // MARK: - Properties

    private let arView: ARView = {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        return view
    }()

    private let cropOverlay = CropGuideOverlay()

    private let saveButton = VLongButton(title: NSLocalizedString("viewer.button.save", comment: ""), style: .accent)
    private let resumeButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(NSLocalizedString("viewer.button.rescan", comment: ""), for: .normal)
        btn.setTitleColor(.vsWhite, for: .normal)
        btn.titleLabel?.font = .vsBody
        btn.backgroundColor = .clear
        return btn
    }()

    private let modelURL: URL
    private let mode: ViewerMode
    private var anchorEntity: AnchorEntity?
    private var currentPinchScale: Float = 1.0

    private var cropDiameter: CGFloat { UIScreen.main.bounds.width - 48 }

    // MARK: - Init

    init(modelURL: URL, onSave: @escaping (UIImage) -> Void, onResume: @escaping () -> Void) {
        self.modelURL = modelURL
        self.mode = .capture(onSave: onSave, onResume: onResume)
        super.init(nibName: nil, bundle: nil)
    }

    init(modelURL: URL, viewerOnly: Bool) {
        self.modelURL = modelURL
        self.mode = .viewerOnly
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setupGestures()
        loadModel()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if case .capture = mode {
            cropOverlay.diameter = cropDiameter
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if case .capture = mode {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if case .capture = mode {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    // MARK: - Setup

    private func configureView() {
        view.addSubview(arView)
        arView.environment.background = .color(.white)
        arView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        guard case .capture = mode else { return }

        view.addSubview(cropOverlay)
        view.addSubview(saveButton)
        view.addSubview(resumeButton)

        cropOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        saveButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(resumeButton.snp.top).offset(-14)
        }

        resumeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(40)
        }
    }

    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        arView.addGestureRecognizer(pinch)
    }

    private func loadModel() {
        Task {
            do {
                let entity = try await Entity(contentsOf: modelURL)

                let bounds = entity.visualBounds(relativeTo: nil)
                let maxExtent = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
                guard maxExtent > 0 else { return }

                let normalizedScale = Float(0.5) / maxExtent
                entity.scale = SIMD3<Float>(repeating: normalizedScale)
                entity.position = -bounds.center * normalizedScale

                let anchor = AnchorEntity(world: [0, 0, -1])
                anchor.addChild(entity)

                await MainActor.run {
                    arView.scene.addAnchor(anchor)
                    anchorEntity = anchor
                }
            } catch {
                // 로딩 실패 — 뷰어는 빈 상태로 유지
            }
        }
    }

    private func bind() {
        guard case .capture(let onSave, let onResume) = mode else { return }

        saveButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.captureAndSave(onSave: onSave)
            }
            .disposed(by: disposeBag)

        resumeButton.rx.tap
            .bind(with: self) { owner, _ in
                onResume()
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Capture

    private func captureAndSave(onSave: @escaping (UIImage) -> Void) {
        // 배경을 투명하게 전환 후 스냅샷 → 모델만 캡쳐
        arView.environment.background = .color(.clear)
        arView.snapshot(saveToHDR: false) { [weak self] image in
            guard let self, let image else { return }
            DispatchQueue.main.async {
                self.arView.environment.background = .color(.white)
            }
            let cropped = self.cropToCircle(from: image)
            DispatchQueue.main.async {
                onSave(cropped)
            }
        }
    }

    /// snapshot 이미지에서 원형 가이드 영역(cropDiameter)을 300×300 원형 PNG로 추출
    private func cropToCircle(from image: UIImage) -> UIImage {
        let outputSide: CGFloat = 300
        let diameter = cropDiameter

        // arView 좌표계 기준으로 원의 위치 계산
        let viewWidth = arView.bounds.width
        let viewHeight = arView.bounds.height
        let originX = (viewWidth - diameter) / 2
        let originY = (viewHeight - diameter) / 2

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: outputSide, height: outputSide),
            format: format
        )

        return renderer.image { ctx in
            ctx.cgContext.addEllipse(in: CGRect(x: 0, y: 0, width: outputSide, height: outputSide))
            ctx.cgContext.clip()
            // ARView.snapshot은 Metal 렌더러 특성상 scale=1, size=픽셀 크기로 반환될 수 있음
            // image.size.width / viewWidth 비율로 포인트↔픽셀 좌표계 차이를 보정
            let imgToView = image.size.width / viewWidth
            let scale = outputSide / diameter
            image.draw(in: CGRect(
                x: -originX * scale,
                y: -originY * scale,
                width: image.size.width * scale / imgToView,
                height: image.size.height * scale / imgToView
            ))
        }
    }

    // MARK: - Gesture Handlers

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let anchor = anchorEntity else { return }
        let translation = recognizer.translation(in: arView)
        recognizer.setTranslation(.zero, in: arView)

        let sensitivity: Float = 0.5 * .pi / 180
        let angleY = Float(translation.x) * sensitivity
        let angleX = Float(translation.y) * sensitivity

        let rotY = simd_quatf(angle: angleY, axis: [0, 1, 0])
        let rotX = simd_quatf(angle: angleX, axis: [1, 0, 0])
        anchor.orientation = simd_normalize(rotY * rotX * anchor.orientation)
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let anchor = anchorEntity else { return }

        switch recognizer.state {
        case .began:
            currentPinchScale = anchor.scale.x
        case .changed:
            let rawScale = currentPinchScale * Float(recognizer.scale)
            let newScale = min(max(rawScale, 0.1), 3.0)
            anchor.scale = SIMD3<Float>(repeating: newScale)
        default:
            break
        }
    }
}
