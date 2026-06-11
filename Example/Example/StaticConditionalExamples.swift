//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

struct StaticConditionalExamples: View {
    var body: some View {
        BuildConfigurationText()

        StaticTypeErasureExample()
    }
}

struct BuildConfigurationText: View {
    var body: some View {
        StaticConditionalContent(IsDebug.self) {
            Text("Debug")
        } otherwise: {
            Text("Release")
        }
    }
}

struct StaticTypeErasureExample: View {
    var body: some View {
        StaticContent(TextDescriptor.self) {
            // Could do #availability checks here to return different content
            ContentView(
                title: Text("Title"),
                subtitle: Text("Subtitle")
            )
        }
    }

    struct ContentView: View {
        var title: Text
        var subtitle: Text

        var body: some View {
            VStack(alignment: .leading) {
                title
                subtitle
            }
        }
    }

    struct TextDescriptor: TypeDescriptor {
        static var descriptor: UnsafeRawPointer {
            // Could do #availability checks here to return different metadata
            TypeIdentifier(ContentView.self).metadata
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
