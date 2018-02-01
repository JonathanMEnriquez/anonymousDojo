import Foundation
import MultipeerConnectivity

class AnonServiceManager : NSObject {
    
    var delegate: AnonServiceManagerDelegate?
    private let AnonServiceType = "an-do"
    private var myPeerID = MCPeerID(displayName: "temp\(arc4random_uniform(10000))")
//    private var myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: AnonServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: AnonServiceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    func setDisplayName(newDisplayName: String) {
        myPeerID = MCPeerID(displayName: newDisplayName)
    }
    
    func send(newMessage: NSDictionary) {
        print("sendMessage: \(newMessage.allValues) to \(session.connectedPeers.count) peers")
        
        if session.connectedPeers.count > 0 {
            
            do {
                let jsonStr = try JSONSerialization.data(withJSONObject: newMessage, options: .prettyPrinted)
                do{
                    try self.session.send(jsonStr, toPeers: session.connectedPeers, with: .reliable)
                } catch {
                    print("Error for sending: \(error)")
                }
            } catch {
                print("error converting", error)
            }
        }
    }
}

extension AnonServiceManager : MCNearbyServiceAdvertiserDelegate
{
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
}

extension AnonServiceManager : MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer: \(peerID)")
        print("invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lostPeer: \(peerID)")
    }
    
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("didNotStartBrowsingForPeers: \(error)")
    }
}

extension AnonServiceManager : MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state)")
        
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("didReceiveData: \(data)")
        do {
            print("inside the doooo")
            let receivedDict = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! NSDictionary
            self.delegate?.newMessageReceived(manager: self, messageDictionary: receivedDict)
        } catch {
            print("failed to decode json", error)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("didFinishReceivingResourceWithName")
    }
}
