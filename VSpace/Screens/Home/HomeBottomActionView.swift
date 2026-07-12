//
//  HomeBottomActionView.swift
//  VSpace
//

import UIKit
import SnapKit

/// 홈 화면 하단의 장식 배경 + "+" 플로팅 버튼을 담당하는 뷰입니다.
/// keepsake 리스트가 비어있는 상태와 채워진 상태 모두에서 동일하게 노출됩니다.
/// 이 뷰 자체의 높이는 상위 뷰(HomeViewController)의 제약에 따라 유동적으로 결정되며,
/// 내부 장식 요소들은 뷰 하단을 기준으로 배치되어 높이가 변해도 항상 화면 최하단에 고정되어 보입니다.
final class HomeBottomActionView: UIView {
  
  // MARK: - Properties
  
  let addButton = VRoundButton(style: .black, size: .normal, iconName: "plus")
  
  private let gradientLayer: CAGradientLayer = {
    let layer = CAGradientLayer()
    layer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
    layer.locations = [0, 1]
    return layer
  }()
  
  private let gradientView = UIView()
  
  private let grass8ImageView = UIImageView(image: UIImage(named: "grass8"))
  private let grass2ImageView = UIImageView(image: UIImage(named: "grass2"))
  private let grass3RightImageView = UIImageView(image: UIImage(named: "grass3"))
  private let grass3LeftImageView = UIImageView(image: UIImage(named: "grass3"))
  private let grass5ImageView = UIImageView(image: UIImage(named: "grass5"))
  
  // MARK: - Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupLayout()
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not available")
  }
  
  // MARK: - Layout
  
  override func layoutSubviews() {
    super.layoutSubviews()
    gradientLayer.frame = gradientView.bounds
  }
  
  private func setupLayout() {
    [grass8ImageView, grass2ImageView, grass3RightImageView, grass3LeftImageView, grass5ImageView].forEach {
      $0.contentMode = .scaleAspectFit
    }
    
    gradientView.layer.addSublayer(gradientLayer)
    
    addSubview(gradientView)
    addSubview(grass8ImageView)
    addSubview(grass3RightImageView)
    addSubview(grass3LeftImageView)
    addSubview(grass5ImageView)
    addSubview(addButton)
    addSubview(grass2ImageView)
    
    gradientView.snp.makeConstraints { make in
      make.leading.trailing.bottom.equalToSuperview()
      make.height.equalTo(80)
    }
    
    grass8ImageView.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(116)
      make.bottom.equalToSuperview().offset(-127)
      make.width.equalTo(89)
      make.height.equalTo(40)
    }
    
    grass2ImageView.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(162)
      make.bottom.equalToSuperview().offset(-34)
      make.width.equalTo(210)
      make.height.equalTo(45)
    }
    
    grass3RightImageView.snp.makeConstraints { make in
      make.trailing.equalToSuperview().offset(-52)
      make.bottom.equalToSuperview().offset(-93)
      make.width.equalTo(61)
      make.height.equalTo(67)
    }
    
    grass3LeftImageView.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(75)
      make.bottom.equalToSuperview().offset(-56)
      make.width.equalTo(61)
      make.height.equalTo(67)
    }
    
    grass5ImageView.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(29)
      make.bottom.equalToSuperview().offset(-45)
      make.width.equalTo(76)
      make.height.equalTo(45)
    }
    
    addButton.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.bottom.equalToSuperview().offset(-52)
    }
  }
}
