//
// Copyright (c) Nathan Tannar
//

import SwiftUI
import Engine

struct UserInterfaceIdiomExamples: View {
    var body: some View {
        IdiomText()
    }
}

struct IdiomText: UserInterfaceIdiomContent {
    var phoneBody: some View {
        Text("iPhone")
    }

    var padBody: some View {
        Text("iPad")
    }

    var macBody: some View {
        Text("Mac")
    }

    var tvBody: some View {
        Text("TV")
    }

    var carBody: some View {
        Text("Car")
    }
}

struct UserInterfaceIdiomExamples_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UserInterfaceIdiomExamples()
        }
    }
}
