//
//  BaseViewController.swift
//  VSpace
//
//  재사용 가능한 Alert 헬퍼를 포함하는 베이스 뷰컨트롤러
//

import UIKit
import RxSwift

class BaseViewController: UIViewController {

    // MARK: - Properties

    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .vsWhite
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    // MARK: - Alert Helper

    /// 재사용 가능한 Alert 표시 메서드
    /// - Parameters:
    ///   - title: Alert 제목
    ///   - message: Alert 메시지
    ///   - confirmTitle: 확인 버튼 타이틀 (기본: "확인")
    ///   - confirmStyle: 확인 버튼 스타일 (기본: .default / 삭제 시 .destructive 사용)
    ///   - cancelTitle: 취소 버튼 타이틀 (nil이면 취소 버튼 미표시)
    ///   - onConfirm: 확인 버튼 탭 콜백
    ///   - onCancel: 취소 버튼 탭 콜백
    func showAlert(
        title: String,
        message: String,
        confirmTitle: String = NSLocalizedString("alert.default.confirm", comment: ""),
        confirmStyle: UIAlertAction.Style = .default,
        cancelTitle: String? = NSLocalizedString("alert.default.cancel", comment: ""),
        onConfirm: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if let cancelTitle {
            let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
                onCancel?()
            }
            alert.addAction(cancelAction)
        }

        let confirmAction = UIAlertAction(title: confirmTitle, style: confirmStyle) { _ in
            onConfirm?()
        }
        alert.addAction(confirmAction)

        present(alert, animated: true)
    }
}
