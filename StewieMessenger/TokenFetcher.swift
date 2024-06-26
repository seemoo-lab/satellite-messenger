//
//  TokenFetcher.swift
//  StewieMessenger
//
//  Created by Alex - SEEMOO on 17.05.24.
//

import Foundation
import Accounts
import OSLog

class TokenFetcher {
    
    static let shared = TokenFetcher()
    
    var searchPartyToken: String?
    var appleId: String?
    
    
    private init() {
        // Load the accounts framework
        dlopen("/System/Library/PrivateFrameworks/AuthKit.framework/AuthKit", RTLD_NOW);
    }
    
    func getICloudAccount() throws -> ACAccount {
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountType(withAccountTypeIdentifier: "com.apple.account.AppleAccount")
        
        let appleAccounts = accountStore.accounts(with: accountType)
        
        os_log(.debug, "Fetching Apple account")
        
        guard let iCloudAccount = appleAccounts?.first as? ACAccount else {
            throw TokenFetcherError.appleAccountNotFound
        }
        return iCloudAccount
    }
    
    
    /// Fetch all available iCloud tokens for the current Apple Account
    /// - Throws: An error of the apple account cannot be accessed or found.
    /// - Returns: Dictionary of iCloud tokens linked to this accoutn
    func fetchiCloudTokens() throws -> [AnyHashable: Any] {
        let iCloudAccount = try self.getICloudAccount()
        
        guard let accountCredentials = iCloudAccount.credential else {
            os_log(.error, "Could not find Apple iCloud Account")
            throw TokenFetcherError.appleAccountNotFound
        }
        
        os_log(.debug, "Got iCloud Account, %{public}@", String(describing: iCloudAccount))
        
        guard accountCredentials.responds(to: Selector(("credentialItems")))
        else {
            os_log(.error, "Account credential items selector not available \n%{public}@",String(describing: accountCredentials))
            throw TokenFetcherError.appleAccountCredentialItemsSelectorNotAvailable
        }
        os_log(.debug, "Credential items available")
        
        let credentialItems = accountCredentials.perform(Selector(("credentialItems"))).takeUnretainedValue()
        
        os_log(.debug, "Got credential items, %{public}@", String(describing: credentialItems))
        
        guard let credentialItemsDict = credentialItems as? [AnyHashable: Any] else {
            os_log(.error, "Account could not get account credentials \n%{public}@",String(describing: accountCredentials))
            throw TokenFetcherError.appleAccountCredentialsNotFound
        }
        
        os_log(.debug, "Got credential items dict, %{public}@", String(describing: credentialItemsDict))
        
        return credentialItemsDict
    }
    
    func fetchSearchPartyToken() throws -> String {
        let tokens = try self.fetchiCloudTokens()
        guard let searchPartyToken = tokens["search-party-token"] as? String  else {
            throw TokenFetcherError.searchPartyTokenNotFound
        }
        self.searchPartyToken = searchPartyToken
        return searchPartyToken
    }
    
    func fetchAppleAccountId() throws -> String {
        let iCloudAccount = try getICloudAccount()
        let appleId = iCloudAccount.perform(Selector(("aa_personID"))).takeUnretainedValue()
        let appleIdString = "\(appleId)"
        self.appleId = appleIdString
        return appleIdString
    }
    
    enum TokenFetcherError: Error {
        case appleAccountNotFound
        case appleAccountCredentialItemsSelectorNotAvailable
        case appleAccountCredentialsNotFound
        case searchPartyTokenNotFound
    }

}


//- (NSString *)fetchAppleAccountId {
//    NSDictionary *query = @{
//        (NSString *)kSecClass : (NSString *)kSecClassGenericPassword,
//        (NSString *)kSecAttrService : @"iCloud",
//        (NSString *)kSecMatchLimit : (id)kSecMatchLimitOne,
//        (NSString *)kSecReturnAttributes : @true
//    };
//
//    CFTypeRef item;
//    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &item);
//
//    if (status == errSecSuccess) {
//        NSDictionary *itemDict = (__bridge NSDictionary *)(item);
//        CFRelease(item);
//        
//        NSString *accountId = itemDict[(NSString *)kSecAttrAccount];
//
//        return accountId;
//    }
//
//    return nil;
//}
