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
