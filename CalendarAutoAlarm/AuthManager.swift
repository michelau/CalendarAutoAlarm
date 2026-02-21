import AuthenticationServices
import Foundation
import SwiftUI

/// Manages Google OAuth 2.0 sign-in via ASWebAuthenticationSession.
///
/// ## Configuration
/// Set your Google OAuth client ID in `Info.plist` under the key `GoogleOAuthClientID`.
/// The redirect URI must match the custom URL scheme registered in `Info.plist` under `CFBundleURLSchemes`.
///
/// ## Required Google Cloud Setup
/// 1. Create a project at https://console.cloud.google.com
/// 2. Enable the **Google Calendar API**
/// 3. Create an **OAuth 2.0 client ID** of type *iOS* with your app's bundle ID
/// 4. Copy the client ID into `Info.plist` → `GoogleOAuthClientID`
@MainActor
final class AuthManager: NSObject, ObservableObject {

    // MARK: - Published state

    @Published private(set) var isSignedIn = false
    @Published private(set) var accessToken: String?
    @Published var errorMessage: String?

    // MARK: - Private constants

    private let keychainKey = "com.calendarautoalarm.accessToken"
    private let tokenExpiryKey = "com.calendarautoalarm.tokenExpiry"
    private let scope = "https://www.googleapis.com/auth/calendar.readonly"
    private let authEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    private let tokenEndpoint = "https://oauth2.googleapis.com/token"

    // MARK: - Init

    override init() {
        super.init()
        loadStoredToken()
    }

    // MARK: - Public API

    /// Launches the Google sign-in flow in a web authentication session.
    func signIn() async {
        guard let clientID = Bundle.main.infoDictionary?["GoogleOAuthClientID"] as? String,
              !clientID.isEmpty,
              !clientID.hasPrefix("YOUR_") else {
            errorMessage = "Google OAuth client ID is not configured. See README for setup instructions."
            return
        }

        let redirectScheme = "com.googleusercontent.apps.\(clientID)"
        let redirectURI   = "\(redirectScheme):/oauth2callback"
        let state         = UUID().uuidString

        var components = URLComponents(string: authEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id",     value: clientID),
            URLQueryItem(name: "redirect_uri",  value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope",         value: scope),
            URLQueryItem(name: "state",         value: state),
            URLQueryItem(name: "access_type",   value: "offline")
        ]

        guard let authURL = components.url else {
            errorMessage = "Failed to build authorization URL."
            return
        }

        do {
            let callbackURL = try await startWebAuthSession(
                url: authURL,
                callbackScheme: redirectScheme
            )
            await exchangeCodeForToken(
                callbackURL: callbackURL,
                clientID: clientID,
                redirectURI: redirectURI
            )
        } catch ASWebAuthenticationSessionError.canceledLogin {
            // User cancelled – silently ignore
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Signs out and removes the stored token.
    func signOut() {
        accessToken = nil
        isSignedIn  = false
        UserDefaults.standard.removeObject(forKey: tokenExpiryKey)
        deleteTokenFromKeychain()
    }

    // MARK: - Private helpers

    private func startWebAuthSession(
        url: URL,
        callbackScheme: String
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(
                        throwing: URLError(.badServerResponse)
                    )
                }
            }
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    private func exchangeCodeForToken(
        callbackURL: URL,
        clientID: String,
        redirectURI: String
    ) async {
        guard
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
            let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            errorMessage = "Authorization code not found in callback URL."
            return
        }

        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "code":          code,
            "client_id":     clientID,
            "redirect_uri":  redirectURI,
            "grant_type":    "authorization_code"
        ]
        .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
        .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONDecoder().decode(TokenResponse.self, from: data)

            accessToken = json.access_token
            isSignedIn  = true

            saveTokenToKeychain(json.access_token)
            if let expiresIn = json.expires_in {
                UserDefaults.standard.set(
                    Date().addingTimeInterval(Double(expiresIn)),
                    forKey: tokenExpiryKey
                )
            }
        } catch {
            errorMessage = "Token exchange failed: \(error.localizedDescription)"
        }
    }

    private func loadStoredToken() {
        guard let token = loadTokenFromKeychain() else { return }
        if let expiry = UserDefaults.standard.object(forKey: tokenExpiryKey) as? Date,
           expiry > Date() {
            accessToken = token
            isSignedIn  = true
        }
    }

    // MARK: - Keychain helpers

    private func saveTokenToKeychain(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: keychainKey,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadTokenFromKeychain() -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      keychainKey,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else { return nil }
        return token
    }

    private func deleteTokenFromKeychain() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: keychainKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - OAuth token response

private struct TokenResponse: Decodable {
    let access_token: String
    let expires_in: Int?
    let token_type: String?
}
