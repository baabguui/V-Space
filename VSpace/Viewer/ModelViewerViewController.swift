//
//  ModelViewerViewController.swift
//  VSpace
//
//  ARKit + SceneKit 기반 USDZ 3D 모델 뷰어
//  제스쳐: 1손가락 pan(회전) · pinch(스케일) · rotation(Z축 회전)
//

import UIKit
import QuickLook
import SnapKit

final class ModelViewerViewController: BaseViewController {

    // MARK: - Properties
    private lazy var previewController: QLPreviewController = {
        let pc = QLPreviewController()
        pc.dataSource = self
        pc.currentPreviewItemIndex = 0
        return pc
    }()
    
    private let modelURL: URL

    // MARK: - Init

    init(modelURL: URL) {
        self.modelURL = modelURL
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
    }
    
    private func configureView() {
        self.addChild(previewController)
        view.addSubview(previewController.view)
        
        previewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        previewController.didMove(toParent: self)
    }
}

extension ModelViewerViewController: QLPreviewControllerDataSource {
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        modelURL as NSURL
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
}
