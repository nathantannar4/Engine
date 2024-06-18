//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Group where Content: View {

    @available(iOS, introduced: 13.0, deprecated: 18.0, message: "Please use the built in Group(subviewsOf: ...) init")
    @available(macOS, introduced: 10.15, deprecated: 15.0, message: "Please use the built in Group(subviewsOf: ...) init")
    @available(tvOS, introduced: 13.0, deprecated: 18.0, message: "Please use the built in Group(subviewsOf: ...) init")
    @available(watchOS, introduced: 6.0, deprecated: 11.0, message: "Please use the built in Group(subviewsOf: ...) init")
    @available(visionOS, introduced: 1.0, deprecated: 2.0, message: "Please use the built in Group(subviewsOf: ...) init")
    public init<V: View, Result: View>(
        subviews view: V,
        @ViewBuilder transform: @escaping (AnyVariadicView) -> Result
    ) where Content == VariadicViewAdapter<V, Result> {
        self.init {
            VariadicViewAdapter(source: view) { source in
                transform(source.children)
            }
        }
    }

    @available(iOS, introduced: 13.0, deprecated: 18.0, message: "Please use the built in Group(sectionsOf: ...) init")
    @available(macOS, introduced: 10.15, deprecated: 15.0, message: "Please use the built in Group(sectionsOf: ...) init")
    @available(tvOS, introduced: 13.0, deprecated: 18.0, message: "Please use the built in Group(sectionsOf: ...) init")
    @available(watchOS, introduced: 6.0, deprecated: 11.0, message: "Please use the built in Group(sectionsOf: ...) init")
    @available(visionOS, introduced: 1.0, deprecated: 2.0, message: "Please use the built in Group(sectionsOf: ...) init")
    public init<V: View, Result: View>(
        sections view: V,
        @ViewBuilder transform: @escaping ([AnyVariadicSectionView]) -> Result
    ) where Content == VariadicViewAdapter<V, Result> {
        self.init {
            VariadicViewAdapter(source: view) { source in
                transform(source.sections)
            }
        }
    }
}


// MARK: - Previews

struct Group_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Group(subviews: Content()) { source in
                VStack {
                    HStack {
                        source[0]
                        source[1]
                    }

                    source[2...]
                }
            }
            .previewDisplayName("subviewsOf")

            Group(sections: Content()) { sections in
                ForEach(sections) { section in
                    VStack {
                        HStack {
                            Text("Header: ")
                            section.header
                        }

                        section.content

                        HStack {
                            Text("Footer: ")
                            section.footer
                        }
                    }
                }
            }
            .previewDisplayName("sectionsOf")
        }
    }

    struct Content: View {
        var body: some View {
            Section {
                Text("Line 1")
                Text("Line 2")
                Text("Line 3")
                Text("Line 4")
                Text("Line 5")
            } header: {
                SectionHeader {
                    Text("Header")
                }
            } footer: {
                SectionFooter {
                    Text("Footer")
                }
            }
        }
    }
}
