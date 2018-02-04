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
    
    var serviceManager = AnonServiceManager()
    
    var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var personalHandle = ""
    var messageArr = [Message]()
    var connectedPeers = [String]()
    var viewIsMovedUp = false
    
    @IBOutlet var postButton: UIButton!
    @IBOutlet var messageField: UITextField!
    @IBOutlet var messageTableView: UITableView!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var logo: UIImageView!
    @IBOutlet var logoTapGesture: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: https://medium.com/the-traveled-ios-developers-guide/devicecheck-6f3eafac60e5
        // TODO: find ways to allow users to mute nearby users using the UUID, maybe filter messages coming in?
        print(UIDevice.current.identifierForVendor!)
    
        serviceManager.delegate = self
        
        //Lets image be clicked
        enableImageInteraction()
        
        messageTableView.delegate = self
        messageTableView.dataSource = self
        fetchAndReload()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardPresented), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDisappeared), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // TODO: Add observers for change in orientation
        
        postButton.layer.cornerRadius = 5
        messageTableView.layer.borderColor = UIColor.lightGray.cgColor
        messageTableView.layer.backgroundColor = #colorLiteral(red: 0.9214683175, green: 0.9216262698, blue: 0.9214583635, alpha: 1)
        messageTableView.layer.cornerRadius = 10
    }
    
    override func viewDidAppear(_ animated: Bool) {
        messageTableView.reloadData()
    }
    
    @objc func keyboardPresented(notification: Notification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        UIView.animate(withDuration: 0.1, animations: {
            self.view.frame = CGRect(x:self.view.frame.origin.x, y:self.view.frame.origin.y - keyboardFrame.height, width:self.view.frame.size.width, height:self.view.frame.size.height);
        })
    }
    
    @objc func keyboardDisappeared(notification: Notification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        UIView.animate(withDuration: 0.1, animations: {
            self.view.frame = CGRect(x:self.view.frame.origin.x, y:self.view.frame.origin.y + keyboardFrame.height, width:self.view.frame.size.width, height:self.view.frame.size.height);
                    })
    }
    
    @IBAction func userClickedTextField(_ sender: UITextField) {
//        if viewIsMovedUp == false {
//            UIView.animate(withDuration: 0.475, animations: {
//                self.view.frame = CGRect(x:self.view.frame.origin.x, y:self.view.frame.origin.y - 250, width:self.view.frame.size.width, height:self.view.frame.size.height);
//            })
//            viewIsMovedUp = true
//        }
    }
    
    @IBAction func textFieldDidEndEditing(_ sender: UITextField) {
//        if viewIsMovedUp == true {
//            UIView.animate(withDuration: 0.25, animations: {
//                self.view.frame = CGRect(x:self.view.frame.origin.x, y:self.view.frame.origin.y + 250, width:self.view.frame.size.width, height:self.view.frame.size.height);
//                        })
//            viewIsMovedUp = false
//        }
    }
    
    
    @IBAction func logoIsTapped(_ sender: UITapGestureRecognizer) {
        
        print("logo tapped")
        //Alert the user if anyone is connected
        
        let alert = UIAlertController(title: "Connected Peeps", message: "You are currently connected to \(String(describing: serviceManager.session.connectedPeers.count)) peers", preferredStyle: .actionSheet)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
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
                print(date)
                newMessage.date = date
                let messageDict: NSDictionary = ["content": newMessage.content!, "date": String(describing: newMessage.date), "handle": newMessage.username!]
                saveContext()
                fetchAndReload()
                messageField.text = ""
                serviceManager.send(newMessage: messageDict)
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
                serviceManager = AnonServiceManager()
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
                let messageDict: NSDictionary = ["content": newMessage.content!, "date": String(describing: newMessage.date!), "handle": newMessage.username!]
                saveContext()
                fetchAndReload()
                messageField.text = ""
                serviceManager.send(newMessage: messageDict)
            }
            else {
                return
            }
        }
        messageField.resignFirstResponder()
    }
    
    func enableImageInteraction() {
        logo.isUserInteractionEnabled = true
        print("logo is prepped: \(logo.isUserInteractionEnabled)")
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
        
        DispatchQueue.main.async {
            self.messageTableView.reloadData()
        }
        
//        let indexPath = IndexPath(row: 0, section: 0)
//        messageTableView.scrollToRow(at: indexPath, at: .top, animated: false)
    }
}

// MARK: - TableView Methods

extension AnonViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let messageToDel = messageArr[indexPath.row]
        managedObjectContext.delete(messageToDel)
        saveContext()
        fetchAndReload()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        messageField.resignFirstResponder()
    }
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
        if let dateisok = date {
            cell.dateLabel.text = dateFormatter.string(from: date!)
        } else {
            print("date: \(String(describing: date))")
        }
        cell.nameLabel.text = messageArr[indexPath.row].username
        tableView.rowHeight = 72
        return cell
    }
}

extension AnonViewController: AnonServiceManagerDelegate {
    func connectedDevicesChanged(manager: AnonServiceManager, connectedDevices: [String]) {
        connectedPeers = connectedDevices
    }
    
    func newMessageReceived(manager: AnonServiceManager, messageDictionary: NSDictionary) {
        let receivedMessage = Message(context: managedObjectContext)
        receivedMessage.content = (messageDictionary.value(forKey: "content") as! String)
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .full
//        dateFormatter.timeStyle = .full
//        let dateStr = String(describing: messageDictionary.value(forKey: "date"))
//        let formattedDate = dateFormatter.date(from: dateStr)
//        print("formatted: \(formattedDate) \(messageDictionary.allValues)")
        receivedMessage.date = Date()
        receivedMessage.username = (messageDictionary.value(forKey: "handle") as! String)
        saveContext()
        fetchAndReload()
    }
}
