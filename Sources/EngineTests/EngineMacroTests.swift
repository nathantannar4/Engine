import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(EngineMacrosCore)
import EngineMacros
@testable import EngineMacrosCore

@MainActor
final class MacroTests: XCTestCase {

    func testStyledViewMacro() throws {
        let sourceInput = """
        @StyledView
        struct LabelView<Label: View, Content: View>: StyledView {
            var label: Label
            var content: Content
            var identifier: String
            var value: String?
            var traits: Array<Int>
            var action: () -> Void
            var completion: ((Bool) -> Void)?
            @Binding var isEnabled: Bool
            var selection: Binding<Int>?

            var body: some View {
                HStack {
                    label
                    content
                }
                .id(identifier)
            }
        }
        """
        let sourceOutput = """
        struct LabelView<Label: View, Content: View>: StyledView {
            var label: Label
            var content: Content
            var identifier: String
            var value: String?
            var traits: Array<Int>
            var action: () -> Void
            var completion: ((Bool) -> Void)?
            @Binding var isEnabled: Bool
            var selection: Binding<Int>?

            var body: some View {
                HStack {
                    label
                    content
                }
                .id(identifier)
            }

            var _body: some View {
                LabelViewBody(
                    configuration: LabelViewConfiguration(
                        identifier: identifier,
                        value: value,
                        traits: traits,
                        action: action,
                        completion: completion,
                        isEnabled: $isEnabled,
                        selection: selection
                    )
                )
                .viewAlias(LabelViewConfiguration.Label.self) {
                    label
                }
                .viewAlias(LabelViewConfiguration.Content.self) {
                    content
                }
            }

            init(
                identifier: String,
                value: String? = nil,
                traits: Array<Int>,
                isEnabled: Binding<Bool>,
                selection: Binding<Int>? = nil,
                action: @escaping () -> Void,
                completion: ((Bool) -> Void)? = nil,
                @ViewBuilder label: () -> Label,
                @ViewBuilder content: () -> Content
            ) {
                self.label = label()
                self.content = content()
                self.identifier = identifier
                self.value = value
                self.traits = traits
                self.action = action
                self.completion = completion
                self._isEnabled = isEnabled
                self.selection = selection
            }

            init(
                _ configuration: LabelViewConfiguration
            ) where Label == LabelViewConfiguration.Label, Content == LabelViewConfiguration.Content {
                self.label = configuration.label
                self.content = configuration.content
                self.identifier = configuration.identifier
                self.value = configuration.value
                self.traits = configuration.traits
                self.action = configuration.action
                self.completion = configuration.completion
                self._isEnabled = configuration.$isEnabled
                self.selection = configuration.selection
            }
        }

        struct LabelViewConfiguration {
            struct Label: ViewAlias {
            }
            var label: Label {
                .init()
            }
            struct Content: ViewAlias {
            }
            var content: Content {
                .init()
            }
            var identifier: String
            var value: String?
            var traits: Array<Int>
            var action: () -> Void
            var completion: ((Bool) -> Void)?
            @Binding var isEnabled: Bool
            var selection: Binding<Int>?
        }

        protocol LabelViewStyle: ViewStyle where Configuration == LabelViewConfiguration {
        }

        struct LabelViewDefaultStyle: LabelViewStyle {
            func makeBody(configuration: LabelViewConfiguration) -> some View {
                _DefaultStyledView(LabelView(configuration))
            }
        }

        private struct LabelViewBody: ViewStyledView {
            var configuration: LabelViewConfiguration

            static var defaultStyle: LabelViewDefaultStyle {
                LabelViewDefaultStyle()
            }
        }

        struct LabelViewStyleModifier<Style: LabelViewStyle>: ViewModifier {
            var style: Style

            init(_ style: Style) {
                self.style = style
            }

            func body(content: Content) -> some View {
                content.styledViewStyle(LabelViewBody.self, style: style)
            }
        }
        """
        assertMacroExpansion(
            sourceInput,
            expandedSource: sourceOutput,
            macros: [
                "StyledView": StyledViewMacro.self,
            ]
        )
    }

    func testUnionMacro() {
        @Union
        enum PrimitiveUnion {
            case empty
            case integer(Int)
            case double(Double)
            case string(String)
            case pair(int: Int, double: Double)
            case triple(Int, Double, String)
            case optionalInteger(Int?)
            case optionalDouble(double: Double?)
            case optionalPair(Int?, Double?)

            struct Box {
                var value: Int
            }
            case box(Box)

            @Union
            enum Status {
                case offline
                case online
            }
            case status(Status)

            case `default`
        }

        var union = PrimitiveUnion.empty
        XCTAssert(union.isEmpty)
        union.integer = 0
        XCTAssert(union.isInteger)
        union.double = nil
        XCTAssert(union.isInteger)
        union.pair = (1, 1)
        XCTAssert(union.isPair)
        union.optionalInteger = nil
        XCTAssert(union.isOptionalInteger)
        union.isDefault = false
        XCTAssert(union.isOptionalInteger)
        union.status = .online
        XCTAssert(union.isStatus)

        let sourceInput = """
        @Union
        enum PrimitiveUnion {
            case empty
            case integer(Int)
            case double(Double)
            case string(String)
            case pair(int: Int, double: Double)
            case triple(Int, Double, String)
            case optionalInteger(Int?)
            case optionalDouble(double: Double?)
            case optionalPair(Int?, Double?)
        
            struct Box {
                var value: Int
            }
            case box(Box)
        
            @Union
            enum Status {
                case offline
                case online
            }
            case status(Status)
        
            case `default`
        }
        """
        let sourceOutput = """
        enum PrimitiveUnion {
            case empty
            case integer(Int)
            case double(Double)
            case string(String)
            case pair(int: Int, double: Double)
            case triple(Int, Double, String)
            case optionalInteger(Int?)
            case optionalDouble(double: Double?)
            case optionalPair(Int?, Double?)

            struct Box {
                var value: Int
            }
            case box(Box)
            enum Status {
                case offline
                case online

                var isOffline: Bool {
                    get {
                        switch self {
                        case .offline:
                            return true
                        default:
                            return false
                        }
                    }
                    set {
                        guard newValue else {
                            return
                        }
                        self = .offline
                    }
                }

                var isOnline: Bool {
                    get {
                        switch self {
                        case .online:
                            return true
                        default:
                            return false
                        }
                    }
                    set {
                        guard newValue else {
                            return
                        }
                        self = .online
                    }
                }
            }
            case status(Status)

            case `default`

            enum CaseKey {
                case empty
                case integer
                case double
                case string
                case pair
                case triple
                case optionalInteger
                case optionalDouble
                case optionalPair
                case box
                case status
                case `default`
            }

            var key: CaseKey {
                switch self {
                case .empty:
                    return .empty
                case .integer:
                    return .integer
                case .double:
                    return .double
                case .string:
                    return .string
                case .pair:
                    return .pair
                case .triple:
                    return .triple
                case .optionalInteger:
                    return .optionalInteger
                case .optionalDouble:
                    return .optionalDouble
                case .optionalPair:
                    return .optionalPair
                case .box:
                    return .box
                case .status:
                    return .status
                case .`default`:
                    return .`default`
                }
            }

            var isEmpty: Bool {
                get {
                    switch self {
                    case .empty:
                        return true
                    default:
                        return false
                    }
                }
                set {
                    guard newValue else {
                        return
                    }
                    self = .empty
                }
            }

            var isInteger: Bool {
                get {
                    switch self {
                    case .integer:
                        return true
                    default:
                        return false
                    }
                }
            }

            var integer: Int? {
                get {
                    switch self {
                    case .integer(let v0):
                        return v0
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue else {
                        return
                    }
                    self = .integer(newValue)
                }
            }

            var isDouble: Bool {
                get {
                    switch self {
                    case .double:
                        return true
                    default:
                        return false
                    }
                }
            }

            var double: Double? {
                get {
                    switch self {
                    case .double(let v0):
                        return v0
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue else {
                        return
                    }
                    self = .double(newValue)
                }
            }

            var isString: Bool {
                get {
                    switch self {
                    case .string:
                        return true
                    default:
                        return false
                    }
                }
            }

            var string: String? {
                get {
                    switch self {
                    case .string(let v0):
                        return v0
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue else {
                        return
                    }
                    self = .string(newValue)
                }
            }

            var isPair: Bool {
                get {
                    switch self {
                    case .pair:
                        return true
                    default:
                        return false
                    }
                }
            }

            var pairInt: Int? {
                get {
                    switch self {
                    case .pair(let v0, _):
                        return v0
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue, case .pair(_, let v1) = self else {
                        return
                    }
                    self = .pair(int: newValue, double: v1)
                }
            }

            var pairDouble: Double? {
                get {
                    switch self {
                    case .pair(_, let v1):
                        return v1
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue, case .pair(let v0, _) = self else {
                        return
                    }
                    self = .pair(int: v0, double: newValue)
                }
            }

            var pair: (int: Int, double: Double)? {
                get {
                    switch self {
                    case .pair(let v0, let v1):
                        return (int: v0, double: v1)
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue else {
                        return
                    }
                    self = .pair(int: newValue.int, double: newValue.double)
                }
            }

            var isTriple: Bool {
                get {
                    switch self {
                    case .triple:
                        return true
                    default:
                        return false
                    }
                }
            }

            var tripleInt: Int? {
                get {
                    switch self {
                    case .triple(let v0, _, _):
                        return v0
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue, case .triple(_, let v1, let v2) = self else {
                        return
                    }
                    self = .triple(newValue, v1, v2)
                }
            }

            var tripleDouble: Double? {
                get {
                    switch self {
                    case .triple(_, let v1, _):
                        return v1
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue, case .triple(let v0, _, let v2) = self else {
                        return
                    }
                    self = .triple(v0, newValue, v2)
                }
            }

            var tripleString: String? {
                get {
                    switch self {
                    case .triple(_, _, let v2):
                        return v2
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue, case .triple(let v0, let v1, _) = self else {
                        return
                    }
                    self = .triple(v0, v1, newValue)
                }
            }

            var triple: (Int, Double, String)? {
                get {
                    switch self {
                    case .triple(let v0, let v1, let v2):
                        return (v0, v1, v2)
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue else {
                        return
                    }
                    self = .triple(newValue.0, newValue.1, newValue.2)
                }
            }

            var isOptionalInteger: Bool {
                get {
                    switch self {
                    case .optionalInteger:
                        return true
                    default:
                        return false
                    }
                }
            }

            var optionalInteger: Int? {
                get {
                    switch self {
                    case .optionalInteger(let v0):
                        return v0
                    default:
                        return nil
                    }
                }
                set {
                    self = .optionalInteger(newValue)
                }
            }

            var isOptionalDouble: Bool {
                get {
                    switch self {
                    case .optionalDouble:
                        return true
                    default:
                        return false
                    }
                }
            }

            var optionalDoubleDouble: Double? {
                get {
                    switch self {
                    case .optionalDouble(let v0):
                        return v0
                    default:
                        return nil
                    }
                }
                set {
                    self = .optionalDouble(double: newValue)
                }
            }

            var isOptionalPair: Bool {
                get {
                    switch self {
                    case .optionalPair:
                        return true
                    default:
                        return false
                    }
                }
            }

            var optionalPairInt: Int? {
                get {
                    switch self {
                    case .optionalPair(let v0, _):
                        return v0
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue, case .optionalPair(_, let v1) = self else {
                        return
                    }
                    self = .optionalPair(newValue, v1)
                }
            }

            var optionalPairDouble: Double? {
                get {
                    switch self {
                    case .optionalPair(_, let v1):
                        return v1
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue, case .optionalPair(let v0, _) = self else {
                        return
                    }
                    self = .optionalPair(v0, newValue)
                }
            }

            var optionalPair: (Int?, Double?)? {
                get {
                    switch self {
                    case .optionalPair(let v0, let v1):
                        return (v0, v1)
                    default:
                        return nil
                    }
                }
                set {
                    self = .optionalPair(newValue?.0, newValue?.1)
                }
            }

            var isBox: Bool {
                get {
                    switch self {
                    case .box:
                        return true
                    default:
                        return false
                    }
                }
            }

            var box: Box? {
                get {
                    switch self {
                    case .box(let v0):
                        return v0
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue else {
                        return
                    }
                    self = .box(newValue)
                }
            }

            var isStatus: Bool {
                get {
                    switch self {
                    case .status:
                        return true
                    default:
                        return false
                    }
                }
            }

            var status: Status? {
                get {
                    switch self {
                    case .status(let v0):
                        return v0
                    default:
                        return nil
                    }
                }
                set {
                    guard let newValue else {
                        return
                    }
                    self = .status(newValue)
                }
            }

            var isDefault: Bool {
                get {
                    switch self {
                    case .`default`:
                        return true
                    default:
                        return false
                    }
                }
                set {
                    guard newValue else {
                        return
                    }
                    self = .`default`
                }
            }
        }
        """
        assertMacroExpansion(
            sourceInput,
            expandedSource: sourceOutput,
            macros: [
                "Union": UnionMacro.self,
            ]
        )
    }
}

#endif
