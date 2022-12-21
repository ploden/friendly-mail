//
//  AddAccountVC.swift
//  friendly-mail
//
//  Created by Philip Loden on 7/26/21.
//

import Foundation
import UIKit
import AppAuth
import friendly_mail_core

class AddAccountVC: UIViewController {
    @IBOutlet weak var nameTextField: UITextField?
    @IBOutlet weak var emailAddressTextField: UITextField?
    @IBOutlet weak var passwordTextField: UITextField?
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    
        if (UIApplication.shared.delegate as? AppDelegate)?.settings?.isValid == false {
            emailAddressTextField?.text = nil
            passwordTextField?.text = nil
        }
    }
    
    @IBAction func doneButtonTapped(sender: Any) {
        let session = MCOIMAPSession()
        session.hostname = "imap.gmail.com"
        session.port = 993
        session.username = emailAddressTextField?.text
        session.password = passwordTextField?.text
        session.connectionType = .TLS
        
        let requestKind: MCOIMAPMessagesRequestKind = .headers
        let folder = "Inbox"
        let uids = MCOIndexSet(range: MCORange(location: 1, length: 1))
        
        let fetchOperation: MCOIMAPFetchMessagesOperation = session.fetchMessagesOperation(withFolder: folder, requestKind: requestKind, uids: uids)
        
        let logger = (UIApplication.shared.delegate as? AppDelegate)?.logger
        
        fetchOperation.start { error, fetchedFolders, arg  in
            if let error = error {
                logger?.log(message: "AddAccountVC: doneButtonTapped: error: \(error)")
            } else {
                logger?.log(message: "AddAccountVC: doneButtonTapped: authentication succeeded")
                if let settings = (UIApplication.shared.delegate as? AppDelegate)?.settings {
                    let user = friendly_mail_core.Address(name: self.nameTextField!.text!, address: session.username)!
                    _ = settings.new(withUser: user, password: session.password).save(toUserDefaults: .standard)
                }
            }
        }
    }
    
    @IBAction func viewTapped(sender: Any) {
        //let authorizationEndpoint = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")
        //let tokenEndpoint = URL(string: "https://www.googleapis.com/oauth2/v4/token")
        
        let redirectURL = URL(string: "com.googleusercontent.apps.820729101438-bt5tt835cpgq3fqasciomuhcscgt624h:/oauth2redirect/example-provider")!
        let clientID = "820729101438-bt5tt835cpgq3fqasciomuhcscgt624h.apps.googleusercontent.com"
        
        // performs authentication request
        if let app = (UIApplication.shared.delegate as? AppDelegate) {
            if let issuer = URL(string: "https://accounts.google.com") {
                OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
                    if let configuration = configuration {
                        let scopes = [
                            OIDScopeOpenID,
                            OIDScopeEmail,
                            OIDScopeProfile,
                            "https://www.googleapis.com/auth/gmail.labels",
                            "https://www.googleapis.com/auth/gmail.readonly",
                            "https://www.googleapis.com/auth/gmail.metadata",
                            "https://www.googleapis.com/auth/gmail.modify",
                            "https://www.googleapis.com/auth/gmail.send",
                            "https://mail.google.com/"
                        ]
                        let request = OIDAuthorizationRequest(configuration: configuration, clientId: clientID, scopes: scopes, redirectURL: redirectURL, responseType: OIDResponseTypeCode, additionalParameters: nil)
                        
                        app.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: self, callback: { authState, error in
                            OperationQueue.main.addOperation {
                                if let authState = authState {
                                    if
                                        let newSettings = (UIApplication.shared.delegate as? AppDelegate)?.settings?.new(withAuthState: authState),
                                        newSettings.isValid
                                    {
                                        _ = newSettings.save(toUserDefaults: UserDefaults.standard)
                                    }
                                    self.getUserInfo(authState: authState)
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    func getUserInfo(authState: OIDAuthState) {
        let logger = (UIApplication.shared.delegate as? AppDelegate)?.logger

        guard let userinfoEndpoint = authState.lastAuthorizationResponse.request.configuration.discoveryDocument?.userinfoEndpoint else {
            logger?.log(message: "Userinfo endpoint not declared in discovery document")
            return
        }

        logger?.log(message: "Performing userinfo request")

        let currentAccessToken: String? = authState.lastTokenResponse?.accessToken

        authState.performAction() { (accessToken, idToken, error) in
            if error != nil  {
                logger?.log(message: "Error fetching fresh tokens: \(error?.localizedDescription ?? "ERROR")")
                return
            }

            guard let accessToken = accessToken else {
                logger?.log(message: "Error getting accessToken")
                return
            }

            if currentAccessToken != accessToken {
                logger?.log(message: "Access token was refreshed automatically (\(currentAccessToken ?? "CURRENT_ACCESS_TOKEN") to \(accessToken))")
            } else {
                logger?.log(message: "Access token was fresh and not updated \(accessToken)")
            }

            var urlRequest = URLRequest(url: userinfoEndpoint)
            
            urlRequest.allHTTPHeaderFields = ["Authorization":"Bearer \(accessToken)"]

            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in

                DispatchQueue.main.async {
                    
                    guard error == nil else {
                        logger?.log(message: "HTTP request failed \(error?.localizedDescription ?? "ERROR")")
                        return
                    }

                    guard let response = response as? HTTPURLResponse else {
                        logger?.log(message: "Non-HTTP response")
                        return
                    }

                    guard let data = data else {
                        logger?.log(message: "HTTP response data is empty")
                        return
                    }

                    var json: [AnyHashable: Any]?

                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    } catch {
                        logger?.log(message: "JSON Serialization Error")
                    }

                    if response.statusCode != 200 {
                        // server replied with an error
                        let responseText: String? = String(data: data, encoding: String.Encoding.utf8)

                        if response.statusCode == 401 {
                            // "401 Unauthorized" generally indicates there is an issue with the authorization
                            // grant. Puts OIDAuthState into an error state.
                            let oauthError = OIDErrorUtilities.resourceServerAuthorizationError(withCode: 0,
                                                                                                errorResponse: json,
                                                                                                underlyingError: error)
                            authState.update(withAuthorizationError: oauthError)
                            logger?.log(message: "Authorization Error (\(oauthError)). Response: \(responseText ?? "RESPONSE_TEXT")")
                        } else {
                            logger?.log(message: "HTTP: \(response.statusCode), Response: \(responseText ?? "RESPONSE_TEXT")")
                        }

                        return
                    }

                    if
                        let json = json,
                        let email = json["email"] as? String
                    {
                        logger?.log(message: "Success: \(json)")
                        let name = json["name"] as? String ?? nil
                        let given = json["given_name"] as? String ?? nil
                        let family = json["family_name"] as? String ?? nil
                        
                        if let address = Address(name: name, givenName: given, familyName: family, address: email) {
                            OperationQueue.main.addOperation {
                                if let settings = (UIApplication.shared.delegate as? AppDelegate)?.settings {
                                    _ = settings.new(withUser: address, authState: authState).save(toUserDefaults: .standard)
                                } else {
                                    let theme = (UIApplication.shared.delegate as! AppDelegate).appConfig.defaultTheme
                                    let settings = AppleSettings(user: address, selectedTheme: theme)
                                    _ = settings.new(withUser: address, authState: authState).save(toUserDefaults: .standard)
                                }
                            }
                        }
                    }
                }
            }

            task.resume()
        }
    }
    
}

extension AddAccountVC: UITextFieldDelegate {
    
    func updateDoneBarButtonItem() {
        if
            let email = emailAddressTextField?.text,
            let password = passwordTextField?.text,
            let name = nameTextField?.text
        {
            doneBarButtonItem?.isEnabled = email.count > 0 && password.count > 0 && name.count > 0
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateDoneBarButtonItem()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateDoneBarButtonItem()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        updateDoneBarButtonItem()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        updateDoneBarButtonItem()
    }
}
