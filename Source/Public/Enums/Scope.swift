//
//  Scope.swift
//
//  Created by Ruben Nine on 20/09/2019.
//

import Foundation

/// Indicates the scope used by an `AudioDevice` or `AudioStream`.
///
/// Please notice that `AudioStream` only supports `input` or `output` scopes,
/// whether as `AudioDevice` may, additionally, support `global` and `playthrough`.
public enum Scope {
    /// Global scope
    case global
    /// Input scope
    case input
    /// Output scope
    case output
    /// Playthrough scope
    case playthrough
}
