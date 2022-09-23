# Greycats.swiftUI

A set of scaffold tools for SwiftUI & Combine

##### GreycatsPreference Example:

```swift

import GreycatsPreference

struct WantLocalAuth: Codable {
    var wantLocalAuth: Bool
    var isLocalAuthenticated: Bool
}

final class MyPreferences: Preferences {
    static let shared = MyPreferences()

    @Keychain("access_token")
    var access_token = ""

    @UserDefault("virtual_card_prompted")
    var virtualCardPrompted: Bool = false

    @LocalStorage("local-auth-enrolled")
    var wantLocalAuth = WantLocalAuth(wantLocalAuth: false, isLocalAuthenticated: false)
}

extension Preference where T == MyPreferences {
    init(_ keyPath: ReferenceWritableKeyPath<T, Value>) {
        self.init(keyPath, preferences: MyPreferences.shared)
    }
}

struct VirtualCardView: View {
    @Preference(\.virtualCardPrompted) var prompted
    ...
}
```

#### GreycatsComponent Examples:

```swift

import GreycatsComponent

struct Slides: View {
    var body: some View {
        VStack {
            DraggableHStack(index: $index, total: 3, canMove: true) { size, _ in
                Slide(index: 0, ...)
                    .frame(width: size.width)
                Slide(index: 1, ...)
                    .frame(width: size.width)
                Slide(index: 2, ...)
                    .frame(width: size.width)
            }
        }
    }
}

struct LoaderHolder: Presentable, AutoDismiss {
    var isPresented: Binding<Bool>
    var duration: DispatchTimeInterval = .seconds(5)

    @ViewBuilder func body(context: PresentableContext) -> some View {
        ProgressView()
            .progressViewStyle(.circular)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white).frame(width: 80, height: 80).shadow(radius: 5)
            )
            
    }
}

extension View {
    public func loader(isPresented: Binding<Bool>, duration: DispatchTimeInterval = .seconds(5)) -> some View {
        callout(LoaderHolder(isPresented: isPresented, duration: duration))
    }
}
```
