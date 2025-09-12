//
//  Dependency+ProperyWrapper.swift
//  LiveFourCut
//
//  Created by Greem on 9/12/25.
//

import Foundation
import Swinject

@propertyWrapper
public struct Dependency<T> {
    private var service: T
    
    @MainActor
    public init(name: String? = nil) {
        guard let resolved = Container.shared.resolve(T.self, name: name) else {
            fatalError("\(#file) - \(#line): \(#function) - resolved failed for \(T.self) - with \(name ?? "none")")
        }
        self.service = resolved
    }
    
    public var wrappedValue: T {
        return service
    }
}
