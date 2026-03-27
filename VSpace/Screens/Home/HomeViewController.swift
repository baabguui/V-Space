//
//  HomeViewController.swift
//  VSpace
//
//  Created by baabguui on 3/23/26.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import RealityKit

final class HomeViewController: BaseViewController {

    // MARK: - Properties

    private weak var coordinator: HomeCoordinating?
    private let viewModel: HomeViewModel

    // MARK: - UI
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 16
        let sideMargin: CGFloat = 20
        // 3열 그리드 너비 계산
        let itemWidth = (UIScreen.main.bounds.width - (sideMargin * 2) - (spacing * 2)) / 3
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 20, left: sideMargin, bottom: 20, right: sideMargin)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.register(KeepsakeCell.self, forCellWithReuseIdentifier: KeepsakeCell.identifier)
        cv.register(AddKeepsakeCell.self, forCellWithReuseIdentifier: AddKeepsakeCell.identifier)
        return cv
    }()

    // MARK: - Init
    
    init(coordinator: HomeCoordinating, viewModel: HomeViewModel) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .vsSurface
        setupLayout()
        bindViewModel()
    }

    // MARK: - Setup

    private func setupLayout() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func bindViewModel() {
        // 컬렉션뷰 아이템 바인딩
        viewModel.items
            .bind(to: collectionView.rx.items) { collectionView, index, item in
                let indexPath = IndexPath(item: index, section: 0)
                switch item {
                case .keepsake(let keepsake):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KeepsakeCell.identifier, for: indexPath) as? KeepsakeCell else {
                        return UICollectionViewCell()
                    }
                    cell.configure(with: keepsake)
                    return cell
                case .add:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddKeepsakeCell.identifier, for: indexPath) as? AddKeepsakeCell else {
                        return UICollectionViewCell()
                    }
                    return cell
                }
            }
            .disposed(by: disposeBag)
        
        // 아이템 클릭 핸들링
        collectionView.rx.modelSelected(HomeItem.self)
            .subscribe(onNext: { [weak self] item in
                switch item {
                case .keepsake(let keepsake):
                    if keepsake.status == .inProgress {
                        self?.coordinator?.resumeKeepsakeForm(keepsake: keepsake)
                    } else {
                        // TODO: - Detail 이동
                    }
                case .add:
                    self?.startCapture()
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Navigation

    private func startCapture() {
        if #available(iOS 17.0, *) {
            coordinator?.showCaptureTypeSelect()
        } else {
            showAlert(
                title: NSLocalizedString("alert.unsupported.title", comment: ""),
                message: NSLocalizedString("alert.unsupported.message", comment: ""),
                cancelTitle: nil
            )
        }
    }

}
