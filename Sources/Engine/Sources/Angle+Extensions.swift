//
// Copyright (c) Nathan Tannar
//

import SwiftUI

extension Angle {

    /// Returns the angle to travel from this angle to `endAngle` in the given direction.
    ///
    /// When `clockwise` is `true` the result is zero or negative, otherwise it is
    /// zero or positive. The result is suitable for
    /// use as the `delta` of `Path.addRelativeArc(center:radius:startAngle:delta:transform:)`.
    public func delta(endAngle: Angle, clockwise: Bool) -> Angle {
        var delta = endAngle - self
        if clockwise, delta.degrees > 0 {
            delta -= .degrees(360)
        } else if !clockwise, delta.degrees < 0 {
            delta += .degrees(360)
        }
        return delta
    }
}

// MARK: - Previews

@available(tvOS, unavailable)
struct Angle_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Preview()
        }
    }

    struct Preview: View {
        @State var startAngle: Angle = .degrees(90)
        @State var endAngle: Angle = .degrees(180)
        @State var clockwise: Bool = true

        var body: some View {
            VStack {
                HStack {
                    Path { path in
                        path.addArc(
                            center: CGPoint(x: 50, y: 50),
                            radius: 50,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: clockwise
                        )
                    }
                    .stroke(lineWidth: 2)
                    .frame(width: 100, height: 100)

                    Path { path in
                        path.addRelativeArc(
                            center: CGPoint(x: 50, y: 50),
                            radius: 50,
                            startAngle: startAngle,
                            delta: startAngle.delta(endAngle: endAngle, clockwise: clockwise)
                        )
                    }
                    .stroke(lineWidth: 2)
                    .frame(width: 100, height: 100)
                }

                Text("Delta: \(startAngle.delta(endAngle: endAngle, clockwise: clockwise).degrees)")

                Slider(value: $startAngle.degrees, in: 0...360)

                Slider(value: $endAngle.degrees, in: 0...360)

                Toggle(isOn: $clockwise) {
                    Text("clockwise")
                }
            }
            .padding()
        }
    }
}
