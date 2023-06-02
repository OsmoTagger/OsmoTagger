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

//  Class for working with the OSM API.  Later it is necessary to get rid of singleton
class OsmClient: NSObject, ASWebAuthenticationPresentationContextProviding {
    let session = URLSession.shared
    
//    MARK: OAuth 2.0
    
    //  The authorization verification method, and in case of its absence, the authorization is launched
    func checkAuth() async throws {
        if AppSettings.settings.token == nil {
            let url = try await authSessionStartAsync()
            let code = try getCode(url: url)
            let token = try await getAccessToken(code: code)
            AppSettings.settings.token = token
        }
    }
    
    //  The method starts ASWebAuthenticationSession in async
    func authSessionStartAsync() async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            authSessionStart(handler: { result in
                if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(with: .failure("Error get callback URL"))
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
    
    func authSessionStart(handler: @escaping (URL?) -> Void) {
        guard let authURL = URL(string: "\(AppSettings.settings.authServer)/oauth2/authorize?client_id=\(AppSettings.settings.clienID)&redirect_uri=openstreeteditor:/&response_type=code&scope=read_prefs%20write_api") else {
            handler(nil)
            return
        }
        let scheme = "openstreeteditor"
        let authSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: scheme) { callbackURL, error in
            if error != nil {
                handler(nil)
            } else if let callbackURL = callbackURL {
                handler(callbackURL)
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            authSession.presentationContextProvider = self
            authSession.start()
        }
    }

    @Sendable func getAccessToken(code: String) async throws -> String {
        guard let url = URL(string: "\(AppSettings.settings.authServer)/oauth2/token") else {
            throw "Error generate auth URL for get access token. Code: \(code)"
        }
        let stringBody = "grant_type=authorization_code&code=\(code)&redirect_uri=openstreeteditor:/&client_secret=\(AppSettings.settings.clientSecret)&client_id=\(AppSettings.settings.clienID)"
        let dataBody = stringBody.data(using: .utf8)
        var request = URLRequest(url: url)
        request.httpBody = dataBody
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        do {
            let (data, response) = try await session.data(for: request)
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
    
    //  The method of downloading data from the server. The latest bbox parameters are saved to update the data
    var lastLongitudeDisplayMin: Double?
    var lastLatitudeDisplayMin: Double?
    var lasltLongitudeDisplayMax: Double?
    var lastLatitudeDisplayMax: Double?
    func downloadOSMData(longitudeDisplayMin: Double, latitudeDisplayMin: Double, longitudeDisplayMax: Double, latitudeDisplayMax: Double) async throws -> (Data) {
        guard let url = URL(string: "\(AppSettings.settings.server)/api/0.6/map?bbox=\(longitudeDisplayMin),\(latitudeDisplayMin),\(longitudeDisplayMax),\(latitudeDisplayMax)") else {
            throw "Error generate URL for download data. Server: \(AppSettings.settings.server), Bbox: \(longitudeDisplayMin),\(latitudeDisplayMin),\(longitudeDisplayMax),\(latitudeDisplayMax)"
        }
        let (data, response) = try await session.data(from: url)
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                lastLongitudeDisplayMin = longitudeDisplayMin
                lastLatitudeDisplayMin = latitudeDisplayMin
                lasltLongitudeDisplayMax = longitudeDisplayMax
                lastLatitudeDisplayMax = latitudeDisplayMax
                return data
            } else if httpResponse.statusCode == 400 || httpResponse.statusCode == 509 {
                throw OsmClientErrors.objectLimit
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
        var delete = Delete(node: [], way: [])
        for object in deleteObjs {
            switch object.type {
            case .node:
                guard let node = object.getNode() else { continue }
                delete.node.append(node)
            case .way, .closedway:
                let way = object.getWay()
                delete.way.append(way)
            default:
                continue
            }
        }
        var changeset = osmChange(version: "0.6", generator: "osm editor", modify: Modify(node: [], way: []), create: Create(node: [], way: []), delete: delete)
        for object in sendObjs {
            if object.id < 0 {
                switch object.type {
                case .node:
                    guard let node = object.getNode() else { continue }
                    changeset.create.node.append(node)
                case .way, .closedway:
                    let way = object.getWay()
                    changeset.create.way.append(way)
                default:
                    continue
                }
            } else {
                switch object.type {
                case .node:
                    guard let node = object.getNode() else { continue }
                    changeset.modify.node.append(node)
                case .way, .closedway:
                    let way = object.getWay()
                    changeset.modify.way.append(way)
                default:
                    continue
                }
            }
        }
        var changesetID = 0
        do {
            changesetID = try await openChangeset()
            if changeset.create.node.count != 0 {
                for i in 0 ... changeset.create.node.count - 1 {
                    changeset.create.node[i].changeset = changesetID
                }
            }
            if changeset.create.way.count != 0 {
                for i in 0 ... changeset.create.way.count - 1 {
                    changeset.create.way[i].changeset = changesetID
                }
            }
            if changeset.modify.node.count != 0 {
                for i in 0 ... changeset.modify.node.count - 1 {
                    changeset.modify.node[i].changeset = changesetID
                }
            }
            if changeset.modify.way.count != 0 {
                for i in 0 ... changeset.modify.way.count - 1 {
                    changeset.modify.way[i].changeset = changesetID
                }
            }
            if changeset.delete.node.count != 0 {
                for i in 0 ... changeset.delete.node.count - 1 {
                    changeset.delete.node[i].changeset = changesetID
                }
            }
            if changeset.delete.way.count != 0 {
                for i in 0 ... changeset.delete.way.count - 1 {
                    changeset.delete.way[i].changeset = changesetID
                }
            }
        } catch {
            throw "Error open changeset: \(error)"
        }
        try await sendChangeset(osmChange: changeset, changesetID: changesetID)
        removeObjectsFromSaved(objects: sendObjs)
        await closeChangeset(changeSetID: changesetID)
    }
    
    func removeObjectsFromSaved(objects: [OSMAnyObject]) {
        for object in objects {
            AppSettings.settings.savedObjects.removeValue(forKey: object.id)
        }
    }
    
    //  open changeset
    func openChangeset() async throws -> Int {
        let comment = AppSettings.settings.changeSetComment ?? "The user has not entered a comment."
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "4"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let requestData = """
        <osm>
            <changeset>
                <tag k="created_by" v="OpenStreetEditor \(appVersion)(\(buildNumber))"/>
                <tag k="contact:telegram" v="https://t.me/OpenStreetEditor"/>
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
            let (data, response) = try await session.data(for: request)
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
            let (data, response) = try await session.data(for: request)
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
        _ = try? await session.data(for: request)
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
        let (data, response) = try await session.data(for: request)
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
