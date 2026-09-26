---
name: mobile-app-security
description: "OWASP Mobile Top 10 2024 + MASVS security controls for React Native and native iOS/Android apps. Cross-platform: covers both React Native (expo-secure-store, TurboModule cert-pinning) and Swift/Keychain patterns. Use when building, auditing, or reviewing mobile applications. Triggers on 'mobile security', 'certificate pinning', 'secure storage mobile', 'mobile owasp', 'react native security', 'ios keychain', 'android keystore', 'masvs'."
department: engineering
triggers:
  - mobile security
  - certificate pinning
  - secure storage mobile
  - mobile owasp
  - react native security
  - ios keychain
  - android keystore
  - masvs
  - security-audit
  - implement-prd
  - mobile-feature
---

# Mobile App Security Skill

Comprehensive coverage of the **OWASP Mobile Top 10 2024** and **MASVS** with cross-platform code examples for both React Native and native iOS (Swift). Use this skill when building, auditing, or reviewing mobile applications.

> Version anchor: OWASP Mobile Top 10 2024 (no 2026 revision has shipped as of 2026-06-04). React Native 0.85+ (post-bridge — new arch is the only runtime). Verified 2026-06-04.

> **RN 0.85 post-bridge note:** React Native 0.85 removed the JS↔native bridge entirely. New arch (Fabric + TurboModules + Codegen) is the only runtime. Certificate-pinning and secure-storage native modules must be new-arch / TurboModule compatible. Legacy `NativeModules` interop is gone — any security module using the old bridge architecture will not work on 0.85+.

## When to Invoke

Invoke this skill when:

- Building React Native or native iOS/Android mobile applications
- Running security audits on mobile apps
- Implementing secure storage, authentication, or network communication
- Reviewing mobile app code for security vulnerabilities
- Designing mobile architecture (Step 2, Step 8)

---

## M1:2024 — Improper Credential Usage

Hardcoded credentials, improper storage of API keys, or misuse of authentication credentials.

### React Native — Bad Pattern

```typescript
// VULNERABLE: Hardcoded API keys in source code
const API_KEY = 'sk_live_<REDACTED_EXAMPLE_never_hardcode_a_real_key>';

// VULNERABLE: Storing credentials in AsyncStorage (unencrypted)
import AsyncStorage from '@react-native-async-storage/async-storage';
await AsyncStorage.setItem('auth_token', token);
```

### React Native — Good Pattern

```typescript
// SECURE: expo-secure-store maps to iOS Keychain / Android Keystore
import * as SecureStore from 'expo-secure-store';

async function storeCredentials(token: string, refreshToken: string) {
  await SecureStore.setItemAsync('auth_token', token);
  await SecureStore.setItemAsync('refresh_token', refreshToken);
}

async function getCredentials() {
  const token = await SecureStore.getItemAsync('auth_token');
  const refresh = await SecureStore.getItemAsync('refresh_token');
  return token && refresh ? { token, refresh } : null;
}

async function clearCredentials() {
  await SecureStore.deleteItemAsync('auth_token');
  await SecureStore.deleteItemAsync('refresh_token');
}

// SECURE: API keys from build-time environment variables
// Use expo-constants / react-native-config — never hardcoded strings
import Constants from 'expo-constants';
const apiKey = Constants.expoConfig?.extra?.apiKey;
```

### Swift / iOS — Keychain Pattern

```swift
import Security

// SECURE: Store token in iOS Keychain with strict accessibility
func storeToken(_ token: String, key: String) throws {
    guard let data = token.data(using: .utf8) else { throw KeychainError.encodingFailed }

    let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrAccount: key,
        kSecValueData: data,
        // WHEN_UNLOCKED_THIS_DEVICE_ONLY prevents iCloud backup and migration
        kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    if status == errSecDuplicateItem {
        // Update existing item
        let update: [CFString: Any] = [kSecValueData: data]
        SecItemUpdate(query as CFDictionary, update as CFDictionary)
    } else if status != errSecSuccess {
        throw KeychainError.unexpectedStatus(status)
    }
}

func retrieveToken(key: String) throws -> String? {
    let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrAccount: key,
        kSecReturnData: true,
        kSecMatchLimit: kSecMatchLimitOne,
    ]
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data else { return nil }
    return String(data: data, encoding: .utf8)
}

func deleteToken(key: String) {
    let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrAccount: key,
    ]
    SecItemDelete(query as CFDictionary)
}

enum KeychainError: Error {
    case encodingFailed
    case unexpectedStatus(OSStatus)
}
```

### Remediation Checklist

- [ ] Never hardcode API keys, secrets, or credentials in source code
- [ ] Use `expo-secure-store` (RN) or Keychain Services (Swift) for credential storage
- [ ] Use `expo-constants` / `react-native-config` for build-time environment variables
- [ ] Set `WHEN_UNLOCKED_THIS_DEVICE_ONLY` accessibility for Keychain items
- [ ] Clear credentials on logout

---

## M2:2024 — Inadequate Supply Chain Security

Vulnerable or malicious third-party libraries, SDK integrations, and build pipeline compromises.

### Good Pattern

```json
// package.json — dependency security practices
{
  "scripts": {
    "audit": "npm audit --production",
    "audit:fix": "npm audit fix",
    "verify-pods": "cd ios && pod audit"
  },
  "resolutions": {
    "minimist": ">=1.2.8",
    "json5": ">=2.2.3"
  }
}
```

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "gradle"
    directory: "/android"
    schedule:
      interval: "weekly"
  - package-ecosystem: "cocoapods"
    directory: "/ios"
    schedule:
      interval: "weekly"
```

### Remediation Checklist

- [ ] Run `npm audit` and `pod audit` in CI
- [ ] Use Dependabot for npm, CocoaPods, and Gradle
- [ ] Pin native SDK versions (no floating `~` or `^` for security-critical packages)
- [ ] Review native module permissions before adding

---

## M3:2024 — Insecure Authentication/Authorization

Weak authentication, missing server-side validation, or client-side-only authorization.

### Bad Pattern

```typescript
// VULNERABLE: Client-side only role check
function AdminScreen() {
  const { user } = useAuth();
  // Attacker can modify the app to bypass this check
  if (user.role !== 'admin') return <Redirect to="/home" />;
  return <AdminPanel />;
}
```

### React Native — Good Pattern

```typescript
// SECURE: Biometric authentication
import * as LocalAuthentication from 'expo-local-authentication';

async function authenticateWithBiometrics(): Promise<boolean> {
  const compatible = await LocalAuthentication.hasHardwareAsync();
  if (!compatible) return false;

  const enrolled = await LocalAuthentication.isEnrolledAsync();
  if (!enrolled) return false;

  const result = await LocalAuthentication.authenticateAsync({
    promptMessage: 'Confirm your identity',
    cancelLabel: 'Cancel',
  });

  return result.success;
}

// SECURE: Server-validated authorization
async function fetchAdminData() {
  const token = await SecureStore.getItemAsync('auth_token');
  if (!token) throw new Error('Not authenticated');

  // Server validates token AND role — client check is UX only
  const response = await fetch('/api/admin/dashboard', {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (response.status === 403) throw new Error('Not authorized');
  return response.json();
}
```

### Swift / iOS — Biometric Pattern

```swift
import LocalAuthentication

func authenticateWithBiometrics() async throws -> Bool {
    let context = LAContext()
    var error: NSError?

    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
        return false
    }

    return try await context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
        localizedReason: "Confirm your identity"
    )
}
```

---

## M4:2024 — Insufficient Input/Output Validation

Missing validation of data from servers, deep links, intents, and user input.

### Bad Pattern

```typescript
// VULNERABLE: Deep link without validation
function DeepLinkHandler({ url }: { url: string }) {
  const productId = url.split('/').pop();
  // No validation — attacker can inject malicious IDs
  navigation.navigate('Product', { id: productId });
}
```

### Good Pattern

```typescript
// SECURE: Deep link validation with Zod
import { z } from 'zod';
import { Linking } from 'react-native';

const deepLinkSchema = z.object({
  productId: z.string().uuid(),
});

function useDeepLinks() {
  useEffect(() => {
    const handleDeepLink = (event: { url: string }) => {
      try {
        const url = new URL(event.url);
        if (url.protocol !== 'myapp:') return;

        const match = url.pathname.match(/^\/product\/(.+)$/);
        if (!match) return;

        const result = deepLinkSchema.safeParse({ productId: match[1] });
        if (!result.success) {
          console.warn('Invalid deep link parameters');
          return;
        }
        navigation.navigate('Product', { id: result.data.productId });
      } catch {
        console.warn('Invalid deep link URL');
      }
    };

    const subscription = Linking.addEventListener('url', handleDeepLink);
    return () => subscription.remove();
  }, []);
}

// SECURE: Server response validation
const productSchema = z.object({
  id: z.string().uuid(),
  name: z.string().max(200),
  price: z.number().min(0),
  description: z.string().max(5000),
});

async function fetchProduct(id: string) {
  const response = await apiClient.get(`/products/${id}`);
  const result = productSchema.safeParse(response.data);
  if (!result.success) throw new Error('Invalid server response');
  return result.data;
}
```

---

## M5:2024 — Insecure Communication

Unencrypted network traffic, missing certificate pinning, and TLS misconfigurations.

### Certificate Pinning — React Native (post-bridge, RN 0.85+)

> **RN 0.85 note:** `react-native-ssl-pinning` must be a TurboModule-compatible version. Verify the package supports the new architecture before installing in an RN 0.85+ project. Alternative: implement a native module via the Expo Modules API with Swift/Kotlin doing the pinning.

```typescript
// SECURE: Certificate pinning — verify package supports New Architecture
import { fetch as pinnedFetch } from 'react-native-ssl-pinning';

async function secureApiCall(endpoint: string, options: RequestInit = {}) {
  const response = await pinnedFetch(`https://api.example.com${endpoint}`, {
    ...options,
    sslPinning: {
      certs: ['api_cert'],  // Certificate in app bundle (SPKI hash recommended)
    },
    timeoutInterval: 10000,
  });
  return response.json();
}
```

### Certificate Pinning — Android Network Security Config

```xml
<!-- android/app/src/main/res/xml/network_security_config.xml -->
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <domain-config>
    <domain includeSubdomains="true">api.example.com</domain>
    <!-- Pin SPKI hashes, not leaf certificates — easier to rotate -->
    <pin-set expiration="2027-01-01">
      <pin digest="SHA-256">AABBCC...primary_pin==</pin>
      <pin digest="SHA-256">DDEEFF...backup_pin==</pin>
    </pin-set>
  </domain-config>
  <base-config cleartextTrafficPermitted="false" />
</network-security-config>
```

### Certificate Pinning — iOS (App Transport Security)

```xml
<!-- ios/Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <false/>
</dict>
```

For pinning in Swift, use `URLSessionDelegate` to implement SPKI hash verification:

```swift
// SECURE: SPKI hash pinning in URLSession
final class PinningDelegate: NSObject, URLSessionDelegate {
    private let pinnedHashes: Set<String> = [
        "AABBCC...primary_hash==",
        "DDEEFF...backup_hash==",
    ]

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust,
            let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard let spkiHash = extractSPKIHash(from: certificate) else {
            completionHandler(.cancelAuthenticationChallenge, nil)   // fail closed
            return
        }
        if pinnedHashes.contains(spkiHash) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    // Requires: import CryptoKit
    // Pins the SHA-256 of the SubjectPublicKeyInfo (SPKI), not the leaf certificate.
    private func extractSPKIHash(from certificate: SecCertificate) -> String? {
        guard
            let publicKey = SecCertificateCopyKey(certificate),
            let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?
        else { return nil }

        // ASN.1 SubjectPublicKeyInfo header for an RSA-2048 key. Use the header that
        // MATCHES your server's key type/size — an EC-P256 key needs a different
        // header, and a mismatch silently fails every pin check. For a vetted,
        // key-type-agnostic implementation, prefer TrustKit over hand-rolling this.
        let rsa2048SPKIHeader: [UInt8] = [
            0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09,
            0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
            0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00,
        ]
        var spki = Data(rsa2048SPKIHeader)
        spki.append(keyData)
        return Data(SHA256.hash(data: spki)).base64EncodedString()   // CryptoKit
    }
}
```

### Remediation Checklist

- [ ] Certificate pinning implemented with at least 2 pins (primary + backup)
- [ ] Pinning SPKI hashes, not leaf certificates
- [ ] Android: `cleartextTrafficPermitted="false"` in network security config
- [ ] iOS: `NSAllowsArbitraryLoads` set to `false` in Info.plist
- [ ] RN 0.85+: pinning native modules verified to be new-arch (TurboModule) compatible
- [ ] SPKI hash extracted with the ASN.1 header matching your server's key type (or use TrustKit) — a header mismatch silently fails closed

---

## M6:2024 — Inadequate Privacy Controls

Exposing PII, insufficient data minimization, missing consent management.

### Good Pattern

```typescript
// SECURE: Data minimization in API requests
async function fetchUserProfile(userId: string) {
  const response = await apiClient.get(`/users/${userId}`, {
    params: { fields: 'name,avatar,preferences' },  // Exclude PII not needed
  });
  return response.data;
}

// SECURE: Auto-clear clipboard for sensitive data
import * as Clipboard from 'expo-clipboard';

function useSensitiveClipboard() {
  const copyToClipboard = async (value: string) => {
    await Clipboard.setStringAsync(value);
    setTimeout(() => Clipboard.setStringAsync(''), 30000);
  };
  return { copyToClipboard };
}

function maskSensitiveData(value: string): string {
  if (value.length <= 4) return '****';
  return '****' + value.slice(-4);
}
```

### iOS ATT (App Tracking Transparency)

```swift
import AppTrackingTransparency

func requestTrackingPermission() async {
    // Must be called before any tracking occurs
    let status = await ATTrackingManager.requestTrackingAuthorization()
    switch status {
    case .authorized:
        // Tracking allowed — initialize analytics SDKs
        break
    default:
        // Do not track — do not initialize tracking SDKs
        break
    }
}
```

---

## M7:2024 — Insufficient Binary Protections

Lack of code obfuscation, anti-tampering, and reverse engineering protection.

### React Native

```javascript
// metro.config.js — Hermes bytecode compilation (default in RN 0.84+)
// Hermes V1 is the default in RN 0.84+ — no extra config needed
// Confirm in app.json:
// "jsEngine": "hermes"
```

```groovy
// android/app/build.gradle — Enable ProGuard/R8 for release builds
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

```typescript
// SECURE: Jailbreak/root detection
import JailMonkey from 'jail-monkey';

function SecurityGate({ children }: { children: React.ReactNode }) {
  const [isSecure, setIsSecure] = useState(true);

  useEffect(() => {
    const isJailbroken = JailMonkey.isJailBroken();
    const isDebugged = JailMonkey.isDebuggedMode();

    if (isJailbroken || isDebugged) {
      setIsSecure(false);
      // Log security event to server
      apiClient.post('/api/security/device-check', { jailbroken: isJailbroken, debugged: isDebugged });
    }
  }, []);

  if (!isSecure) {
    return (
      <View>
        <Text>This app cannot run on compromised devices.</Text>
      </View>
    );
  }
  return <>{children}</>;
}
```

### iOS — Strip Debug Symbols in Release

```xml
<!-- Xcode build settings (via project.pbxproj or xcconfig) -->
<!-- STRIP_DEBUG_SYMBOLS = YES (release only) -->
<!-- GCC_GENERATE_DEBUGGING_SYMBOLS = NO (release only) -->
```

---

## M8:2024 — Security Misconfiguration

Debug settings in production, excessive permissions, insecure default configurations.

### Remediation Checklist

- [ ] Disable debug logging in production builds
- [ ] `android:debuggable` absent or `false` in release AndroidManifest
- [ ] `NSAllowsArbitraryLoads` set to `false` in iOS Info.plist
- [ ] Android: `cleartextTrafficPermitted="false"` in network security config
- [ ] Request only necessary permissions; remove unused permissions from AndroidManifest
- [ ] Android: `android:allowBackup="false"` unless backup is explicitly required
- [ ] WebViews: disable JavaScript unless required; configure strict content policies

---

## M9:2024 — Insecure Data Storage

Storing sensitive data in unprotected locations (AsyncStorage, SharedPreferences, plain SQLite).

### Storage Classification

```typescript
type DataClassification = 'public' | 'internal' | 'sensitive' | 'restricted';

// Storage tier map
// public    → MMKV or AsyncStorage (non-sensitive prefs, theme, language)
// internal  → MMKV (app state, non-sensitive settings)
// sensitive → expo-secure-store (user profile with PII, non-token secrets)
// restricted → expo-secure-store with hardware security (tokens, passwords, biometric keys)
```

### React Native — Secure Storage

```typescript
import * as SecureStore from 'expo-secure-store';

// expo-secure-store maps directly to:
// iOS: Keychain Services (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
// Android: EncryptedSharedPreferences backed by Android Keystore

async function storeSecureData(key: string, value: string) {
  await SecureStore.setItemAsync(key, value, {
    requireAuthentication: false,  // set true for biometric-gated items
  });
}

async function getSecureData(key: string): Promise<string | null> {
  return SecureStore.getItemAsync(key);
}
```

### Swift / iOS — Avoid Insecure Storage

```swift
// NEVER store sensitive data in UserDefaults
// UserDefaults.standard.set(token, forKey: "auth_token")  ← WRONG

// NEVER store in plain files without encryption
// try data.write(to: documentsURL.appendingPathComponent("token.txt"))  ← WRONG

// CORRECT: iOS Keychain (see M1 section for full implementation)
try storeToken(token, key: "auth_token")
```

---

## M10:2024 — Insufficient Cryptography

Using weak algorithms, hardcoded keys, or improper crypto implementations.

### React Native

```typescript
// SECURE: Use platform crypto, not custom implementations
import crypto from 'react-native-quick-crypto';

function generateSecureRandom(length: number): string {
  const bytes = crypto.randomBytes(length);
  return bytes.toString('hex');
}

async function deriveKey(password: string, salt: string): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    crypto.pbkdf2(password, salt, 100000, 32, 'sha256', (err, key) => {
      if (err) reject(err);
      else resolve(key);
    });
  });
}
```

### Swift / iOS — CryptoKit

```swift
import CryptoKit

// SECURE: AES-256-GCM symmetric encryption
func encrypt(_ plaintext: Data, using key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.seal(plaintext, using: key)
    return sealedBox.combined ?? Data()
}

func decrypt(_ ciphertext: Data, using key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
    return try AES.GCM.open(sealedBox, using: key)
}

// SECURE: Generate a random 256-bit key
let key = SymmetricKey(size: .bits256)

// SECURE: ECDSA P-256 signing
let signingKey = P256.Signing.PrivateKey()
let signature = try signingKey.signature(for: data)
let isValid = signingKey.publicKey.isValidSignature(signature, for: data)

// NEVER: custom crypto, MD5, SHA-1 for security purposes, ECB mode
```

---

## Screenshot Prevention

```typescript
// SECURE: Prevent screenshots on sensitive screens
import { useIsFocused } from '@react-navigation/native';
import { Platform, NativeModules } from 'react-native';

function usePreventScreenCapture(enabled = true) {
  const isFocused = useIsFocused();

  useEffect(() => {
    if (!enabled || !isFocused) return;

    if (Platform.OS === 'android') {
      NativeModules.FlagSecure?.enable();
    }
    // iOS: use UIScreen.main.isCaptured observer or UITextField.isSecureTextEntry pattern

    return () => {
      if (Platform.OS === 'android') {
        NativeModules.FlagSecure?.disable();
      }
    };
  }, [enabled, isFocused]);
}
```

---

## Cross-Platform Storage Summary

| Data type | React Native | Swift / iOS |
|-----------|-------------|-------------|
| Auth tokens, passwords | `expo-secure-store` | Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) |
| Biometric-gated secrets | `expo-secure-store` with `requireAuthentication: true` | Keychain with `kSecAccessControlBiometryCurrentSet` |
| Fast non-sensitive prefs | MMKV | `UserDefaults` |
| Sensitive non-token data | `expo-secure-store` | Keychain or encrypted file with CryptoKit |
| Never for secrets | `AsyncStorage`, plain SQLite | `UserDefaults`, plain `UserDefaults.standard` |

---

## Mobile Security Audit Checklist

### Storage

- [ ] Credentials stored in `expo-secure-store` / Keychain (not AsyncStorage or UserDefaults)
- [ ] Sensitive data encrypted at rest
- [ ] No sensitive data in app logs or crash reports
- [ ] Clipboard auto-cleared for sensitive data

### Network

- [ ] Certificate pinning implemented with SPKI hashes + backup pin
- [ ] No cleartext (HTTP) traffic allowed in any build
- [ ] API responses validated with schemas (Zod or Swift Codable with strict decoding)
- [ ] TLS 1.2+ enforced; ATS enforced on iOS
- [ ] RN 0.85+: pinning module is New Architecture / TurboModule compatible

### Authentication

- [ ] Biometric authentication for sensitive operations (`expo-local-authentication` / `LocalAuthentication`)
- [ ] Tokens stored in secure storage; never in AsyncStorage or UserDefaults
- [ ] Session timeout implemented
- [ ] Server-side authorization (not client-only role checks)

### Binary

- [ ] Hermes bytecode compilation enabled (default in RN 0.84+)
- [ ] ProGuard/R8 enabled for Android release builds
- [ ] Debug symbols stripped from iOS release builds
- [ ] Jailbreak/root detection active for sensitive apps
- [ ] No hardcoded secrets in source (verify with secrets-detection tooling)

### Input

- [ ] Deep links validated against schemas
- [ ] Server responses validated before use
- [ ] User input sanitized for injection risks

### Privacy

- [ ] ATT requested before any tracking on iOS
- [ ] Minimum permissions requested; unused permissions removed
- [ ] Data minimization: collect only what the feature requires

---

## Integration with Sigma Protocol

### Step 8 (Technical Spec)

Reference mobile security requirements when designing app architecture.

### /implement-prd

Check mobile implementations against M1–M10 before marking a PRD complete.

### Step 2 (Architecture)

Include MASVS control groups in the architecture review: STORAGE, CRYPTO, AUTH, NETWORK, PLATFORM, CODE, PRIVACY.

---

## When NOT to Use

- Web application security — use `owasp-web-security`
- Backend API security — use `owasp-api-security`
- LLM / AI safety — use `owasp-llm-security`
- Infrastructure / cloud security — scope is mobile client-side only

---

_Mobile apps are distributed to untrusted devices. Every piece of data stored locally and every network call must be treated as potentially interceptable._
