---
name: apple-native
description: "Apple-platform DNA skill covering Swift language (concurrency, memory), SwiftUI/SwiftData patterns, and the four platform lobes (iOS, watchOS, macOS, plus a tvOS/visionOS stub). Use when writing or reviewing Swift/SwiftUI code, authoring Apple native modules for Expo, or building platform-specific features. Triggers on 'swiftui', 'swift', 'ios', 'macos', 'watchos', 'tvos', 'visionos', 'xcode', 'swiftdata', '@observable', 'navigationstack', 'concurrency', 'actors', 'inlinearray', 'span', 'apple native', 'apple platform'."
department: engineering
triggers:
  - swiftui
  - swift
  - ios
  - macos
  - watchos
  - tvos
  - visionos
  - xcode
  - swiftdata
  - "@observable"
  - navigationstack
  - concurrency
  - actors
  - inlinearray
  - span
  - apple native
  - apple platform
---

# Apple Native

The single Apple-platform DNA skill. One competency: writing correct, modern, performant Swift for any Apple platform.

> Reference snapshot, 2026-06-04: Swift 6.2, iOS 26, macOS 26 Tahoe, and watchOS 26. This is not a migration target. Resolve the project's Xcode toolchain, deployment targets, and API availability before introducing a newer platform API.

## When to Use

- Writing or reviewing Swift / SwiftUI code for iOS, macOS, watchOS, tvOS, or visionOS
- Authoring iOS native modules inside an Expo project (Expo Modules API Swift side)
- Migrating from `ObservableObject` / Combine to `@Observable` / structured concurrency
- Diagnosing actor-isolation, Sendable, or data-race errors in Swift 6 strict mode
- Building watchOS complications, workout sessions, Smart Stack widgets
- Implementing macOS 26 Tahoe features (scene-bridging, WebKit-for-SwiftUI)

## When NOT to Use

- Pure React Native / Expo JS logic — use the `expo` skill
- Apple Human Interface Guidelines, Liquid Glass design, animation polish — use `apple-platform-design`
- Xcode MCP tooling and agentic build workflows — use `xcode-intelligence` / `xcode-agent-workflow`
- App Store Connect (signing, TestFlight, release) — use the `asc-*` family

---

## Core DNA

1. **`@Observable` is the state model.** The Observation framework gives field-level access tracking. Only the properties a view actually reads trigger re-evaluation. No `objectWillChange`, no over-invalidation. Use `@State` with `@Observable` classes; `@Environment` for DI; `@Bindable` for two-way bindings.

2. **No legacy property wrappers in new code.** `@StateObject`, `@ObservedObject`, `@EnvironmentObject` are replaced by `@State` + `@Observable`. `@Published` is gone in new code.

3. **Structured concurrency only.** `async/await`, `TaskGroup`, actors. No `DispatchQueue`, no completion handlers, no Combine publishers in new code. Respect Swift 6 strict concurrency checking (`@MainActor` for UI-bound work).

4. **Preview-driven development.** Every public view has a `#Preview`. If a view does not preview cleanly, it is not testable.

5. **Repository pattern for data access.** SwiftData and networking live behind protocol boundaries. ViewModels depend on the protocol, enabling testing with mock implementations.

6. **Platform-adaptive components.** Same logical behavior, different visual implementation per platform. `#if os(iOS)`, `#if os(macOS)`, `#if os(watchOS)`. Never force iOS navigation on macOS or vice versa.

---

## Swift language and concurrency (reference snapshot)

### Concurrency

Swift 6.2 ships two headline concurrency improvements:

**`@concurrent` function attribute** — marks a function that can be called concurrently from the nonisolated context without crossing actor boundaries:

```swift
// Swift 6.2: @concurrent allows parallel calls without actor isolation
@concurrent
func fetchUser(id: String) async throws -> User {
    try await networkClient.get("/users/\(id)")
}
```

**Main-actor-by-default inference mode** — opt your module into automatic `@MainActor` inference on types that touch UI, reducing manual annotation noise:

```swift
// module-level: @MainActor inference applied to all types
// Individual non-UI types still opt out with nonisolated
@MainActor
final class ProfileViewModel {
    var name = ""
    var isLoading = false

    func load() async {
        isLoading = true
        defer { isLoading = false }
        name = try await userRepository.fetchName()
    }
}
```

**Sendable conformance** — value types are implicitly Sendable. Reference types need explicit `@unchecked Sendable` (with manual synchronization) or actor isolation:

```swift
actor ImageCache {
    private var cache: [URL: UIImage] = [:]

    func image(for url: URL) -> UIImage? { cache[url] }
    func store(_ image: UIImage, for url: URL) { cache[url] = image }
}
```

**TaskGroup for parallel work:**

```swift
func fetchAllUsers(ids: [String]) async throws -> [User] {
    try await withThrowingTaskGroup(of: User.self) { group in
        for id in ids {
            group.addTask { try await fetchUser(id: id) }
        }
        return try await group.reduce(into: []) { $0.append($1) }
    }
}
```

### Memory: InlineArray and Span

Swift 6.2 adds two low-level types for zero-heap-allocation workloads:

**`InlineArray<N, T>`** — fixed-size, stack-allocated array. The count is part of the type:

```swift
// Zero heap allocation — entire array lives on the stack
var pixels: InlineArray<256, UInt8> = .init(repeating: 0)
pixels[42] = 255

// When to use InlineArray vs Array:
// InlineArray: known-size buffers, signal processing, ring buffers, hot paths
// Array: dynamic sizing, large collections, anything returned from a function
```

**`Span<T>` and `RawSpan`** — non-owning, non-escapable views into contiguous memory. Safe alternative to `UnsafeBufferPointer`:

```swift
func process(buffer: Span<UInt8>) {
    for byte in buffer {
        // safe, bounds-checked, no pointer arithmetic
    }
}

// Lifetime dependency — Span cannot outlive its source
var bytes: [UInt8] = [1, 2, 3, 4]
bytes.withSpan { span in
    process(buffer: span)  // span invalid after closure exits
}
```

---

## iOS Platform

> Verified 2026-06-04 against iOS 26. iOS 27 details land June 8 2026 — re-verify.

### Navigation

```swift
// NavigationStack with type-safe path
@Observable
final class AppRouter {
    var path = NavigationPath()
}

struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: ProductRoute.self) { route in
                    ProductDetailView(id: route.id)
                }
                .navigationDestination(for: SettingsRoute.self) { _ in
                    SettingsView()
                }
        }
        .environment(router)
    }
}
```

### SwiftUI + SwiftData

```swift
@Model
final class Note {
    var title: String
    var body: String
    var createdAt: Date

    init(title: String, body: String) {
        self.title = title
        self.body = body
        self.createdAt = .now
    }
}

struct NoteListView: View {
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @Environment(\.modelContext) private var context

    var body: some View {
        List(notes) { note in
            NavigationLink(note.title, value: note)
        }
        .toolbar {
            Button("New", systemImage: "plus") {
                let note = Note(title: "Untitled", body: "")
                context.insert(note)
            }
        }
    }
}
```

### `@Observable` MVVM

```swift
@Observable
final class ProfileViewModel {
    var name = ""
    var isLoading = false
    var error: Error?

    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func load(id: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            name = try await repository.fetchName(id: id)
        } catch {
            self.error = error
        }
    }
}

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text(viewModel.name)
            }
        }
        .task { await viewModel.load(id: "current") }
    }
}
```

### Dynamic Type and Accessibility

```swift
// Always use system font scaling — never fixed point sizes in user-visible text
Text("Heading")
    .font(.title)            // scales with Dynamic Type

// Accessibility modifiers
Image(systemName: "heart.fill")
    .accessibilityLabel("Favorites")
    .accessibilityHint("Double-tap to add to favorites")

// Reduce motion
@Environment(\.accessibilityReduceMotion) private var reduceMotion

var animation: Animation {
    reduceMotion ? .none : .spring(duration: 0.4)
}
```

---

## watchOS Platform

> Verified 2026-06-04 against watchOS 26. watchOS 27 details land June 8 2026 — re-verify.
> NOTE: Prior skill content referenced watchOS 9/10 baselines — those are stale. watchOS 26 is the current baseline.

### Watch Design Principles

- **Glanceable:** users look for 2 seconds, not 2 minutes. One key metric per screen.
- **Quick interactions:** primary actions complete within 2 taps.
- **Independent apps preferred** — Watch Connectivity for sync, not as a hard dependency.
- **Minimum touch target:** 38pt height.

### App Structure

```swift
@main
struct MyWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Navigation

```swift
// NavigationStack on watchOS 26
NavigationStack {
    List {
        NavigationLink("Metrics", value: Route.metrics)
        NavigationLink("History", value: Route.history)
    }
    .navigationDestination(for: Route.self) { route in
        switch route {
        case .metrics: MetricsView()
        case .history: HistoryView()
        }
    }
}

// TabView with vertical page style
TabView {
    HomeView()
    ActivityView()
    SettingsView()
}
.tabViewStyle(.verticalPage)
```

### Watch Connectivity

```swift
@Observable
final class ConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = ConnectivityManager()
    private(set) var isReachable = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        isReachable = session.isReachable
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    #endif
}
```

| Method | Use case | Delivery |
|--------|----------|----------|
| `updateApplicationContext` | Latest state (settings) | Overwrites previous |
| `sendMessage` | Real-time, both apps active | Immediate |
| `transferUserInfo` | Queued data | Guaranteed, in order |
| `transferFile` | Large data | Background transfer |

### WidgetKit Complications (watchOS 26)

```swift
import WidgetKit
import SwiftUI

struct MyComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MyComplication", provider: ComplicationProvider()) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("My Complication")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}
```

> watchOS 26 adds widget relevance APIs that let the system rank Smart Stack suggestions. Use `TimelineEntryRelevance` with a `score` and optional `duration` to signal when your complication is most important to the user.

### HealthKit + Workout Sessions

```swift
@Observable
class WorkoutManager {
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?

    func startWorkout(type: HKWorkoutActivityType) async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = type
        config.locationType = .outdoor

        session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        builder = session?.associatedWorkoutBuilder()
        session?.startActivity(with: .now)
        try await builder?.beginCollection(at: .now)
    }
}
```

### Digital Crown + Haptics

```swift
@State private var crownValue = 0.0

ScrollView { /* content */ }
    .focusable()
    .digitalCrownRotation($crownValue)

// Haptic feedback
WKInterfaceDevice.current().play(.click)
WKInterfaceDevice.current().play(.success)
```

---

## macOS Platform

> Verified 2026-06-04 against macOS 26 Tahoe. macOS 27 details land June 8 2026 — re-verify.

### macOS-Specific Navigation

```swift
// NavigationSplitView is the macOS standard (not NavigationStack)
NavigationSplitView {
    SidebarView()
} detail: {
    DetailView()
}

// WindowGroup for multi-window apps
WindowGroup {
    ContentView()
}
.windowStyle(.hiddenTitleBar)
.defaultSize(width: 900, height: 600)

// Settings window (macOS only)
Settings {
    SettingsView()
}
```

### AppKit ↔ SwiftUI Bridging

```swift
// NSViewRepresentable — wrap AppKit views in SwiftUI
struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}

// NSHostingView — embed SwiftUI in AppKit hierarchy
let hostingView = NSHostingView(rootView: MySwiftUIView())
```

### macOS 26 Tahoe — Scene Bridging

macOS 26 introduces scene-bridging, allowing UIKit / AppKit views to interoperate with SwiftUI scenes without boilerplate:

```swift
// Adopt scene-bridging when migrating AppKit-heavy windows
// Platform scenes can now exchange focus and state via shared environment
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.openWindow, openWindowAction)
        }
    }
}
```

### macOS 26 Tahoe — WebKit-for-SwiftUI

```swift
// WebPage and WebView available natively in SwiftUI on macOS 26
import WebKit

struct DocumentView: View {
    @State private var page = WebPage()

    var body: some View {
        WebView(page)
            .onAppear {
                page.load(URLRequest(url: URL(string: "https://example.com")!))
            }
    }
}
```

### macOS Sandbox and Entitlements

```swift
// Always request minimum entitlements
// Info.plist:
// NSAppleEventsUsageDescription — only if needed
// com.apple.security.app-sandbox = YES
// com.apple.security.files.user-selected.read-write = YES (for file open panels)
// com.apple.security.network.client = YES (for network access)

// File access via Security-scoped bookmarks
func openDocument() async {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.allowsMultipleSelection = false

    if await panel.begin() == .OK, let url = panel.url {
        let bookmark = try url.bookmarkData(options: .withSecurityScope)
        // Store bookmark for persistent access
    }
}
```

---

## tvOS and visionOS (Stub)

> These platforms share Swift 6.2, `@Observable`, and SwiftUI with iOS/macOS. Platform differences are surface-level. Full coverage deferred to dedicated skills when demand justifies it.

**tvOS:** Focus-based navigation (no touch), `focusSection()` / `hoverEffect(.highlight)`, remote-aware button interactions.

**visionOS:** `RealityView` for 3D content, `ImmersiveSpace` for full-immersion scenes, `ornament` modifier for 2D panels attached to volumes.

---

---

## Quality Gates

- [ ] All new observable state uses `@Observable` — no `@StateObject` / `@ObservedObject`
- [ ] All async work uses structured concurrency — no `DispatchQueue`, no Combine in new code
- [ ] `#Preview` exists for every public SwiftUI view
- [ ] `@MainActor` applied to UI-bound ViewModels and Views
- [ ] No force-unwraps (`!`) in production Swift code — use `guard` / `if let`
- [ ] Dynamic Type supported: all text uses system fonts or scaled custom fonts
- [ ] VoiceOver labels on all interactive elements and meaningful images
- [ ] `accessibilityReduceMotion` respected in all animations
- [ ] Platform APIs have availability checks matching the project's declared deployment targets
- [ ] macOS apps use `NavigationSplitView`, not `NavigationStack`

## Related Skills

- `apple-platform-design` — Liquid Glass, iOS 26 animation polish, HIG compliance (distinct design-DNA skill — do not fold into this one)
- `platform-design-guidelines` — Apple HIG fundamentals + Material Design 3 cross-platform
- `expo` — Expo Modules API (Swift side) + React Native/Expo engineering
- `mobile-app-security` — OWASP Mobile Top 10, Keychain secure storage
- `mobile-ui-testing` — agent-device, ViewInspector, Prefire, Maestro
- `xcode-intelligence` — Xcode MCP tools (BuildProject, RenderPreview, RunAllTests) — optional; provided by the host/global skill pool when Xcode 26+ is installed
