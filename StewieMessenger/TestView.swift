//
//  TestView.swift
//  StewieMessenger
//
//  Created by Alex - SEEMOO on 04.06.24.
//

import SwiftUI

struct TestView: View {

    @State var searchPartyToken: String? = nil
    @State var friends: [FindMyFriendsInfo]? = nil
    @State var appleId: String? = nil
    
    @State var errorText: String? = nil
    
    @State var locationMessages: [String] = []
    
    var body: some View {
        VStack {
            Button("Update") {
                update()
            }
            .buttonStyle(BorderedProminentButtonStyle())
            
            Button("Fetch Location") {
                fetchLocation()
            }
            .buttonStyle(BorderedProminentButtonStyle())
            
            if let errorText {
                Text(errorText)
            }
            
            ScrollView {
                VStack(alignment: .leading) {
                    if let searchPartyToken {
                        Text("Search Party Token")
                        Text(searchPartyToken)
                    }
                    
                    if let appleId {
                        Text("Apple ID")
                        Text(appleId)
                    }
                    
                    if let friends {
                        Text("Friends")
                        ForEach(friends, id: \.findMyId) { friend in
                            VStack(alignment:.leading) {
                                Text(friend.appleId)
                                Text(friend.findMyId)
                                Text(friend.locationIds.description)
                            }
                        }
                    }
                    
                    if locationMessages.count > 0 {
                        ForEach(locationMessages, id: \.self) { message in
                            Text(message)
                        }
                    }
                }
            }
        }
        .onAppear {
            update()
        }
    }
    
    func update() {
        do {
            self.searchPartyToken = try TokenFetcher.shared.fetchSearchPartyToken()
            self.appleId = try TokenFetcher.shared.fetchAppleAccountId()
            self.friends = try AppleFindMyController.shared.fetchFindMyFriends()
            self.errorText = nil
        }catch {
            self.errorText = String(describing: error)
        }
    }
    
    func fetchLocation() {
        self.locationMessages = []
        Task {
            guard let friends = self.friends,
            let token = self.searchPartyToken,
            let appleId else {
                return
            }
            
            for friend in friends {
                do {
                    let location = try await AppleFindMyController.shared.fetchLocationUpdate(for: friend.findMyId, secureLocationIds: friend.locationIds, searchpartyToken: token, appleId: appleId)
                    
                    for payload in location.locationPayload {
                        for locationInfo in payload.locationInfo {
                            if locationInfo.fmt == 1 {
                                // Satellite location.
                                await MainActor.run {
                                    if let messageContent = Data(base64Encoded: locationInfo.location),
                                       let message = String(data: messageContent, encoding: .utf8) {
                                        self.locationMessages.append("\(friend.appleId):\n\(message)")
                                    }
                                }
                            }
                        }
                    }
                    
                }catch {
                    self.errorText = error.localizedDescription
                }
            }

        }
        
    }
}

#Preview {
    TestView()
}
