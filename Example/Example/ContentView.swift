//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

struct ContentView: View {
    var body: some View {
        #if os(macOS) || targetEnvironment(macCatalyst)
        content
        #else
        NavigationView {
            content
                .navigationTitle("Engine")
        }
        #endif
    }

    var content: some View {
        List {
            Section {
                ViewStyleExamples()
            } header: {
                Text("ViewStyle")
            } footer: {
                Text("Makes developing reusable components easier without sacrificing performance, since `AnyView` is not used. This can be especially useful for other framework developers who want a component to be customizable.")
            }

            Section {
                VariadicViewExamples()
            } header: {
                Text("VariadicView")
            } footer: {
                Text("Makes transforming a single view into a collection of subviews possible.")
            }

            Section {
                VersionedViewExamples()
            } header: {
                Text("VersionedView")
            } footer: {
                Text("Makes working with #availability easier and more performant, since using `if #available(...)` within a `@ViewBuilder` results in `AnyView`.")
            }

            if #available(iOS 16.0, macOS 13.0, *) {
                Section {
                    LayoutThatFitsExample()
                } header: {
                    Text("LayoutThatFits")
                } footer: {
                    Text("Makes working with dynamic sized content, such as text, easier to adapt to.")
                }
            }

            Section {
                UserInterfaceIdiomExamples()
            } header: {
                Text("UserInterfaceIdiom")
            } footer: {
                Text("Makes supported multiple device idioms easier.")
            }

            Section {
                StaticConditionalExamples()
            } header: {
                Text("StaticConditional")
            } footer: {
                Text("Makes conditional view code more performant when the condition can be static.")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
