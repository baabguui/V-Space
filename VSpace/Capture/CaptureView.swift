//
//  CaptureView.swift
//  VSpace
//
//  ObjectCapture 세션 SwiftUI 뷰
//

import SwiftUI
import RealityKit

// MARK: - UIViewRepresentable: VLongButton

private struct VLongButtonView: UIViewRepresentable {
    let title: String
    let action: () -> Void

    func makeUIView(context: Context) -> VLongButton {
        let button = VLongButton(title: title)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: VLongButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    final class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }

        @objc func tapped() { action() }
    }
}

// MARK: - CaptureView

@available(iOS 17.0, *)
struct CaptureView: View {
    let viewModel: CaptureViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            ObjectCaptureView(session: viewModel.session)
            
            if case .ready = viewModel.session.state {
                VLongButtonView(title: "대상 감지하기", action: viewModel.startDetecting)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            } else if case .detecting = viewModel.session.state {
                VLongButtonView(title: "스캔 시작하기", action: viewModel.startCapturing)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
    }
}
