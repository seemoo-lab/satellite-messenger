//
//  ContentView.swift
//  StewieMessenger
//
//  Created by Alex - SEEMOO on 17.05.24.
//

import SwiftUI
import SwiftData
import OSLog

struct ContentView: View {

    @State var tokens: [AnyHashable: Any] = [:]
    @State var appleId: String? = nil
    @State var errorText: String? = nil
    @State var decryptedPlists: [String: Any] = [:]
    @State var msgSendError: String? = nil
    @State var msgSendStatus: String? = nil
    @State var messages: [Message] = []
    @ObservedObject var textBindingManager = TextBindingManager(limit: 81)

    @Environment(\.scenePhase) var scenePhase
    
    @ViewBuilder
    var body: some View {
        VStack {
            Text("Satellite Messenger").bold()
            
            Spacer()
            
            
            Text("Your messages will be shared \nwith all your Find My friends.")
                .multilineTextAlignment(.center)
            
            VStack {
                ScrollView (.vertical, showsIndicators: false) {
                    ForEach(0..<messages.count, id: \.self) {index in
                           MessageView(message: messages[index])
                        }
                    
                }
            }
            
            
            Group{
                
                HStack {
                    TextField(
                        "Message",
                        text: $textBindingManager.text
                    )
                    .padding(7)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        sendMsg()
                    }
                    .textInputAutocapitalization(.never)
                    .submitLabel(.send)
                    .disableAutocorrection(false)
                    
                    
                    Button {
                        sendMsg()
                    } label: {
                        // relatively scale send button using font size
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 20, weight: Font.Weight.bold))
                    }
                    .padding(7)
                    

                }
                
                if let msgSendError {
                    Text(msgSendError).foregroundStyle(.red)
                }
                
                if let msgSendStatus {
                    Text(msgSendStatus)
                }
                
                
                Button("Refresh Messages", systemImage: "arrow.triangle.2.circlepath") {
                    Task {
                        await self.update()
                    }
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .padding()
                
            }.frame(maxHeight: 50, alignment: .bottom)
        }
        .onAppear {
            Task {
                await update()
            }
        }
        .onChange(of: scenePhase) { scenePhase in 
            if scenePhase == .active {
                Task {
                    await update()
                }
            }
        }
        .alert(item: $errorText) { errorText in
            Alert(title: Text("Failed Receiving Messages"), message: Text("Error description: \(errorText)"), dismissButton: .default(Text("Okay")))
        }
    }
    
    func sendMsg() {
        let message = Message(withText: $textBindingManager.text.wrappedValue, directionReceive: false)
        let retval = MessageSender.shared.sendMessage(message: message)
        if (retval == MessageSenderError.success) {
            textBindingManager.text = ""
            msgSendError = nil
            messages.append(message)
        } else if (retval == MessageSenderError.noFileWrite) {
            msgSendError = "File permission error when sending message!"
            messages.append(message)
            return
        } else if (retval == MessageSenderError.nonAscii) {
            msgSendError = "Only use ASCII characters!"
            messages.append(message)
            return
        }
        
        // when we sent the message successfully:
        // poll for updates to show in UI
        DispatchQueue.global().async {
            
            DispatchQueue.main.async {
                var state: Int;
                
                while true {
                    state = MessageSender.shared.getState()
                    message.setStewieState(state: state)
                    
                    switch state {
                    case 5:
                        msgSendStatus = "Transmission in progress!"
                    case 1:
                        msgSendStatus = nil
                        msgSendError = "Transmission failed!"
                    case 6:
                        msgSendStatus = "Transmission successful."
                    case 10:
                        msgSendStatus = nil
                        msgSendError = "Stewie unavailable or throttled! Requires active SIM and Wi-Fi without connectivity."
                    default:
                        msgSendStatus = nil
                        msgSendError = nil
                    }
                    
                    // only keep refreshing if state is in progress
                    if (state != 5) {
                        return
                    }
                    usleep(1000000)
                }
            
            }
        }
    }
    
    func update() async  {
        do {
            _ = try TokenFetcher.shared.fetchSearchPartyToken()
            _ = try TokenFetcher.shared.fetchAppleAccountId()
            _ = try AppleFindMyController.shared.fetchFindMyFriends()
            let messages = try await AppleFindMyController.shared.updateMessages()
            await MainActor.run {
                for message in messages {
                    if !self.messages.contains(message) {
                        self.messages.append(message)
                    }
                }
                
            }
            self.errorText = nil
        }catch {
            self.errorText = String(describing: error)
        }
    }
}

#Preview {
    ContentView(messages: [
        Message(withText: "Hello World", directionReceive: true, sender: "Alex", timestamp: Date()),
        
        Message(withText: "Hello My Friend!", directionReceive: false, sender: nil, timestamp: Date(), stewieState: 6)
    ])
}


// https://stackoverflow.com/questions/56476007/how-to-set-textfield-max-length
class TextBindingManager: ObservableObject {
    @Published var text = "" {
        didSet {
            if text.count > characterLimit && oldValue.count <= characterLimit {
                text = oldValue
            }
        }
    }
    let characterLimit: Int

    init(limit: Int = 81){
        characterLimit = limit
    }
}

struct MessageView: View {
    var message: Message
    
    let df: DateFormatter = {
       let df = DateFormatter()
        df.timeStyle = .short
        df.dateStyle = .short
        return df
    }()
    
    var body: some View {
        VStack(alignment: message.direction ? .leading : .trailing, spacing: 0) {
            if let sender = message.sender {
                Text(sender)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                if !message.direction {
                    Spacer()
                }
                
                Text(message.getText())
                    .padding()
                    .background(message.getColor())
                    .clipShape(BubbleShape(myMessage: !message.isSendDirection()))
                    .foregroundColor(.white)
                
                if message.direction {
                    Spacer()
                }
                
            }
            .padding(.leading, 0)
            .padding([.top, .bottom], 6)
            
            Text(df.string(from: message.timestamp))
                .foregroundStyle(.secondary)
            
            
        }.padding(.horizontal)
    }
}

// https://gist.github.com/navsing/21373a82146747e06eef87b5645d8663
struct BubbleShape: Shape {
    var myMessage : Bool
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        let bezierPath = UIBezierPath()
        if !myMessage {
            bezierPath.move(to: CGPoint(x: 20, y: height))
            bezierPath.addLine(to: CGPoint(x: width - 15, y: height))
            bezierPath.addCurve(to: CGPoint(x: width, y: height - 15), controlPoint1: CGPoint(x: width - 8, y: height), controlPoint2: CGPoint(x: width, y: height - 8))
            bezierPath.addLine(to: CGPoint(x: width, y: 15))
            bezierPath.addCurve(to: CGPoint(x: width - 15, y: 0), controlPoint1: CGPoint(x: width, y: 8), controlPoint2: CGPoint(x: width - 8, y: 0))
            bezierPath.addLine(to: CGPoint(x: 20, y: 0))
            bezierPath.addCurve(to: CGPoint(x: 5, y: 15), controlPoint1: CGPoint(x: 12, y: 0), controlPoint2: CGPoint(x: 5, y: 8))
            bezierPath.addLine(to: CGPoint(x: 5, y: height - 10))
            bezierPath.addCurve(to: CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: 5, y: height - 1), controlPoint2: CGPoint(x: 0, y: height))
            bezierPath.addLine(to: CGPoint(x: -1, y: height))
            bezierPath.addCurve(to: CGPoint(x: 12, y: height - 4), controlPoint1: CGPoint(x: 4, y: height + 1), controlPoint2: CGPoint(x: 8, y: height - 1))
            bezierPath.addCurve(to: CGPoint(x: 20, y: height), controlPoint1: CGPoint(x: 15, y: height), controlPoint2: CGPoint(x: 20, y: height))
        } else {
            bezierPath.move(to: CGPoint(x: width - 20, y: height))
            bezierPath.addLine(to: CGPoint(x: 15, y: height))
            bezierPath.addCurve(to: CGPoint(x: 0, y: height - 15), controlPoint1: CGPoint(x: 8, y: height), controlPoint2: CGPoint(x: 0, y: height - 8))
            bezierPath.addLine(to: CGPoint(x: 0, y: 15))
            bezierPath.addCurve(to: CGPoint(x: 15, y: 0), controlPoint1: CGPoint(x: 0, y: 8), controlPoint2: CGPoint(x: 8, y: 0))
            bezierPath.addLine(to: CGPoint(x: width - 20, y: 0))
            bezierPath.addCurve(to: CGPoint(x: width - 5, y: 15), controlPoint1: CGPoint(x: width - 12, y: 0), controlPoint2: CGPoint(x: width - 5, y: 8))
            bezierPath.addLine(to: CGPoint(x: width - 5, y: height - 12))
            bezierPath.addCurve(to: CGPoint(x: width, y: height), controlPoint1: CGPoint(x: width - 5, y: height - 1), controlPoint2: CGPoint(x: width, y: height))
            bezierPath.addLine(to: CGPoint(x: width + 1, y: height))
            bezierPath.addCurve(to: CGPoint(x: width - 12, y: height - 4), controlPoint1: CGPoint(x: width - 4, y: height + 1), controlPoint2: CGPoint(x: width - 8, y: height - 1))
            bezierPath.addCurve(to: CGPoint(x: width - 20, y: height), controlPoint1: CGPoint(x: width - 15, y: height), controlPoint2: CGPoint(x: width - 20, y: height))
        }
        return Path(bezierPath.cgPath)
    }
}

extension String: Identifiable {
    public var id: Int {
        return self.hashValue
    }
}
