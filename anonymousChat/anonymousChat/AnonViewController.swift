//
//  AnonTableViewController.swift
//  anonymousChat
//
//  Created by user on 1/30/18.
//  Copyright © 2018 user. All rights reserved.
//

import UIKit
import CoreData
import QuartzCore
import MultipeerConnectivity

class AnonViewController: UIViewController {
    
    var peerID: MCPeerID!
    var mySession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var personalHandle = ""
    var messageArr = [Message]()
    
    @IBOutlet var postButton: UIButton!
    @IBOutlet var messageField: UITextField!
    @IBOutlet var messageTableView: UITableView!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var logo: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Lets image be clicked
        enableImageInteraction()
        
        setupConnection()
        
        messageTableView.delegate = self
        messageTableView.dataSource = self
        fetchAndReload()
        
        postButton.layer.cornerRadius = 5
        messageTableView.layer.borderColor = UIColor.lightGray.cgColor
        messageTableView.layer.backgroundColor = #colorLiteral(red: 0.9214683175, green: 0.9216262698, blue: 0.9214583635, alpha: 1)
        messageTableView.layer.cornerRadius = 10
    }
    
    @IBAction func logoIsTapped(_ sender: UITapGestureRecognizer) {
        
        print("logo tapped")
        if setupConnection() {
            let actionsheet = UIAlertController(title: "Messages Exchange", message: "Do you want to Host or Join a session?", preferredStyle: .actionSheet)
            
            actionsheet.addAction(UIAlertAction(title: "Host Session", style: .default, handler: { (action: UIAlertAction) in
                self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "an-do", discoveryInfo: nil, session: self.mySession)
                self.mcAdvertiserAssistant.start()
            }))
            
            actionsheet.addAction(UIAlertAction(title: "Join Session", style: .default, handler: { (action: UIAlertAction) in
                let mcBrowser = MCBrowserViewController(serviceType: "an-do", session: self.mySession)
                mcBrowser.delegate = self
                self.present(mcBrowser, animated: true, completion: nil)
            }))
            
            actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(actionsheet, animated: true, completion: nil)
        }
        else {
            return
        }
    }
    
    @IBAction func submitDoubleTapped(_ sender: UIButton) {
        //Switches the submit back to a Handle
        print("double tapped")
        messageField.placeholder = "Enter a new Handle"
        postButton.setTitle("Handle", for: .normal)
    }
    
    @IBAction func userPressedEnter(_ sender: UITextField) {
        if postButton.titleLabel?.text == "Handle" {
            if messageField.text != "" {
                personalHandle = messageField.text!
                postButton.setTitle("Post", for: .normal)
                messageField.text? = ""
                messageField.placeholder = "What do you wanna say?"
            }
            else {
                return
            }
        }
        else if postButton.titleLabel?.text == "Post" {
            //Create a new Message
            print("posting...")
            if messageField.text != "" {
                print("about to save")
                let newMessage = Message(context: managedObjectContext)
                newMessage.content = messageField.text!
                newMessage.username = personalHandle
                let date = Date()
                newMessage.date = date
                saveContext()
                fetchAndReload()
                messageField.text = ""
                sendData(newMessage: newMessage)
            }
            else {
                return
            }
        }
        messageField.resignFirstResponder()
    }
    
    @IBAction func submitButtonPressed(_ sender: UIButton) {
        if sender.titleLabel?.text == "Handle" {
            if messageField.text != "" {
                personalHandle = messageField.text!
                postButton.setTitle("Post", for: .normal)
                messageField.text? = ""
                messageField.placeholder = "What do you wanna say?"
            }
            else {
                return
            }
        }
        else if sender.titleLabel?.text == "Post" {
            //Create a new Message
            print("posting...")
            if messageField.text != "" {
                print("about to save")
                let newMessage = Message(context: managedObjectContext)
                newMessage.content = messageField.text!
                newMessage.username = personalHandle
                let date = Date()
                newMessage.date = date
                saveContext()
                sendData(newMessage: newMessage)
                fetchAndReload()
                messageField.text = ""
            }
            else {
                return
            }
        }
        messageField.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func enableImageInteraction() {
        logo.isUserInteractionEnabled = true
    }
}

// MARK: Core Data Functions

extension AnonViewController {
    
    func saveContext(){
        print("About to save...")
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                print("failed in saveContext", error)
            }
        }
    }
    
    func fetchAndReload() {
        print("About to fetch...")
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let sortDescriptors = [sortDescriptor]
        request.sortDescriptors = sortDescriptors
        do {
            let response = try managedObjectContext.fetch(request)
            print("fetch successful")
            messageArr = response
            
        } catch {
            print("failed in fetch", error)
        }
        messageTableView.reloadData()
    }
}

// MARK: - Table view data source

extension AnonViewController: UITableViewDelegate {
    
}

extension AnonViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = messageTableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        cell.backgroundColor = #colorLiteral(red: 0.9214683175, green: 0.9216262698, blue: 0.9214583635, alpha: 1)
        cell.messageLabel.text = messageArr[indexPath.row].content
        let date = messageArr[indexPath.row].date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy h:mm a"
        dateFormatter.date
        cell.dateLabel.text = dateFormatter.string(from: date!)
        cell.nameLabel.text = messageArr[indexPath.row].username
        tableView.rowHeight = 72
        return cell
    }
}

// MARK: Multipeer Connectivity Functions

extension AnonViewController: MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    func sendData(newMessage: Message) {
        if mySession.connectedPeers.count > 0 {
            
            var sendArray = [Message]()
            sendArray.append(newMessage)
            do {
                let myData = try
                    JSONSerialization.data(withJSONObject: sendArray, options: .prettyPrinted)
                do {
                    try mySession.send(myData, toPeers: mySession.connectedPeers, with: .reliable)
                    } catch {
                    print("failed to send data", error)
                }
            } catch {
                print("failed to convert to Data")
            }
        }
    }
    
    func setupConnection() -> Bool {
        if personalHandle != "" {
            self.peerID = MCPeerID(displayName: self.personalHandle)
            mySession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
            mySession.delegate = self
            return true
        }
        return false
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        do {
            let receivedMessage = try JSONDecoder().decode([Message].self, from: data)
            var message = Message(context: managedObjectContext)
            message = receivedMessage[0]
            saveContext()
            
            DispatchQueue.main.async {
                self.fetchAndReload()
            }
        } catch {
            print("failed to decode", error)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
}

