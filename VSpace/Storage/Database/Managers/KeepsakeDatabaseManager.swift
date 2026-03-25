import Foundation
import RealmSwift

protocol KeepsakeDatabaseManaging {
    func saveKeepsake(_ keepsake: Keepsake) throws
    func fetchKeepsakes() -> Results<Keepsake>
    func updateKeepsake(_ keepsake: Keepsake, action: @escaping (Keepsake) -> Void) throws
    func deleteKeepsake(_ keepsake: Keepsake) throws
}

final class KeepsakeDatabaseManager: KeepsakeDatabaseManaging {
    
    private let realm: Realm
    
    init() {
        do {
            self.realm = try Realm()
        } catch {
            fatalError("Realm initialization failed: \(error.localizedDescription)")
        }
    }
    
    func saveKeepsake(_ keepsake: Keepsake) throws {
        try realm.write {
            realm.add(keepsake)
        }
    }
    
    func fetchKeepsakes() -> Results<Keepsake> {
        return realm.objects(Keepsake.self).sorted(byKeyPath: "createdAt", ascending: false)
    }
    
    func updateKeepsake(_ keepsake: Keepsake, action: @escaping (Keepsake) -> Void) throws {
        try realm.write {
            action(keepsake)
            keepsake.updatedAt = Date()
        }
    }
    
    func deleteKeepsake(_ keepsake: Keepsake) throws {
        try realm.write {
            realm.delete(keepsake)
        }
    }
}
