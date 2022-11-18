//
//  StaticConditionalExamples.swift
//  Example
//
//  Created by Nathan Tannar on 2022-11-12.
//

import SwiftUI
import Engine

struct StaticConditionalExamples: View {
    var body: some View {
        BuildConfigurationText()
    }
}

struct BuildConfigurationText: View {
    var body: some View {
        StaticConditionalContent(IsDebug.self) {
            Text("Debug")
        } else: {
            Text("Release")
        }
    }
}

struct IsDebug: StaticCondition {
    static var value: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

struct StaticModifierExamples_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StaticConditionalExamples()
        }
    }
}
