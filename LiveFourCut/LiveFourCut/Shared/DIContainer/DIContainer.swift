//
//  DIContainer.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import Foundation

final class DIContainer {
    static let shared = DIContainer()
    var dependencies: [AnyHashable: Any] = [:]
    private init() { }
    
    func resolve<T>(type: T.Type, name: String?) -> T? {
        return nil
    }
    
    func register<T>(type: T.Type, name: String?, factory: @escaping () -> T) {
        
        dependencies[name] = factory
    }
}

@propertyWrapper
public struct Dependency<T> {
    private var service: T
    
    public init(name: String? = nil) {
        guard let resolved = DIContainer.shared.resolve(type: T.self, name: name) else {
            fatalError("\(#file) - \(#line): \(#function) - resolved failed for \(T.self) - with \(name ?? "none")")
        }
        self.service = resolved
    }
    
    public var wrappedValue: T {
        return service
    }
}
