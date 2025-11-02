//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Group where Content: View {

    @available(iOS, introduced: 13.0, deprecated: 18.0, message: "Please use the built in Group(subviews: ...) init")
    @available(macOS, introduced: 10.15, deprecated: 15.0, message: "Please use the built in Group(subviews: ...) init")
    @available(tvOS, introduced: 13.0, deprecated: 18.0, message: "Please use the built in Group(subviews: ...) init")
    @available(watchOS, introduced: 6.0, deprecated: 11.0, message: "Please use the built in Group(subviews: ...) init")
    @available(visionOS, introduced: 1.0, deprecated: 2.0, message: "Please use the built in Group(subviews: ...) init")
    @MainActor @preconcurrency
    public init<V: View, Result: View>(
        subviewsOf view: V,
        @ViewBuilder transform: @escaping (VariadicView) -> Result
    ) where Content == VariadicViewAdapter<V, Result> {
        self.init {
            VariadicViewAdapter(source: view) { source in
                transform(source)
            }
        }
    }

    @available(iOS, introduced: 13.0, deprecated: 18.0, message: "Please use the built in Group(sections: ...) init")
    @available(macOS, introduced: 10.15, deprecated: 15.0, message: "Please use the built in Group(sections: ...) init")
    @available(tvOS, introduced: 13.0, deprecated: 18.0, message: "Please use the built in Group(sections: ...) init")
    @available(watchOS, introduced: 6.0, deprecated: 11.0, message: "Please use the built in Group(sections: ...) init")
    @available(visionOS, introduced: 1.0, deprecated: 2.0, message: "Please use the built in Group(sections: ...) init")
    @MainActor @preconcurrency
    public init<V: View, Result: View>(
        sectionsOf view: V,
        @ViewBuilder transform: @escaping ([VariadicSectionView]) -> Result
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
            HStack {
                if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                    Group(subviews: Content()) { source in
                        VStack {
                            HStack {
                                source[0]
                                source[1]
                            }

                            source[2...]
                                .border(Color.red)
                        }
                    }
                }

                Group(subviewsOf: Content()) { source in
                    VStack {
                        HStack {
                            source[0]
                            source[1]
                        }

                        source[2...]
                            .border(Color.red)
                    }
                }
            }
            .previewDisplayName("subviewsOf")

            HStack {
                if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                    Group(sections: Content()) { sections in
                        ForEach(sections) { section in
                            VStack {
                                HStack {
                                    Text("Header: ")
                                    section.header
                                }
                                .border(Color.red)

                                section.content

                                HStack {
                                    Text("Footer: ")
                                    section.footer
                                }
                                .border(Color.red)
                            }
                        }
                    }
                }

                Group(sectionsOf: Content()) { sections in
                    ForEach(sections) { section in
                        VStack {
                            HStack {
                                Text("Header: ")
                                section.header
                            }
                            .border(Color.red)

                            section.content

                            HStack {
                                Text("Footer: ")
                                section.footer
                            }
                            .border(Color.red)
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
