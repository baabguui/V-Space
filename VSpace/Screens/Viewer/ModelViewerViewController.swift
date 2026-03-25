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
import RxSwift
import RxCocoa

final class ModelViewerViewController: BaseViewController {

    // MARK: - Properties
    private lazy var previewController: QLPreviewController = {
        let pc = QLPreviewController()
        pc.dataSource = self
        pc.currentPreviewItemIndex = 0
        return pc
    }()
    
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
    private let onSave: () -> Void
    private let onResume: () -> Void

    // MARK: - Init

    init(modelURL: URL, onSave: @escaping () -> Void, onResume: @escaping () -> Void) {
        self.modelURL = modelURL
        self.onSave = onSave
        self.onResume = onResume
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
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func bind() {
        saveButton.rx.tap.bind(with: self) { owner, _ in
            owner.onSave()
        }
        .disposed(by: disposeBag)
        
        resumeButton.rx.tap.bind(with: self) { owner, _ in
            owner.onResume()
            owner.navigationController?.popViewController(animated: true)
        }
        .disposed(by: disposeBag)
    }
    
    private func configureView() {
        self.addChild(previewController)
        view.addSubview(previewController.view)
        view.addSubview(saveButton)
        view.addSubview(resumeButton)
        
        previewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        saveButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
        }
        
        resumeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(saveButton.snp.bottom).offset(14)
            make.bottom.equalToSuperview().inset(40)
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
