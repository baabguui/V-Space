//
//  NameInputViewModel.swift
//  VSpace
//

import Foundation
import RealmSwift
import RxSwift
import RxRelay

final class NameInputViewModel {

    struct Input {
        let name:    Observable<String>
        let nextTap: Observable<Void>
    }

    struct Output {
        let isNextEnabled: Observable<Bool>
        let navigateNext:  Observable<ObjectId>
    }

    private let keepsakeId: ObjectId
    private let db: KeepsakeDatabaseManaging
    private let disposeBag = DisposeBag()

    var initialName: String { db.fetchKeepsake(id: keepsakeId)?.name ?? "" }

    init(keepsakeId: ObjectId, db: KeepsakeDatabaseManaging = KeepsakeDatabaseManager()) {
        self.keepsakeId = keepsakeId
        self.db = db
    }

    func transform(input: Input) -> Output {
        let isNextEnabled = input.name
            .map { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        let navigateNext = input.nextTap
            .withLatestFrom(input.name)
            .compactMap { [weak self] name -> ObjectId? in
                self?.save(name: name)
            }

        return Output(isNextEnabled: isNextEnabled, navigateNext: navigateNext)
    }

    private func save(name: String) -> ObjectId? {
        guard let keepsake = db.fetchKeepsake(id: keepsakeId) else { return nil }
        try? db.updateKeepsake(keepsake) {
            $0.name = name
            $0.progressStep = 2
        }
        return keepsakeId
    }
}
