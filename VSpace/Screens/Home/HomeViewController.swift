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

    private let spacing: CGFloat = 16
    private let sideMargin: CGFloat = 20
    private let sectionInset: CGFloat = 20

    // 3열 기준 지름을 유지해 4행 가로 스크롤로 바뀌어도 셀 크기는 그대로 유지
    private lazy var itemSize: CGFloat = (UIScreen.main.bounds.width - (sideMargin * 2) - (spacing * 2)) / 3
    // 4행 고정 그리드 높이
    private lazy var gridHeight: CGFloat = (sectionInset * 2) + (itemSize * 4) + (spacing * 3)

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: sectionInset, left: sideMargin, bottom: sectionInset, right: sideMargin)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.showsHorizontalScrollIndicator = false
        cv.register(KeepsakeCell.self, forCellWithReuseIdentifier: KeepsakeCell.identifier)
        return cv
    }()

    private let emptyStateView = HomeEmptyStateView()
    private let bottomActionView = HomeBottomActionView()

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
        view.addSubview(emptyStateView)
        view.addSubview(bottomActionView)

        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(gridHeight)
        }

        emptyStateView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(collectionView)
        }

        bottomActionView.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func bindViewModel() {
        // 컬렉션뷰 아이템 바인딩
        viewModel.keepsakes
            .bind(to: collectionView.rx.items(cellIdentifier: KeepsakeCell.identifier, cellType: KeepsakeCell.self)) { _, keepsake, cell in
                cell.configure(with: keepsake)
            }
            .disposed(by: disposeBag)

        // 빈 상태 뷰 토글
        viewModel.keepsakes.map { $0.isEmpty }
            .bind(to: collectionView.rx.isHidden)
            .disposed(by: disposeBag)
        viewModel.keepsakes.map { !$0.isEmpty }
            .bind(to: emptyStateView.rx.isHidden)
            .disposed(by: disposeBag)

        // 아이템 클릭 핸들링
        collectionView.rx.modelSelected(Keepsake.self)
            .subscribe(onNext: { [weak self] keepsake in
                switch keepsake.status {
                case .inProgress:
                    self?.coordinator?.resumeKeepsakeForm(keepsake: keepsake)
                case .done:
                    self?.coordinator?.showKeepsakeDetail(keepsake: keepsake)
                default:
                    self?.coordinator?.showKeepsakeStatus(keepsake: keepsake)
                }
            })
            .disposed(by: disposeBag)

        // "+" 버튼 클릭 핸들링
        bottomActionView.addButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.startCapture()
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
