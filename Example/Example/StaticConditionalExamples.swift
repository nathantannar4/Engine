//
// Copyright (c) Nathan Tannar
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
