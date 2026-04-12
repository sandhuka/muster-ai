# iOS Security & Keychain

## Purpose
Define keychain operations, biometric authentication, CryptoKit usage, credential storage, and security anti-patterns for iOS development. See `team/developer/skills/ios-code-standards.md` for the `@AppStorage` rule. See `team/developer/skills/ios-networking.md` for Supabase auth integration. See `team/developer/skills/ios-concurrency.md` for actor patterns used in keychain wrappers. Target: **iOS 26+, Swift 6.2+**.

## Core Rules

These are non-negotiable security invariants — not style preferences.

1. **Never ignore `OSStatus`**. Every `SecItem*` call returns an `OSStatus`. Handle at minimum: `errSecSuccess`, `errSecDuplicateItem` (-25299), `errSecItemNotFound` (-25300), `errSecInteractionNotAllowed` (-25308). Silently discarding the return is the root cause of most keychain bugs.

2. **Never use `LAContext.evaluatePolicy()` as a standalone auth gate**. It returns a `Bool` trivially patchable at runtime via Frida. Biometric auth must be keychain-bound: store the secret behind `SecAccessControl` with `.biometryCurrentSet`, retrieve via `SecItemCopyMatching`. The Secure Enclave handles authentication — no `Bool` to patch.

3. **Never store secrets in `UserDefaults`, `Info.plist`, `.xcconfig`, or `NSCoding` archives**. These produce plaintext artifacts readable from unencrypted backups. The Keychain is the only Apple-sanctioned store for credentials. `@AppStorage` wraps `UserDefaults` — equally insecure.

4. **Never call `SecItem*` on `@MainActor`**. Keychain calls are IPC round-trips to `securityd` that block the calling thread. Use a dedicated `actor` for all keychain access.

5. **Always set `kSecAttrAccessible` explicitly**. The system default (`WhenUnlocked`) breaks background operations and makes security policy invisible in code review.

6. **Always use the add-or-update pattern**. `SecItemAdd` followed by `SecItemUpdate` on `errSecDuplicateItem`. Never delete-then-add (race window, destroys persistent references). Never call `SecItemAdd` without handling the duplicate case.

7. **First-launch keychain cleanup**. Keychain items survive app uninstallation. Check a `UserDefaults` flag on first launch, `SecItemDelete` across all `kSecClass` types to clear stale data from previous installs.

## Keychain Patterns

### Add-or-Update
```swift
actor KeychainService {
    func save(data: Data, service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        var status = SecItemAdd(query.merging(attributes) { $1 } as CFDictionary, nil)
        if status == errSecDuplicateItem {
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        }
        guard status == errSecSuccess else {
            throw KeychainError(status: status)
        }
    }
}
```

### Item Classes
| `kSecClass` | Use for | Key attributes |
|-------------|---------|---------------|
| `GenericPassword` | App secrets, tokens, API keys | `kSecAttrService` + `kSecAttrAccount` |
| `InternetPassword` | Web credentials (enables AutoFill) | `kSecAttrServer` + `kSecAttrAccount` |
| `Key` | Cryptographic keys | `kSecAttrKeyType` + `kSecAttrKeyClass` |

- Don't use `GenericPassword` with `kSecAttrServer` — wrong class for web credentials
- Don't combine `kSecAttrSynchronizable: true` with `ThisDeviceOnly` — contradictory constraints

## Accessibility Constants

| Constant | Background Safe | Survives Backup | Use When |
|----------|:-:|:-:|----------|
| `WhenPasscodeSetThisDeviceOnly` | No | No | Highest-security secrets; removed if passcode removed |
| `WhenUnlockedThisDeviceOnly` | No | No | Device-bound secrets, foreground-only |
| `WhenUnlocked` | No | Yes | Syncable secrets (system default — avoid implicit use) |
| `AfterFirstUnlockThisDeviceOnly` | Yes | No | **Background tasks, push handlers, device-bound** |
| `AfterFirstUnlock` | Yes | Yes | Background tasks that must survive restore |

Rule of thumb: Background access needed? `AfterFirstUnlockThisDeviceOnly`. Foreground-only? `WhenUnlockedThisDeviceOnly`. High-value? `WhenPasscodeSetThisDeviceOnly`. Non-`ThisDeviceOnly` only when iCloud sync or backup migration is required.

## Biometric Authentication

The only secure pattern is keychain-bound biometrics. `LAContext.evaluatePolicy()` alone is a critical vulnerability.

```swift
// Store secret behind biometric protection
let access = SecAccessControlCreateWithFlags(
    nil,
    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
    .biometryCurrentSet, // invalidates on enrollment change
    nil
)!

let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "com.app.auth",
    kSecAttrAccount as String: "biometric-token",
    kSecValueData as String: tokenData,
    kSecAttrAccessControl as String: access
]
// SecItemAdd → system prompts Face ID on SecItemCopyMatching
```

- Use `.biometryCurrentSet` (invalidates when biometrics change) over `.biometryAny` (persists across enrollment changes)
- Detect enrollment changes: compare `LAContext().evaluatedPolicyDomainState` across sessions
- Provide passcode fallback for accessibility — biometrics alone excludes users who cannot use them

## CryptoKit Quick Reference

| Need | Algorithm | Notes |
|------|-----------|-------|
| Hash data | `SHA256` / `SHA384` / `SHA512` / `SHA3_256` | SHA-3 included |
| Authenticate data (MAC) | `HMAC<SHA256>` | Constant-time comparison built in |
| Encrypt (authenticated) | `AES.GCM` | 256-bit key, random nonce auto-generated. **Never specify nonce manually** |
| Encrypt (mobile-optimized) | `ChaChaPoly` | Better on devices without AES-NI |
| Sign data | `P256.Signing` / `Curve25519.Signing` | P256 for interop, Curve25519 for performance |
| Key agreement | `P256.KeyAgreement` + `HKDF` | **Never use raw shared secret as key** |
| Hybrid public-key encryption | `HPKE` | Replaces manual ECDH+HKDF+AES-GCM chains |
| Hardware-backed signing | `SecureEnclave.P256.Signing` | P256 only; key never leaves hardware |
| Post-quantum key exchange | `MLKEM768` | iOS 26+, formal verification (ML-KEM FIPS 203) |
| Post-quantum signing | `MLDSA65` | iOS 26+, formal verification (ML-DSA FIPS 204) |
| Password → key derivation | PBKDF2 via `CommonCrypto` | Min 600,000 iterations SHA-256 (OWASP 2024) |
| Key → key derivation | `HKDF<SHA256>` | Always use info parameter for domain separation |

### Secure Enclave Constraints
- P256 only (classical) — no symmetric, no Curve25519
- Keys generated on-device only — cannot import external keys. `init(dataRepresentation:)` accepts only opaque blobs from previously created SE keys
- Device-bound — no backup, no sync
- Persist via keychain using the key's opaque `dataRepresentation`
- iOS 26 adds ML-KEM and ML-DSA post-quantum algorithms

## Credential Storage Patterns

### OAuth Token Lifecycle
- Store access token and refresh token as separate keychain items with distinct `kSecAttrAccount` values
- Access token: `AfterFirstUnlockThisDeviceOnly` (background refresh needs it)
- Refresh token: `WhenUnlockedThisDeviceOnly` or biometric-protected (higher value)
- On token refresh: update access token in place (add-or-update pattern)
- On logout: `SecItemDelete` both tokens. Verify deletion succeeded before clearing UI state

### API Keys
- Never hardcode in source — base64/hex strings in code are extractable from binaries
- Store in keychain on first launch (fetched from server or provisioned via config)
- For build-time secrets: use `.xcconfig` excluded from git + inject into keychain at app launch, never reference directly from code at runtime

### First-Launch Cleanup
```swift
func clearStaleKeychainOnFirstLaunch() {
    let key = "hasLaunchedBefore"
    guard !UserDefaults.standard.bool(forKey: key) else { return }

    let classes = [kSecClassGenericPassword, kSecClassInternetPassword,
                   kSecClassKey, kSecClassCertificate, kSecClassIdentity]
    for secClass in classes {
        SecItemDelete([kSecClass as String: secClass] as CFDictionary)
    }
    UserDefaults.standard.set(true, forKey: key)
}
```

## Anti-Pattern Quick Scan

When reviewing code, search for these patterns. Any match is a finding.

| Search for | Anti-pattern | Severity |
|-----------|-------------|----------|
| `UserDefaults.standard.set` + token/key/secret/password | Plaintext credential storage | CRITICAL |
| Hardcoded base64/hex strings (16+ chars) in source | Hardcoded cryptographic key | CRITICAL |
| `evaluatePolicy` without `SecItemCopyMatching` nearby | LAContext-only biometric gate | CRITICAL |
| `SecItemAdd` without checking `OSStatus` | Ignored error code | HIGH |
| No `kSecAttrAccessible` in add dictionary | Implicit accessibility class | HIGH |
| `AES.GCM.Nonce()` inside a loop with same key | Nonce reuse | CRITICAL |
| `sharedSecret.withUnsafeBytes` without HKDF | Raw shared secret as key | HIGH |
| `kSecAttrAccessibleAlways` | Deprecated accessibility constant | HIGH |
| `kSecAttrSynchronizable: true` + `ThisDeviceOnly` | Contradictory constraints | MEDIUM |
| `kSecClassGenericPassword` + `kSecAttrServer` | Wrong class for web credentials | MEDIUM |

## Keychain Sharing (App Extensions)

- Use `kSecAttrAccessGroup` with full `TEAMID.group.identifier` format
- Entitlements must match between app and extensions — `keychain-access-groups` for keychain sharing, `com.apple.security.application-groups` for App Groups
- Test on device — simulator keychain behavior differs from hardware
- iCloud Keychain sync: only items without `ThisDeviceOnly` are eligible

## Certificate Pinning

- Use SPKI (Subject Public Key Info) hash pinning — not leaf certificate pinning (breaks on annual rotation)
- Prefer `NSPinnedDomains` in `Info.plist` for declarative pinning (no code needed)
- For programmatic pinning: use `SecTrustEvaluateAsyncWithError` (not deprecated synchronous `SecTrustEvaluate`)
- Pin the CA or intermediate certificate for resilience — leaf pinning requires app update on every cert renewal

## Testing Security Code

- Use protocol-based abstraction for unit tests — wrap `SecItem*` behind a protocol, mock in tests
- Real keychain tests require device — simulator behavior differs for Secure Enclave and biometrics
- CI/CD: create a temporary keychain with `SecKeychainCreate` for test isolation
- Test `errSecItemNotFound` and `errSecInteractionNotAllowed` paths explicitly
- Never ship test keychain data — clean up in test teardown

## Principles

1. **Keychain is the only credential store**: No exceptions. `UserDefaults`, plists, `NSCoding`, and `@AppStorage` are plaintext. If it's a secret, it goes in the Keychain with an explicit accessibility class.

2. **Biometrics must be hardware-enforced**: `LAContext.evaluatePolicy()` returns a patchable boolean. Keychain-bound biometric auth delegates authentication to the Secure Enclave where there is no boolean to intercept.

3. **Every keychain call is fallible**: `OSStatus` is not optional. `errSecDuplicateItem` is not an error — it's the update path. `errSecInteractionNotAllowed` means retry later, not delete and retry. Build error handling into the pattern, not as an afterthought.

4. **Minimize attack surface**: Use the most restrictive `kSecAttrAccessible` that works. Use `ThisDeviceOnly` unless sync is required. Use `WhenPasscodeSet` for high-value secrets. Default to generating keys in the Secure Enclave when signing or key agreement is needed.
