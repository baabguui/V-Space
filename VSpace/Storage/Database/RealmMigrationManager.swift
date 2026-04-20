//
//  RealmMigrationManager.swift
//  VSpace
//
//  Realm 스키마 버전 관리 및 마이그레이션 정의
//
//  버전 이력:
//  v1: 최초 배포 버전
//

import RealmSwift

enum RealmMigrationManager {

    private static let schemaVersion: UInt64 = 1

    static func configure() {
        let config = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { _, _ in }
        )
        Realm.Configuration.defaultConfiguration = config
    }
}
