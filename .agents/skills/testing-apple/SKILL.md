---
name: testing-apple
description: "Apple-platform testing skill — Swift Testing (modern, default) and XCTest for iOS/macOS unit and UI tests, ViewInspector for SwiftUI view-tree assertions, swift-snapshot-testing for pixel/structural snapshots, Prefire for auto-generated snapshot tests from #Preview declarations. Use when writing tests for Swift/SwiftUI/UIKit apps, choosing between Swift Testing and XCTest, setting up visual regression for SwiftUI, or doing TDD on Apple platforms. Cross-reference mobile-ui-testing (agent-device/Maestro/Detox) for E2E simulator automation and apple-native for Swift language internals. Triggers on 'swift testing', 'xctest', 'viewinspector', 'prefire', 'swift-snapshot-testing', 'swiftui test', 'ios test', 'macos test', 'characterization test', 'snapshot test swift', 'tdd swift', 'test contract swift', 'xcuitest', 'swift test pyramid'."
department: engineering
triggers:
  - swift testing
  - xctest
  - viewinspector
  - prefire
  - swift-snapshot-testing
  - swiftui test
  - ios test
  - macos test
  - characterization test swift
  - snapshot test swift
  - tdd swift
  - test contract swift
  - xcuitest
  - swift test pyramid
---

# Apple-Platform Testing

Testing skill for Swift, SwiftUI, and UIKit apps on iOS and macOS. Covers the full Apple test stack: Swift Testing (modern default), XCTest (legacy and UI tests), ViewInspector (SwiftUI view-tree assertions), swift-snapshot-testing (pixel + structural snapshots), and Prefire (auto-generated snapshots from `#Preview`).

> **Version:** Swift Testing ships with Xcode 16+ (Swift 6 / Swift 5.10 via backport). swift-snapshot-testing 1.17+. ViewInspector 0.10+. Prefire 0.9+. Verified 2026-06-04; re-verify after WWDC26 June 8 for any Swift/Xcode version claims.

## When to Invoke

Invoke this skill when:

- Writing unit or integration tests for Swift/SwiftUI code
- Choosing between Swift Testing and XCTest for a new project
- Adding ViewInspector assertions on SwiftUI view structure
- Setting up visual regression tests with swift-snapshot-testing or Prefire
- Implementing TDD red-green-refactor for new Swift features
- Writing characterization tests before refactoring existing Swift code
- Defining test contracts for protocols / interfaces
- Adding snapshot coverage for dark mode, Dynamic Type, and device variants

## When NOT to Use

- E2E simulator automation (tapping through full flows) — use `mobile-ui-testing` (agent-device / Maestro)
- React Native / Expo testing — use `mobile-ui-testing` or `testing`
- TypeScript / web testing — use `testing`
- Swift language internals, actors, concurrency — use `apple-native`

---

## Swift Testing vs XCTest

Swift Testing is the modern default (Xcode 16+). Prefer it for all new unit tests.

| Feature | Swift Testing | XCTest |
|---------|--------------|--------|
| Syntax | `@Test`, `#expect`, `#require` | `func test...`, `XCTAssert...` |
| Parameterized tests | `@Test(arguments:)` built-in | Manual loop or external lib |
| Async / actor support | `async` tests natively | `XCTestExpectation` boilerplate |
| Tagging / filtering | `@Suite`, `.tags` | Test plan groups |
| UI tests (XCUITest) | Not supported | XCTest only |
| Snapshot frameworks | Use alongside XCTest host | Native host |
| Adoption | All new unit tests | Existing suites + UI tests |

**Rule:** Write new unit tests in Swift Testing. Keep existing XCTest suites intact — mixed targets compile fine. UI tests (XCUITest) must stay on XCTest; Swift Testing has no UIKit event-injection surface.

---

## TDD Red-Green-Refactor (Swift)

```
1. RED     — Write the smallest @Test / func test... that fails to compile or asserts incorrectly
2. GREEN   — Write the minimal Swift code that makes the test pass
3. REFACTOR — Improve both production code and test without breaking green
4. COMMIT  — One atomic commit per coherent change
5. REPEAT
```

---

## Key Patterns

### Swift Testing — unit test

```swift
// Tests/CartTests/DiscountTests.swift
import Testing
@testable import CartModule

@Suite("Discount calculation")
struct DiscountTests {

    @Test("applies 10% when total exceeds threshold")
    func exceedsThreshold() {
        let discount = Discount(threshold: 100, percentage: 10)
        #expect(discount.amount(for: 150) == 15)
    }

    @Test("returns zero at exact threshold")
    func atThreshold() {
        let discount = Discount(threshold: 100, percentage: 10)
        #expect(discount.amount(for: 100) == 0)
    }

    @Test("returns zero below threshold")
    func belowThreshold() {
        let discount = Discount(threshold: 100, percentage: 10)
        #expect(discount.amount(for: 50) == 0)
    }

    // Parameterized — Swift Testing built-in
    @Test("boundary values", arguments: [
        (total: 0,   expected: 0),
        (total: 99,  expected: 0),
        (total: 101, expected: 10),
        (total: 1000, expected: 100),
    ])
    func boundaryValues(total: Decimal, expected: Decimal) {
        let discount = Discount(threshold: 100, percentage: 10)
        #expect(discount.amount(for: total) == expected)
    }
}
```

### XCTest — async test

```swift
// Tests/NetworkTests/UserServiceTests.swift
import XCTest
@testable import NetworkModule

final class UserServiceTests: XCTestCase {

    var sut: UserService!
    var mockSession: MockURLSession!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        sut = UserService(session: mockSession)
    }

    override func tearDown() {
        sut = nil
        mockSession = nil
        super.tearDown()
    }

    func test_fetchUser_returnsDecodedUser_onSuccess() async throws {
        // Arrange
        let userData = try JSONEncoder().encode(User(id: "u-1", name: "Alice"))
        mockSession.stub(data: userData, statusCode: 200)

        // Act
        let user = try await sut.fetchUser(id: "u-1")

        // Assert
        XCTAssertEqual(user.name, "Alice")
    }

    func test_fetchUser_throwsNotFound_on404() async {
        mockSession.stub(data: Data(), statusCode: 404)

        do {
            _ = try await sut.fetchUser(id: "u-1")
            XCTFail("Expected NetworkError.notFound")
        } catch NetworkError.notFound {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
```

### Characterization tests (capture current behavior before refactoring)

Write these BEFORE touching existing code. They document what the code actually does, not what it should do.

```swift
// Tests/LegacyCharacterization/PricingEngineCharacterizationTests.swift
import Testing
@testable import PricingModule

// These tests document the CURRENT behavior of PricingEngine.
// Do not "fix" a failing test here — it means you changed behavior.
// If behavior change is intentional, delete and replace the test.
@Suite("PricingEngine — characterization")
struct PricingEngineCharacterizationTests {

    let engine = PricingEngine()

    @Test("base price for tier-A item")
    func tierABasePrice() {
        #expect(engine.price(for: .init(sku: "A-001", tier: .a)) == 29.99)
    }

    @Test("zero price when stock is negative (legacy bug — do not fix without updating this test)")
    func negativStockReturnsZero() {
        #expect(engine.price(for: .init(sku: "A-001", tier: .a, stock: -1)) == 0)
    }
}
```

### Test contracts (protocol conformance)

```swift
// Tests/Contracts/StorageContractTests.swift
import Testing

// Any type conforming to DataStorage must satisfy this contract.
// Run against each implementation by calling storageContract(factory:) in its own test file.
func storageContract<S: DataStorage>(factory: () -> S) {
    @Suite struct Contract {
        let storage: S

        @Test("returns nil for a key that was never set")
        func missingKey() async throws {
            let result = try await storage.get("missing-key")
            #expect(result == nil)
        }

        @Test("round-trips a stored value")
        func roundTrip() async throws {
            try await storage.set("key", value: "hello")
            let result = try await storage.get("key")
            #expect(result == "hello")
        }

        @Test("delete removes the key")
        func deletion() async throws {
            try await storage.set("key", value: "hello")
            try await storage.delete("key")
            let result = try await storage.get("key")
            #expect(result == nil)
        }
    }
}

// Tests/InMemoryStorageTests.swift
import Testing
@testable import StorageModule

struct InMemoryStorageTests {
    init() { storageContract(factory: { InMemoryStorage() }) }
}
```

### ViewInspector — SwiftUI view-tree assertions

ViewInspector traverses the SwiftUI view hierarchy in tests without rendering pixels. Use it to assert on text content, button presence, modifier state, and accessibility identifiers.

```swift
// Tests/ViewTests/ProfileViewTests.swift
import XCTest
import ViewInspector
@testable import ProfileFeature

final class ProfileViewTests: XCTestCase {

    func test_displaysUserName() throws {
        let view = ProfileView(user: .mock(name: "Alice"))
        let name = try view.inspect()
            .find(viewWithAccessibilityIdentifier: "user-name")
            .text()
            .string()
        XCTAssertEqual(name, "Alice")
    }

    func test_editButtonIsDisabled_whenUserIsReadOnly() throws {
        let view = ProfileView(user: .mock(name: "Alice", readOnly: true))
        let button = try view.inspect()
            .find(viewWithAccessibilityIdentifier: "edit-button")
            .button()
        XCTAssertTrue(try button.isDisabled())
    }

    func test_loadingSpinner_visibleWhileFetching() throws {
        let vm = ProfileViewModel(state: .loading)
        let view = ProfileView(viewModel: vm)
        XCTAssertNoThrow(
            try view.inspect().find(ViewType.ProgressView.self)
        )
    }
}
```

### swift-snapshot-testing — pixel and structural snapshots

Use for design-critical screens where pixel accuracy matters. Golden images are stored in `__Snapshots__/` alongside the test file.

```swift
// Tests/SnapshotTests/ProfileSnapshotTests.swift
import XCTest
import SnapshotTesting
import SwiftUI
@testable import ProfileFeature

final class ProfileSnapshotTests: XCTestCase {

    func test_profileLoaded_lightMode() {
        let view = ProfileView(user: .mock(name: "Alice"))
        assertSnapshot(
            of: view,
            as: .image(
                layout: .device(config: .iPhone16),
                traits: UITraitCollection(userInterfaceStyle: .light)
            )
        )
    }

    func test_profileLoaded_darkMode() {
        let view = ProfileView(user: .mock(name: "Alice"))
        assertSnapshot(
            of: view,
            as: .image(
                layout: .device(config: .iPhone16),
                traits: UITraitCollection(userInterfaceStyle: .dark)
            )
        )
    }

    func test_profileLoaded_accessibilityExtraLarge() {
        let view = ProfileView(user: .mock(name: "Alice"))
        assertSnapshot(
            of: view,
            as: .image(
                layout: .device(config: .iPhone16),
                traits: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraLarge)
            )
        )
    }
}
```

Record new golden images (CI should never record — local only):

```bash
# Run once to record; remove the env var for subsequent verification runs
RECORD_SNAPSHOTS=1 xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Prefire — auto-generated snapshot tests from `#Preview`

Prefire scans your `#Preview` declarations and generates a snapshot test for each one. No manual snapshot test code needed.

```swift
// 1. Author your previews as normal
#Preview("Profile — loaded") {
    ProfileView(user: .mock(name: "Alice"))
}

#Preview("Profile — loading") {
    ProfileView(viewModel: .mockLoading)
}

#Preview("Profile — error") {
    ProfileView(viewModel: .mockError)
}

// 2. Run the generator:
//    swift package plugin --allow-writing-to-package-directory prefire-generate
//
// 3. Prefire writes: Tests/PrefireTests/ProfileViewTests.swift (do not edit — auto-generated)
//
// 4. On every CI run these tests verify no visual regression across all your previews.
```

**Rule:** every `#Preview` declaration is implicitly a regression test commitment. If you add a preview, Prefire adds a test. If you delete a preview, the test disappears. This enforces test coverage by construction.

---

## Snapshot Naming Convention

```
__Snapshots__/
  ProfileSnapshotTests/
    test_profileLoaded_lightMode.iPhone16.png
    test_profileLoaded_darkMode.iPhone16.png
    test_profileLoaded_accessibilityExtraLarge.iPhone16.png
```

Format: `{testMethod}.{device}.png`

Store golden images in Git LFS for large repos:

```gitattributes
# .gitattributes
**/__Snapshots__/**/*.png filter=lfs diff=lfs merge=lfs -text
```

---

## Test Data Factories

```swift
// Tests/Factories/UserFactory.swift
extension User {
    static func mock(
        id: String = "user-\(UUID().uuidString.prefix(8))",
        name: String = "Test User",
        email: String = "test@example.com",
        readOnly: Bool = false
    ) -> User {
        User(id: id, name: name, email: email, readOnly: readOnly)
    }
}
```

---

## Quality Gates

- [ ] New unit tests written in Swift Testing (`@Test`, `#expect`) — not `func test...` unless in an existing XCTest file
- [ ] Characterization tests exist before any refactor of untested legacy code
- [ ] ViewInspector tests cover view-tree assertions; pixel assertions use swift-snapshot-testing
- [ ] Snapshots cover light mode, dark mode, and at least one Dynamic Type size
- [ ] `#Preview` declarations exist for all design-critical views (Prefire will pick them up)
- [ ] Golden images stored in Git LFS (repos with >20 snapshots)
- [ ] `RECORD_SNAPSHOTS` env var never set in CI — only record locally
- [ ] Test contracts run against every implementation of a protocol
- [ ] No `XCTAssert` in Swift Testing targets (mixing assertion APIs)
- [ ] Async tests use `async throws` (Swift Testing) or `XCTestExpectation` (XCTest) — never `DispatchSemaphore`

---

## Related Skills

- `mobile-ui-testing` — agent-device (Callstack), Maestro, and Detox for full E2E simulator automation; cross-platform flows
- `apple-native` — Swift language internals: actors, Sendable, structured concurrency, SwiftData
- `testing` — TypeScript/web testing: Vitest, Playwright, MSW, Testing Library
