//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct AnyDatePickerStyle: DatePickerStyle {

    var style: any DatePickerStyle

    public init<S: DatePickerStyle>(_ style: S) {
        self.style = style
    }

    public func makeBody(configuration: Configuration) -> some View {
        func project<S: DatePickerStyle>(_ style: S) -> some View {
            AnyView(
                AnyDatePickerStyleBody(
                    style: style,
                    configuration: configuration
                )
            )
        }
        return _openExistential(style, do: project)
    }
}

@available(iOS 16.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct AnyDatePickerStyleBody<S: DatePickerStyle>: View {
    var style: S
    var configuration: S.Configuration

    var body: some View {
        style.makeBody(configuration: configuration)
    }
}

// MARK: - Previews

#if os(iOS) || os(macOS)

@available(iOS 16.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AnyDatePickerStyle_Previews: PreviewProvider {
    struct Preview: View {
        @State var flag = false

        var body: some View {
            VStack {
                DatePicker(selection: .constant(Date.distantPast)) {
                    Text("Label")
                        .onTapGesture {
                            withAnimation {
                                flag.toggle()
                            }
                        }
                }
                .datePickerStyle(flag ? AnyDatePickerStyle(.automatic) : AnyDatePickerStyle(.graphical))
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}

#endif
