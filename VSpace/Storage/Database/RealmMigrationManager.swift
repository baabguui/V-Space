//
//  RealmMigrationManager.swift
//  VSpace
//
//  Realm 스키마 버전 관리 및 마이그레이션 정의
//
//  버전 이력:
//  v1 → v2: Keepsake.ritualDate non-optional → optional (개발 중: deleteRealmIfMigrationNeeded)
//

import RealmSwift

enum RealmMigrationManager {

    private static let schemaVersion: UInt64 = 2

    static func configure() {
        let config = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    // ritualDate: Date → Date?
                    // 기존 값을 그대로 유지 (Realm이 자동 처리)
                    // 개발 단계: 데이터 초기화
                }
            },
            deleteRealmIfMigrationNeeded: true  // TODO: 배포 전 제거
        )
        Realm.Configuration.defaultConfiguration = config
    }
}
