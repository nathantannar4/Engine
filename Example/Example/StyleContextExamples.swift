//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

struct StyleContextExamples: View {
    struct TestView: View {
        var body: some View {
            Text("Hello, World")
                .modifier(
                    StyleContextConditionalModifier(predicate: .none) {
                        BackgroundModifier(color: .red)
                    }
                )
                .modifier(
                    StyleContextConditionalModifier(predicate: CustomStyleContext()) {
                        BackgroundModifier(color: .green)
                    }
                )
                .modifier(
                    StyleContextConditionalModifier(predicate: .list) {
                        BackgroundModifier(color: .blue)
                    }
                )
                .modifier(
                    StyleContextConditionalModifier(predicate: .scrollView) {
                        BackgroundModifier(color: .purple)
                    }
                )
                .modifier(
                    StyleContextConditionalModifier(predicate: .navigationView) {
                        BackgroundModifier(color: .yellow)
                    }
                )
                .modifier(_StyleContextLogModifier())
        }
    }

    var body: some View {
        TestView()
            .styleContext(.none)

        TestView()

        TestView()
            .styleContext(CustomStyleContext())

        ScrollView(.horizontal) {
            TestView()
        }
    }
}

struct CustomStyleContext: StyleContext { }

struct BackgroundModifier: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .padding()
            .background(color)
    }
}
