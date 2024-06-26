//
//  AppleFindMyController.swift
//  StewieMessenger
//
//  Created by Alex - SEEMOO on 17.05.24.
//

import Foundation
import Security
import OSLog
import CryptoKit

class AppleFindMyController {
    static let shared = AppleFindMyController()
    
    var findMyFriends = [FindMyFriendsInfo]()
    
    private init() {
        
    }
    
    // First we would have to fetch the friends from which the user can receive a location
    // This can be done accessing the files and decrypt them
    // These files are stored in a secure directory, so we need to be unsandboxed, but we are also required to access the keychain category for apple
    
    // Keychain group:
    //    <?xml version="1.0" encoding="UTF-8"?>
    //    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    //    <plist version="1.0">
    //    <array>
    //        <string>apple</string>
    //    </array>
    //    </plist>
    
    // Disabling sandboxing
    //    <key>platform-application</key>
    //    <true/>
    
    
    /// This function fetches all friends which are sharing a location with the user by accessing the according find my files
    func fetchFindMyFriends() throws -> [FindMyFriendsInfo] {
        os_log(.debug, "Fetching beacon store key")
        let beaconStoreKey = try fetchBeaconStoreKey()
        os_log(.debug, "Fetched key. Decrypting plists")
        let decryptedFiles = traverseDirectoriesForRecords(key: beaconStoreKey)
        
        var friends = [FindMyFriendsInfo]()
        for (fileName, decryptedPlist) in decryptedFiles {
            if let friendsInfo = self.getFindMyFriendsInfo(from: decryptedPlist) {
                friends.append(friendsInfo)
            }
        }
        self.findMyFriends = friends
        return friends
    }
    
    
    /// Fetch the Beacon Store Key which is used to encrypt plist files with private data on the system.
    /// - Returns: The key data
    func fetchBeaconStoreKey() throws -> Data {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "BeaconStore",
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnAttributes: true,
            kSecReturnData: true
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
            let entry = result as? [CFString: Any]
        else {
            os_log(.error, "Could not fetch key from keychain %{public}d", status)
            throw KeychainError.keyNotFound(errorCode: Int(status))
        }

        os_log("Entry found for Beacon Store: \n%@", String(describing: entry))
        guard let service = entry[kSecAttrService] as? String,
            service == "BeaconStore"
        else {
            throw KeychainError.keyNotAvailableInEntry
        }

        // Prior to iOS 17.5 the Beacon Store Key was stored in the `gena` file
        // This was a vuln that apple has fixed. Need to check where it is stored now if we want to support later OS versions
        
        /// Get the `gena` entry
        if let gena = entry["gena" as CFString] as? Data {
            return gena
        }
        
        if let valueData = entry[kSecValueData] as? Data {
            return valueData
        }
        
        throw KeychainError.keyNotAvailableInEntry

        return Data()
    }
    
    enum KeychainError: Error {
        case keyNotFound(errorCode: Int)
        case keyNotAvailableInEntry
    }
    
    
    //MARK: - File Decryption
    
    
    func traverseDirectoriesForRecords(key: Data) -> [String: [String: Any]] {
        let folderPath = URL(fileURLWithPath: "/var/mobile/Library/com.apple.icloud.searchpartyd/SecureLocationSharedKeys")
        
        guard let enumerator = FileManager.default.enumerator(at: folderPath, includingPropertiesForKeys: []) else {
            return [:]
        }
        
        var decryptedPlists = [String: [String: Any]]()
        
        for pathNameValue in enumerator {
            guard let pathnameURL = pathNameValue as? URL else {continue}
            if pathnameURL.pathExtension.contains("record") {
                // Found a record that we can decrypt
                do {
                    let recordURL = pathnameURL
                    guard let plist = try decryptRecord(at: recordURL, with: key) as? [String: Any] else{
                        throw FindMyFilesError.plistDecodingFailed
                    }
                    //Log contents of the plist
                    os_log("Decrypted plist at %@", String(describing: recordURL))
                    os_log("Contents:\n%@", String(describing: plist))
                    
                    let pathComponents = recordURL.pathComponents
                    let plistName = "\(pathComponents[pathComponents.count-2])/\(pathComponents.last!)"
                    decryptedPlists[plistName] = plist
                    
                }catch {
                    os_log("Failed decrypting record %@", pathnameURL.absoluteString)
                }
            }
        }
        
        return decryptedPlists
    }
    
    func decryptRecord(at url: URL, with key: Data) throws -> Any {
        let recordData = try Data(contentsOf: url)
        let recordPlist = try PropertyListSerialization.propertyList(
            from: recordData,
            format: nil
        ) as! [Data]
        
        let (nonce, tag, cipher) = (recordPlist[0], recordPlist[1], recordPlist[2])
        
        let key = SymmetricKey(data: key)
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonce),
            ciphertext: cipher,
            tag: tag
        )
        let decryptedPlistData = try AES.GCM.open(sealedBox, using: key)
        let plist = try PropertyListSerialization.propertyList(from: decryptedPlistData, format: nil)
        return plist
    }
    
    func getFindMyFriendsInfo(from plist: [String: Any]) -> FindMyFriendsInfo? {
        guard let locationDecryptionKey = plist["locationDecryptionKey"] as? [String: Any],
              let key = locationDecryptionKey["key"] as? [String: Any],
              let keyData = key["data"] as? Data else {
            return nil
        }
        
        guard let ownerHandle = plist["ownerHandle"] as? [String: Any],
              let destination = ownerHandle["destination"] as? String else {
            return nil
        }
        var appleId = String(destination.split(separator: "/").last ?? "No Apple ID")
        appleId = appleId.replacingOccurrences(of: "mailto:", with: "")
        appleId = appleId.replacingOccurrences(of: "tel:", with: "")
        
        guard let advertisedLocationId = plist["advertisedLocationId"] as? [String: Any],
              let locationIdKey = advertisedLocationId["key"] as? [String: Any],
              let locationIdData = locationIdKey["data"] as? Data else {
            return nil
        }
        
        let locationId = locationIdData.base64EncodedString()
        
        guard let findMydId = plist["findMyId"] as? String else {
            return nil
        }
        
        return FindMyFriendsInfo(findMyId: findMydId, locationIds: [locationId], decryptionKeys: [keyData], appleId: appleId)
    }
 
    
    
    
    enum FindMyFilesError: Error {
        case plistDecodingFailed
        case decryptionFailed
    }
    
    
    func fetchLocationUpdate(for findMyId: String, secureLocationIds: [String], searchpartyToken: String, appleId: String) async throws -> FindMyLocationResponseBody {
        var request = URLRequest(url: URL(string: "https://gateway.icloud.com/findmyservice/fetch")!)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let basicAuthRaw = "\(appleId):\(searchpartyToken)"
        let basicAuthData = basicAuthRaw.data(using: .utf8)!
        let basicAuth = "Basic \(basicAuthData.base64EncodedString())"
        request.addValue(basicAuth, forHTTPHeaderField: "Authorization")
        
        request.addValue("1", forHTTPHeaderField: "Accept-Version")
        request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("de-DE,de;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.addValue("searchpartyd/1.0 CFNetwork/1410.0.3 Darwin/22.6.0", forHTTPHeaderField: "User-Agent")
        request.addValue("keep-alive", forHTTPHeaderField: "Connection")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = FetchLocationRequestBody(fetch: [.init(fmId: findMyId, intent: "startLocationUpdates", mode: "shallow", ids: secureLocationIds)], clientContext: .init(apsToken: "5F42A10481E758BC26A08938E11A8C2C24AF68B886815CE0875718D1B33A0C2F", clientId: "667e79292ec056e82593b3c69b1e48ee4ba86c3d"))
        let bodyData = try! JSONEncoder().encode(body)
        
        request.addValue("\(bodyData.count)", forHTTPHeaderField: "Content-Length")
        request.httpBody = bodyData
        request.httpMethod = "POST"
        
        
        let headers = try getAnisetteHeaders(for: request)
        for (headerField, value) in headers {
            request.addValue(value, forHTTPHeaderField: headerField)
        }
        
        request.addValue("<iPhone10,4> <iPhone OS;16.6;20G75> <com.apple.AuthKit/1 (com.apple.icloud.searchpartyd/1.0)>", forHTTPHeaderField: "X-MME-CLIENT-INFO")
        
        os_log(.debug, "Created request for fetching location %@", request.debugDescription)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        os_log(.debug, "Received response for location\nResponse:\n%@\n\nBody:\n%@", response.debugDescription, String(data: data, encoding: .utf8) ?? "Decoding failed")
        
        if data.count > 0 {
            let respondeBody = try JSONDecoder().decode(FindMyLocationResponseBody.self, from: data)
            return respondeBody
        }
           
        throw LocationFetchError.didNotGetLocation
    }
    
    func getAnisetteHeaders(for request:URLRequest) throws -> [String: String]  {
        let appleIdSession = NSClassFromString("AKAppleIDSession")?.alloc().perform(Selector(("initWithIdentifier:")), with: "com.apple.icloud.searchpartyd").takeUnretainedValue()
        guard let headers = appleIdSession?.perform(Selector(("appleIDHeadersForRequest:")), with: request).takeUnretainedValue() as? [String: String] else {
            throw AnisetteError.couldNotGetAnisetteHeaders
        }
        
        return headers
    }
    
    
    func updateMessages() async throws -> [Message] {
        let friends = self.findMyFriends
        guard friends.count > 0,
              let token = TokenFetcher.shared.searchPartyToken,
              let appleId = TokenFetcher.shared.appleId else {
            throw LocationFetchError.tokensNotAvailable
        }
        
        var messages = [Message]()
        
        for friend in friends {
            do {
                let location = try await AppleFindMyController.shared.fetchLocationUpdate(for: friend.findMyId, secureLocationIds: friend.locationIds, searchpartyToken: token, appleId: appleId)
                
                for payload in location.locationPayload {
                    for locationInfo in payload.locationInfo {
                        if locationInfo.fmt == 1 {
                            // Satellite location.
                            
                            if let messageContent = Data(base64Encoded: locationInfo.location),
                               let messageText = String(data: messageContent, encoding: .utf8) {
                                
                                let timestamp = Date(timeIntervalSince1970: TimeInterval(locationInfo.locationTs/1000))
                                
                                let message = Message(withText: messageText, directionReceive: true, sender: friend.appleId, timestamp: timestamp)
                                messages.append(message)
                            }
                            
                            
                        }
                    }
                }
                
            }catch {
                
            }
        }
        return messages
    }
    
    enum AnisetteError: Error {
        case couldNotGetAnisetteHeaders
    }
    
    enum LocationFetchError: Error {
        case didNotGetLocation
        case tokensNotAvailable
    }
}

struct FetchLocationRequestBody: Codable {
    let fetch: [FetchLocation]
    let clientContext: ClientContext
    
    struct FetchLocation: Codable {
        let fmId: String
        let intent: String
        let mode: String
        let ids: [String]
    }
    
    struct ClientContext: Codable {
        let apsToken: String
        let clientId: String
        var contextApp: String = "com.apple.findmy.fmfcore" // ""
        var shallowStats: ShallowStats = ShallowStats()
        
        struct ShallowStats: Codable {
            
        }
    }
    
}


struct FindMyFriendsInfo: Codable {
    let findMyId: String
    let locationIds: [String]
    let decryptionKeys: [Data]
    let appleId: String
}

struct FindMyLocationResponseBody: Codable {
    let locationPayload: [LocationPayload]
    let configVersion: Int
    let statusCode: String
    
    struct LocationPayload: Codable {
        let locationInfo: [LocationInfo]
        let id: String
        
        struct LocationInfo: Codable {
            let locationTs: Int
            let location: String
            let fmt: Int
        }
        
    }
}
