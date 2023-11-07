//
//  AutomaticDosingStrategyAction.swift
//  LoopKit
//
//  Created by 王鹏 on 2023/4/8.
//  Copyright © 2023 LoopKit Authors. All rights reserved.
//

import Foundation

public struct AutomaticDosingStrategyAction: Codable{
    public let automaticDosingStrategy: AutomaticDosingStrategy
    public init(automaticDosingStrategy: AutomaticDosingStrategy) {
        self.automaticDosingStrategy = automaticDosingStrategy
    }
}
