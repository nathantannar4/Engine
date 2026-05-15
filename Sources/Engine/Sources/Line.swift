//
// Copyright (c) Nathan Tannar
//

import SwiftUI

@frozen
public struct Line: Shape {

    @frozen
    public enum Segment: Hashable, Sendable, Animatable {
        case linear(point: AnchoredPoint)
        case curve(controlPoint1: AnchoredPoint, controlPoint2: AnchoredPoint)
        case quadCurve(controlPoint: AnchoredPoint)
        case arc(center: AnchoredPoint, radius: CGFloat, startAngle: Angle, delta: Angle)
        case tangentArc(tangent1End: AnchoredPoint, tangent2End: AnchoredPoint, radius: CGFloat)

        public static func linear(
            point: UnitPoint
        ) -> Segment {
            .linear(
                point: AnchoredPoint(anchor: point)
            )
        }

        public static func curve(
            controlPoint1: UnitPoint,
            controlPoint2: UnitPoint
        ) -> Segment {
            .curve(
                controlPoint1: AnchoredPoint(anchor: controlPoint1),
                controlPoint2: AnchoredPoint(anchor: controlPoint2)
            )
        }

        public static func quadCurve(
            controlPoint: UnitPoint
        ) -> Segment {
            .quadCurve(
                controlPoint: AnchoredPoint(anchor: controlPoint)
            )
        }

        public static func arc(
            center: UnitPoint,
            radius: CGFloat,
            startAngle: Angle,
            delta: Angle
        ) -> Segment {
            .arc(
                center: AnchoredPoint(anchor: center),
                radius: radius,
                startAngle: startAngle,
                delta: delta
            )
        }

        public static func tangentArc(
            tangent1End: UnitPoint,
            tangent2End: UnitPoint,
            radius: CGFloat
        ) -> Segment {
            .tangentArc(
                tangent1End: AnchoredPoint(anchor: tangent1End),
                tangent2End: AnchoredPoint(anchor: tangent2End),
                radius: radius
            )
        }

        @frozen
        public struct Set: Hashable, Sendable, Animatable, VectorArithmetic, ExpressibleByArrayLiteral {

            public var elements: [Segment]

            @inlinable
            public init(_ elements: [Segment]) {
                self.elements = elements
            }

            public init(arrayLiteral elements: Segment...) {
                self.elements = elements
            }
        }
    }

    public var startPoint: AnchoredPoint
    public var endPoint: AnchoredPoint
    public var segments: Segment.Set
    public var strokeStyle: StrokeStyle

    @inlinable
    public init(
        startPoint: AnchoredPoint,
        endPoint: AnchoredPoint,
        segments: Segment.Set = [],
        strokeStyle: StrokeStyle = StrokeStyle(lineWidth: 1),
    ) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.segments = segments
        self.strokeStyle = strokeStyle
    }

    @inlinable
    public init(
        startPoint: UnitPoint,
        endPoint: UnitPoint,
        segments: Segment.Set = [],
        strokeStyle: StrokeStyle = StrokeStyle(lineWidth: 1)
    ) {
        self.init(
            startPoint: AnchoredPoint(anchor: startPoint, offset: .zero),
            endPoint: AnchoredPoint(anchor: endPoint, offset: .zero),
            segments: segments,
            strokeStyle: strokeStyle
        )
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public nonisolated static var role: ShapeRole {
        .stroke
    }

    public nonisolated func path(in rect: CGRect) -> Path {
        let startPoint = startPoint.point(in: rect.size)
        let endPoint = endPoint.point(in: rect.size)
        var path = Path()
        path.move(to: startPoint)
        for index in segments.elements.indices {
            switch segments.elements[index] {
            case .linear(let point):
                let point = point.point(in: rect.size)
                path.addLine(to: point)
            case .curve(let controlPoint1, let controlPoint2):
                let control1 = controlPoint1.point(in: rect.size)
                let control2 = controlPoint2.point(in: rect.size)
                let toPoint = index < segments.elements.count - 2 ? segments.elements[index + 1].point1.point(in: rect.size) : endPoint
                path.addCurve(to: toPoint, control1: control1, control2: control2)
            case .quadCurve(let controlPoint):
                let control = controlPoint.point(in: rect.size)
                let toPoint = index < segments.elements.count - 2 ? segments.elements[index + 1].point1.point(in: rect.size) : endPoint
                path.addQuadCurve(to: toPoint, control: control)
            case .tangentArc(let tangent1End, let tangent2End, let radius):
                let tangent1End = tangent1End.point(in: rect.size)
                let tangent2End = tangent2End.point(in: rect.size)
                path.addArc(tangent1End: tangent1End, tangent2End: tangent2End, radius: radius)
            case .arc(let center, let radius, let startAngle, let delta):
                let center = center.point(in: rect.size)
                path.addRelativeArc(center: center, radius: radius, startAngle: startAngle, delta: delta)
            }
        }
        path.addLine(to: endPoint)
        return path.strokedPath(strokeStyle)
    }
}

extension Line {

    public typealias AnimatableData = AnimatablePair<
        AnimatablePair<
            AnchoredPoint.AnimatableData,
            AnchoredPoint.AnimatableData
        >,
        AnimatablePair<
            Segment.Set.AnimatableData,
            StrokeStyle.AnimatableData
        >
    >
    public var animatableData: AnimatableData {
        get {
            AnimatablePair(
                AnimatablePair(
                    startPoint.animatableData,
                    endPoint.animatableData
                ),
                AnimatablePair(
                    segments.animatableData,
                    strokeStyle.animatableData
                )
            )
        }
        set {
            startPoint.animatableData = newValue.first.first
            endPoint.animatableData = newValue.first.second
            segments.animatableData = newValue.second.first
            strokeStyle.animatableData = newValue.second.second
        }
    }
}

extension Line.Segment {

    public typealias AnimatableData = AnimatablePair<
        AnimatablePair<
            AnchoredPoint.AnimatableData,
            AnchoredPoint.AnimatableData
        >,
        AnimatablePair<
            CGFloat,
            AnimatablePair<
                Angle.AnimatableData,
                Angle.AnimatableData
            >
        >
    >
    public var animatableData: AnimatableData {
        get {
            AnimatablePair(
                AnimatablePair(
                    point1.animatableData,
                    point2.animatableData
                ),
                AnimatablePair(
                    radius,
                    AnimatablePair(
                        angle1.animatableData,
                        angle2.animatableData
                    )
                )
            )
        }
        set {
            point1.animatableData = newValue.first.first
            point2.animatableData = newValue.first.second
            radius = newValue.second.first
            angle1.animatableData = newValue.second.second.first
            angle2.animatableData = newValue.second.second.second
        }
    }

    fileprivate var point1: AnchoredPoint {
        get {
            switch self {
            case .linear(let point):
                return point
            case .curve(let controlPoint1, _):
                return controlPoint1
            case .quadCurve(let controlPoint):
                return controlPoint
            case .tangentArc(let tangent1End, _, _):
                return tangent1End
            case .arc(let center, _, _, _):
                return center
            }
        }
        set {
            switch self {
            case .linear:
                self = .linear(point: newValue)
            case .curve(_, let controlPoint2):
                self = .curve(controlPoint1: newValue, controlPoint2: controlPoint2)
            case .quadCurve:
                self = .quadCurve(controlPoint: newValue)
            case .tangentArc(_, let tangent2End, let radius):
                self = .tangentArc(tangent1End: newValue, tangent2End: tangent2End, radius: radius)
            case .arc(_, let radius, let startAngle, let delta):
                self = .arc(center: newValue, radius: radius, startAngle: startAngle, delta: delta)
            }
        }
    }

    private var point2: AnchoredPoint {
        get {
            switch self {
            case .linear, .quadCurve, .arc:
                return AnchoredPoint(anchor: .center)
            case .curve(_, let controlPoint2):
                return controlPoint2
            case .tangentArc(_, let tangent2End, _):
                return tangent2End
            }
        }
        set {
            switch self {
            case .linear, .quadCurve, .arc:
                break
            case .curve(let controlPoint1, _):
                self = .curve(controlPoint1: controlPoint1, controlPoint2: newValue)
            case .tangentArc(let tangent1End, _, let radius):
                self = .tangentArc(tangent1End: tangent1End, tangent2End: newValue, radius: radius)
            }
        }
    }

    private var radius: CGFloat {
        get {
            switch self {
            case .linear, .curve, .quadCurve:
                return 0
            case .tangentArc(_, _, let radius):
                return radius
            case .arc(_, let radius, _, _):
                return radius
            }
        }
        set {
            switch self {
            case .linear, .curve, .quadCurve:
                break
            case .tangentArc(let tangent1End, let tangent2End, _):
                self = .tangentArc(tangent1End: tangent1End, tangent2End: tangent2End, radius: newValue)
            case .arc(let center, _, let startAngle, let delta):
                self = .arc(center: center, radius: newValue, startAngle: startAngle, delta: delta)
            }
        }
    }

    private var angle1: Angle {
        get {
            switch self {
            case .linear, .curve, .quadCurve, .tangentArc:
                return .zero
            case .arc(_, _, let startAngle, _):
                return startAngle
            }
        }
        set {
            switch self {
            case .linear, .curve, .quadCurve, .tangentArc:
                break
            case .arc(let center, let radius, _, let delta):
                self = .arc(center: center, radius: radius, startAngle: newValue, delta: delta)
            }
        }
    }

    private var angle2: Angle {
        get {
            switch self {
            case .linear, .curve, .quadCurve, .tangentArc:
                return .zero
            case .arc(_, _, _, let delta):
                return delta
            }
        }
        set {
            switch self {
            case .linear, .curve, .quadCurve, .tangentArc:
                break
            case .arc(let center, let radius, let startAngle, _):
                self = .arc(center: center, radius: radius, startAngle: startAngle, delta: newValue)
            }
        }
    }
}

extension Line.Segment.Set {

    public static let zero = Line.Segment.Set([])

    public static func + (lhs: Line.Segment.Set, rhs: Line.Segment.Set) -> Line.Segment.Set {
        let upperBound = min(lhs.elements.count, rhs.elements.count)
        var segments: [Line.Segment] = []
        segments.reserveCapacity(max(lhs.elements.count, rhs.elements.count))
        for i in 0..<upperBound {
            var segment = lhs.elements[i]
            segment.animatableData += rhs.elements[i].animatableData
            segments.append(segment)
        }
        segments.append(contentsOf: lhs.elements[upperBound...])
        segments.append(contentsOf: rhs.elements[upperBound...])
        return Line.Segment.Set(segments)
    }

    public static func - (lhs: Line.Segment.Set, rhs: Line.Segment.Set) -> Line.Segment.Set {
        let upperBound = min(lhs.elements.count, rhs.elements.count)
        var segments: [Line.Segment] = []
        segments.reserveCapacity(max(lhs.elements.count, rhs.elements.count))
        for i in 0..<upperBound {
            var segment = lhs.elements[i]
            segment.animatableData -= rhs.elements[i].animatableData
            segments.append(segment)
        }
        segments.append(contentsOf: lhs.elements[upperBound...])
        segments.append(contentsOf: rhs.elements[upperBound...])
        return Line.Segment.Set(segments)
    }

    public mutating func scale(by rhs: Double) {
        for index in elements.indices {
            elements[index].animatableData.scale(by: rhs)
        }
    }

    public var magnitudeSquared: Double {
        elements.reduce(into: 0) { result, segment in
            result += segment.animatableData.magnitudeSquared
        }
    }
}

// MARK: - Previews

struct Line_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var flag = false

        var body: some View {
            let style = StrokeStyle(
                lineWidth: flag ? 4 : 2
            )
            VStack {
                HStack {
                    Line(
                        startPoint: flag ? .topTrailing : .top,
                        endPoint: flag ? .bottomLeading : .bottom,
                        strokeStyle: style
                    )

                    Line(
                        startPoint: AnchoredPoint(
                            anchor: flag ? .top : .leading,
                            offset: CGPoint(x: flag ? 10 : 0, y: flag ? 0 : -10)
                        ),
                        endPoint: AnchoredPoint(
                            anchor: flag ? .bottom : .trailing,
                            offset: CGPoint(x: flag ? -10 : 0, y: flag ? 10 : 0)
                        ),
                        strokeStyle: style
                    )

                    Line(
                        startPoint: flag ? .bottomLeading : .topLeading,
                        endPoint: flag ? .topLeading : .bottomTrailing,
                        strokeStyle: style
                    )
                }
                .frame(height: 100)

                HStack {
                    Line(
                        startPoint: .bottom,
                        endPoint: .topTrailing,
                        segments: [
                            .curve(
                                controlPoint1: .bottomLeading,
                                controlPoint2: .center
                            )
                        ],
                        strokeStyle: style
                    )

                    Line(
                        startPoint: .bottom,
                        endPoint: .topTrailing,
                        segments: [
                            .quadCurve(
                                controlPoint: .leading
                            )
                        ],
                        strokeStyle: style
                    )

                    Line(
                        startPoint: .bottom,
                        endPoint: .topTrailing,
                        segments: [
                            .linear(
                                point: flag ? .trailing : .leading
                            ),
                            .linear(
                                point: flag ? .center : .top
                            ),
                        ],
                        strokeStyle: style
                    )
                }
                .frame(height: 100)

                HStack {
                    Line(
                        startPoint: .bottom,
                        endPoint: .topTrailing,
                        segments: [
                            .arc(
                                center: .center,
                                radius: flag ? 25 : 50,
                                startAngle: .degrees(90),
                                delta: .degrees(270)
                            )
                        ],
                        strokeStyle: style
                    )

                    Line(
                        startPoint: .bottom,
                        endPoint: .topTrailing,
                        segments: [
                            .arc(
                                center: .center,
                                radius: flag ? 25 : 50,
                                startAngle: .degrees(90),
                                delta: Angle.degrees(90).delta(endAngle: .degrees(0), clockwise: false)
                            )
                        ],
                        strokeStyle: style
                    )

                    Line(
                        startPoint: .bottomTrailing,
                        endPoint: .topTrailing,
                        segments: [
                            .tangentArc(
                                tangent1End: .leading,
                                tangent2End: .topTrailing,
                                radius: flag ? 25 : 50
                            )
                        ],
                        strokeStyle: style
                    )
                }
                .frame(height: 100)

                Line(
                    startPoint: .bottom,
                    endPoint: .topTrailing,
                    segments: [
                        .linear(
                            point: .center
                        ),
                        .arc(
                            center: AnchoredPoint(
                                anchor: .trailing,
                                offset: CGPoint(
                                    x: -20,
                                    y: -20
                                )
                            ),
                            radius: 30,
                            startAngle: .degrees(180),
                            delta: .degrees(90)
                        ),
                    ],
                    strokeStyle: style
                )
                .frame(width: 100, height: 100)

                Button {
                    withAnimation {
                        flag.toggle()
                    }
                } label: {
                    Text("Toggle")
                }
            }
            .padding()
        }
    }
}
