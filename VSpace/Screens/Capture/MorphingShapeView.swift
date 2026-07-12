//
//  MorphingShapeView.swift
//  VSpace
//
//  원 → 네모 → 세모로 무한 반복 모핑되는 로딩 인디케이터
//

import UIKit

final class MorphingShapeView: UIView {

    // MARK: - Constants

    private static let pointCount = 12
    private static let morphAnimationKey = "morph"

    // MARK: - UI

    private let shapeLayer = CAShapeLayer()

    // MARK: - State

    private var isAnimating = false

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    /// 도형 레이어의 기본 스타일(흰 배경 + 검정 테두리 윤곽선)을 구성합니다
    private func setupLayer() {
        shapeLayer.fillColor = UIColor.vsWhite.cgColor
        shapeLayer.strokeColor = UIColor.vsText.cgColor
        shapeLayer.lineWidth = 4
        shapeLayer.lineJoin = .round
        shapeLayer.lineCap = .round
        layer.addSublayer(shapeLayer)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        guard bounds.width > 0, bounds.height > 0 else { return }
        if isAnimating {
            startMorphAnimation()
        } else {
            shapeLayer.path = Self.circlePath(center: centerPoint, radius: shapeRadius, pointCount: Self.pointCount).cgPath
        }
    }

    // MARK: - Public

    /// 원→네모→세모 무한 루프 모핑 애니메이션을 시작합니다
    func startAnimating() {
        isAnimating = true
        layoutIfNeeded()
        startMorphAnimation()
    }

    /// 모핑 애니메이션을 멈추고 레이어에서 제거합니다
    func stopAnimating() {
        isAnimating = false
        shapeLayer.removeAnimation(forKey: Self.morphAnimationKey)
    }

    // MARK: - Private

    private var centerPoint: CGPoint {
        CGPoint(x: bounds.midX, y: bounds.midY)
    }

    private var shapeRadius: CGFloat {
        max(0, min(bounds.width, bounds.height) / 2 - shapeLayer.lineWidth)
    }

    /// 원 → 네모 → 세모 → 원 순서의 CAKeyframeAnimation을 만들어 무한 반복시킵니다
    private func startMorphAnimation() {
        guard bounds.width > 0, bounds.height > 0 else { return }

        let center = centerPoint
        let radius = shapeRadius
        let circle = Self.circlePath(center: center, radius: radius, pointCount: Self.pointCount).cgPath
        let square = Self.polygonPath(sides: 4, center: center, radius: radius, pointCount: Self.pointCount).cgPath
        let triangle = Self.polygonPath(sides: 3, center: center, radius: radius, pointCount: Self.pointCount).cgPath

        let animation = CAKeyframeAnimation(keyPath: "path")
        animation.values = [circle, square, triangle, circle]
        animation.keyTimes = [0, 0.333, 0.667, 1.0]
        animation.duration = 3.0
        animation.calculationMode = .linear
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false

        shapeLayer.path = circle
        shapeLayer.add(animation, forKey: Self.morphAnimationKey)
    }

    /// 정다각형의 꼭짓점 좌표를 시계 방향으로 계산합니다
    /// - Parameters:
    ///   - sides: 변의 개수 (3 또는 4)
    ///   - center: 다각형 중심
    ///   - radius: 중심에서 꼭짓점까지의 거리
    /// - Returns: 꼭짓점 좌표 배열
    private static func regularPolygonVertices(sides: Int, center: CGPoint, radius: CGFloat) -> [CGPoint] {
        let baseAngle: CGFloat = sides == 4 ? (-3 * .pi / 4) : (-.pi / 2)
        return (0..<sides).map { index in
            let angle = baseAngle + CGFloat(index) * (2 * .pi / CGFloat(sides))
            return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        }
    }

    /// 네모/세모처럼 직선 변으로 이루어진 도형의 경로를 생성합니다
    /// 각 변을 pointCount / sides개로 등분하고, 컨트롤포인트를 양 끝점과 동일하게 두어
    /// 직선을 나타내는 큐빅 베지어로 구성합니다 (원 경로와 점 개수를 맞춰 매끄러운 모핑을 위함)
    /// - Parameters:
    ///   - sides: 변의 개수 (3 또는 4)
    ///   - center: 도형 중심
    ///   - radius: 중심에서 꼭짓점까지의 거리
    ///   - pointCount: 전체 경로의 앵커 포인트 개수 (sides의 배수여야 함)
    /// - Returns: 도형 경로
    private static func polygonPath(sides: Int, center: CGPoint, radius: CGFloat, pointCount: Int) -> UIBezierPath {
        let vertices = regularPolygonVertices(sides: sides, center: center, radius: radius)
        let pointsPerSide = pointCount / sides
        var samples: [CGPoint] = []
        for sideIndex in 0..<sides {
            let start = vertices[sideIndex]
            let end = vertices[(sideIndex + 1) % sides]
            for step in 0..<pointsPerSide {
                let t = CGFloat(step) / CGFloat(pointsPerSide)
                samples.append(CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t))
            }
        }

        let path = UIBezierPath()
        path.move(to: samples[0])
        for index in 0..<samples.count {
            let p0 = samples[index]
            let p1 = samples[(index + 1) % samples.count]
            path.addCurve(to: p1, controlPoint1: p0, controlPoint2: p1)
        }
        path.close()
        return path
    }

    /// 원 경로를 pointCount개의 큐빅 베지어 세그먼트로 근사해 생성합니다
    /// - Parameters:
    ///   - center: 원 중심
    ///   - radius: 반지름
    ///   - pointCount: 전체 경로의 앵커 포인트 개수
    /// - Returns: 원 경로
    private static func circlePath(center: CGPoint, radius: CGFloat, pointCount: Int) -> UIBezierPath {
        let step = 2 * CGFloat.pi / CGFloat(pointCount)
        let handleLength = radius * (4.0 / 3.0) * tan(step / 4)

        let anchors: [(point: CGPoint, tangent: CGPoint)] = (0..<pointCount).map { index in
            let angle = -CGFloat.pi / 2 + CGFloat(index) * step
            let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            let tangent = CGPoint(x: -sin(angle), y: cos(angle))
            return (point, tangent)
        }

        let path = UIBezierPath()
        path.move(to: anchors[0].point)
        for index in 0..<pointCount {
            let current = anchors[index]
            let next = anchors[(index + 1) % pointCount]
            let controlPoint1 = CGPoint(
                x: current.point.x + current.tangent.x * handleLength,
                y: current.point.y + current.tangent.y * handleLength
            )
            let controlPoint2 = CGPoint(
                x: next.point.x - next.tangent.x * handleLength,
                y: next.point.y - next.tangent.y * handleLength
            )
            path.addCurve(to: next.point, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        }
        path.close()
        return path
    }
}
