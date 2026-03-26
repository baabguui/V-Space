//
//  RealmMigrationManager.swift
//  VSpace
//
//  Realm 스키마 버전 관리 및 마이그레이션 정의
//
//  버전 이력:
//  v1 → v2: Keepsake.ritualDate non-optional → optional (개발 중: deleteRealmIfMigrationNeeded)
//  v2 → v3: Keepsake.disposalDate 기본값 Date() → Date.distantFuture ("미정" 센티넬)
//

import RealmSwift

enum RealmMigrationManager {

    private static let schemaVersion: UInt64 = 3

    static func configure() {
        let config = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { _, _ in },
            deleteRealmIfMigrationNeeded: true  // TODO: 배포 전 제거
        )
        Realm.Configuration.defaultConfiguration = config
    }
}
