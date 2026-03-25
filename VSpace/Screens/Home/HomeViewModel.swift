//
//  HomeViewModel.swift
//  VSpace
//
//  홈 화면 비즈니스 로직 및 Realm 데이터 제공
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import Realm

enum HomeItem {
    case keepsake(Keepsake)
    case add
}

final class HomeViewModel {
    
    // MARK: - Properties
    
    private let disposeBag = DisposeBag()
    private var notificationToken: NotificationToken?
    
    // MARK: - Outputs
    
    let items = BehaviorRelay<[HomeItem]>(value: [.add])
    
    // MARK: - Init
    
    init() {
        fetchKeepsakes()
    }
    
    // MARK: - Fetch
    
    private func fetchKeepsakes() {
        guard let realm = try? Realm() else {
            print("Failed to initialize Realm")
            return
        }
        
        // 생성일 기준 내림차순(최신순) 정렬
        let results = realm.objects(Keepsake.self).sorted(byKeyPath: "createdAt", ascending: false)
        
        // Realm 변경사항 구독
        notificationToken = results.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial(let keepsakes), .update(let keepsakes, _, _, _):
                let homeItems = keepsakes.map { HomeItem.keepsake($0) } + [.add]
                self.items.accept(homeItems)
            case .error(let error):
                print("Realm observation error: \(error)")
            }
        }
    }
    
    deinit {
        notificationToken?.invalidate()
    }
}
