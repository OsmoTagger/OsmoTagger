//
//  OsmClient.swift
//  OSM editor
//
//  Created by Arkadiy on 02.11.2022.
//

import AuthenticationServices
import Foundation
import UIKit
import XMLCoder

// Class for working with the OSM API.  Later it is necessary to get rid of singleton
class OsmClient: NSObject, ASWebAuthenticationPresentationContextProviding {
    static var client = OsmClient()
    
    var session: ASWebAuthenticationSession?
    typealias AuthCallback = (AuthResult) -> Void
    var callback: AuthCallback?
    let redirectUrl = "https://osmotagger.github.io/oauth2/"
    
    private override init() {
        
    }
    
    // MARK: OAuth 2.0
    
    //  The authorization verification method, and in case of its absence, the authorization is launched
    func checkAuth() async throws {
        if AppSettings.settings.token == nil {
            let code = try await authSessionStartAsync()
            let token = try await getAccessToken(code: code)
            AppSettings.settings.token = token
        }
    }
    
    //  The method starts ASWebAuthenticationSession in async
    func authSessionStartAsync() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            authSessionStart(handler: { result in
                if case let .success(token) = result {
                    continuation.resume(returning: token)
                } else if case let .error(err) = result {
                    continuation.resume(with: .failure(err))
                }
            })
        }
    }
    
    func getCode(url: URL) throws -> String {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let items = components?.queryItems {
            for item in items where item.name == "code" {
                guard let code = item.value else {
                    throw "Not found code in url: \(url)"
                }
                return code
            }
            throw "Not found code in url: \(url)"
        } else {
            throw "Not found code in url: \(url)"
        }
    }
    
    public enum AuthResult {
        case success(_ code: String)
        case error(_ error: Error)
    }
    
    func encodeBase64urlNoPadding(data: Data) -> String {
        var base64string = data.base64EncodedString()

        // converts base64 to base64url
        base64string = base64string.replacingOccurrences(of: "+", with: "-")
        base64string = base64string.replacingOccurrences(of: "/", with: "_")
        // strips padding
        base64string = base64string.replacingOccurrences(of: "=", with: "")
        return base64string
    }

    func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 += padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
    
    func randomURLSafeString(size: Int) -> String? {
        var data = Data(count: size)
        let result = data.withUnsafeMutableBytes { rawPointer -> Int32 in
            if let address = rawPointer.bindMemory(to: UInt8.self).baseAddress {
                return SecRandomCopyBytes(kSecRandomDefault, size, address)
            } else {
                return errSecMemoryError
            }
        }
        if result == errSecSuccess {
            return encodeBase64urlNoPadding(data: data)
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }

    func generateNonce() -> String? {
        return randomURLSafeString(size: 32)
    }
    
    func authSessionStart(handler: @escaping (AuthResult) -> Void) {
        callback = handler
        
        guard var urlComponents = URLComponents(string: AppSettings.settings.authServer + "/oauth2/authorize"), let nonce = generateNonce() else {
            handler(AuthResult.error("Can't create url components"))
            return
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: AppSettings.settings.clienID),
            URLQueryItem(name: "scope", value: "read_prefs write_api"),
            URLQueryItem(name: "nonce", value: nonce),
            URLQueryItem(name: "redirect_uri", value: redirectUrl),
            URLQueryItem(name: "response_type", value: "code")
        ]
        guard let url = urlComponents.url else {
            handler(AuthResult.error("Can't create url"))
            return
        }
        
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "https") { [weak self] url, err in
            self?.session = nil
            self?.resumeFlow(url: url, error: err)
        }
        session.presentationContextProvider = self
        
        self.session = session

        DispatchQueue.main.async {
            session.start()
        }
    }
    
    private func callbackOnce(_ result: AuthResult) {
        if let callback {
            self.callback = nil
            // ASWebAuth вызывает делегата на фоновом потоке
            DispatchQueue.main.async {
                callback(result)
            }
        }
    }
    
    // OpenStreetMap don't support custom schema in redirect url. So we have to use Universal Links to handle redirects. Universal Link is handled inside SceneDelegate and returned there
    func resumeFlow(url: URL?, error: Error?) {
        // Close auth session window
        if let session {
            session.cancel()
        }
        
        if let error {
            callbackOnce(AuthResult.error(error))
            return
        }
        guard let url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            callbackOnce(AuthResult.error("Can't find auth response"))
            return
        }
        
        var code: String?

        if let items = components.queryItems {
            for item in items where item.name == "code" {
                code = item.value
                break
            }
        }

        guard let code else {
            callbackOnce(AuthResult.error("Can't find token in auth response"))
            return
        }

        callbackOnce(AuthResult.success(code))
    }
    
    func getAccessToken(code: String) async throws -> String {
        guard let authURL = URL(string: AppSettings.settings.authServer + "/oauth2/token") else {
            throw "Can't generate auth URL to get access token. Code: \(code)"
        }
        
        let parameters: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectUrl,
            "client_secret": AppSettings.settings.clientSecret,
            "client_id": AppSettings.settings.clienID
        ]

        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.httpBody = parameters.percentEncoded()
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRespone = response as? HTTPURLResponse {
                if httpRespone.statusCode == 200 {
                    do {
                        let answer = try JSONDecoder().decode(AuthSuccess.self, from: data)
                        return answer.access_token
                    } catch {
                        throw "Error decoding response with access code: \(error)"
                    }
                } else {
                    guard let str = String(data: data, encoding: .utf8) else {
                        throw "Status code \(httpRespone.statusCode), error decoding response"
                    }
                    throw "Error get access token: status code \(httpRespone.statusCode) - \(str)"
                }
            } else {
                guard let str = String(data: data, encoding: .utf8) else {
                    throw "Unknown status code and answer while get access code"
                }
                throw str
            }
        } catch {
            throw "Error while get access token: \(error)"
        }
    }
    
    func downloadOSMData(longitudeDisplayMin: Double, latitudeDisplayMin: Double, longitudeDisplayMax: Double, latitudeDisplayMax: Double) async throws -> (Data) {
        guard let url = URL(string: "\(AppSettings.settings.server)/api/0.6/map?bbox=\(longitudeDisplayMin),\(latitudeDisplayMin),\(longitudeDisplayMax),\(latitudeDisplayMax)") else {
            throw "Error generate URL for download data. Server: \(AppSettings.settings.server), Bbox: \(longitudeDisplayMin),\(latitudeDisplayMin),\(longitudeDisplayMax),\(latitudeDisplayMax)"
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                return data
            } else {
                guard let str = String(data: data, encoding: .utf8) else {
                    throw "Unknown response from server. URL: \(url). Status code: \(httpResponse.statusCode)"
                }
                throw "Error getting data. Status code: \(httpResponse.statusCode), error: \(str)"
            }
        } else {
            guard let str = String(data: data, encoding: .utf8) else {
                throw "Unknown response from server. URL: \(url)"
            }
            throw str
        }
    }
    
    //  Method of sending changes to the server
    func sendObjects(sendObjs: [OSMAnyObject], deleteObjs: [OSMAnyObject]) async throws {
        try await checkAuth()
        if sendObjs.count == 0 && deleteObjs.count == 0 {
            throw "Point array is empty"
        }
        var changeset = osmChange(sendObjs: sendObjs, deleteObjs: deleteObjs)
        var changesetID = 0
        do {
            changesetID = try await openChangeset()
            changeset.setChangesetID(id: changesetID)
        } catch {
            throw "Error open changeset: \(error)"
        }
        try await sendChangeset(osmChange: changeset, changesetID: changesetID)
        AppSettings.settings.savedObjects.removeAll()
        await closeChangeset(changeSetID: changesetID)
    }
    
    //  open changeset
    func openChangeset() async throws -> Int {
        let comment = AppSettings.settings.changeSetComment ?? "The user has not entered a comment."
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "4"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let requestData = """
        <osm>
            <changeset>
                <tag k="created_by" v="OsmoTagger \(appVersion)(\(buildNumber))"/>
                <tag k="contact:telegram" v="https://t.me/OsmoTagger_chat"/>
                <tag k="comment" v="\(comment)"/>
            </changeset>
        </osm>
        """.data(using: .utf8)
        guard let url = URL(string: "\(AppSettings.settings.server)/api/0.6/changeset/create") else {
            throw "Error create url while open changeset"
        }
        var request = URLRequest(url: url)
        guard let token = AppSettings.settings.token else {
            throw "You are not logged in to osm.org"
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = requestData
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let str = String(data: data, encoding: .utf8) else {
                throw "Error decode data while open changeset"
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    guard let changesetID = Int(str) else {
                        throw "Changeset was open, but error decode data"
                    }
                    return changesetID
                } else {
                    throw "Status code request: \(httpResponse.statusCode), message: \(str)"
                }
            } else {
                throw str
            }
        } catch {
            throw "Error while open changeset: \(error)"
        }
    }
    
    //  Method of sending changeset
    func sendChangeset(osmChange: osmChange, changesetID: Int) async throws {
        var requestData: Data?
        do {
            requestData = try XMLEncoder().encode(osmChange)
        } catch {
            throw "Error encode changeset to send: \(error)"
        }
        guard let token = AppSettings.settings.token else {
            throw "You are not logged in to osm.org"
        }
        guard requestData == requestData else {
            throw "Request data was nil while encode changeset."
        }
        guard let url = URL(string: "\(AppSettings.settings.server)/api/0.6/changeset/\(changesetID)/upload") else {
            throw "Error create url while send changeset"
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = requestData
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    return
                default:
                    guard let str = String(data: data, encoding: .utf8) else {
                        throw "Request status code: \(httpResponse.statusCode), error decode data while send changeset."
                    }
                    throw "Status code: \(httpResponse.statusCode), error: \(str)"
                }
            } else {
                guard let message = String(data: data, encoding: .utf8) else {
                    throw "Changeset \(changesetID) was open and try send to server, but unknown response and answer"
                }
                throw message
            }
        } catch {
            throw "Changeset \(changesetID) was open, but error while send request  \(error)"
        }
    }
    
    //  Close changeset
    func closeChangeset(changeSetID: Int) async {
        guard let url = URL(string: "\(AppSettings.settings.server)/api/0.6/changeset/\(changeSetID)/close"),
              let token = AppSettings.settings.token else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: request)
    }
    
    //  Get user information
    func getUserInfo() async throws -> OSMUserInfo {
        guard let url = URL(string: "\(AppSettings.settings.server)/api/0.6/user/details.json"),
              let token = AppSettings.settings.token
        else {
            throw "Error create url while check auth"
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                let userInfo = try JSONDecoder().decode(OSMUserInfo.self, from: data)
                AppSettings.settings.userName = userInfo.user.display_name
                return userInfo
            default:
                guard let str = String(data: data, encoding: .utf8) else {
                    throw "Request status code: \(httpResponse.statusCode), error decode data while check auth."
                }
                throw "Status code: \(httpResponse.statusCode), error: \(str)"
            }
        } else {
            guard let message = String(data: data, encoding: .utf8) else {
                throw "Unknown response and answer from server"
            }
            throw message
        }
    }
    
    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=")
        return allowed
    }()
}
