/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains view controller code for previewing live-captured content.
*/

import UIKit
import AVFoundation
import CoreVideo
import MobileCoreServices
import Accelerate
import Photos

@available(iOS 13.0, *)
class LoginViewController: UIViewController{
    @IBOutlet weak private var returnButton: UIButton!
    @IBOutlet weak private var loginButton: UIButton!
    @IBOutlet weak private var usernameText:UITextField!
    @IBOutlet weak private var passwordText:UITextField!
    
    @IBAction private func returnHome(_ sender:UIButton) {
        print("return")
        self.dismiss(animated: true, completion: nil)
    }
    func loginfunc(username: String, password:String){
        self.view.makeToastActivityWithText(.center)
        UIView.sharedlabel.text = "logining"
        MyServiceProvider.request(.login(value1: username, value2: password),progress:{
            progress in
            let prog = Int(progress.progress*100)
            print("\(prog)%")
        }) {
            result in
            switch result{
            case let .success(response):

                //解析数据
                let data = try? response.mapString()
                let status = data ?? ""
                print("status",status)
                self.view.hideToastActivity()
                if(status == "" || status == "error" ){
                    self.view.makeToast("Password Error",duration: 1.0, position: .center)
                }else{
                    self.view.makeToast("Login Succeed",duration: 1.0, position: .center)
                    CameraViewController.username = username
                    CameraViewController.password = password
                    CameraViewController.token = data ?? "test"

                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refresh"), object: nil, userInfo: nil)
                    self.dismiss(animated: true, completion: nil)
                }
                break
            case let .failure(error):
                self.view.hideToastActivity()
                self.view.makeToast("Connect Error",duration: 1.0, position: .center)
                print(error.errorDescription ?? "")
                break
            }
        }
    }
    @IBAction private func loginUser(_ sender:UIButton) {
        let password = passwordText.text ?? ""
        let username = usernameText.text ?? ""
        loginfunc(username:username, password:password)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKey()
        returnButton.layer.cornerRadius = 20
        loginButton.layer.cornerRadius = 20
        usernameText.layer.cornerRadius = 20
        passwordText.layer.cornerRadius = 20
        passwordText.isSecureTextEntry = true
        usernameText.placeholder = "默认账号:admin"
        passwordText.placeholder = "默认密码:123456"
    }
    
    
}
extension UIViewController{
    func hideKey(){
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap);
    }
    @objc private func dismissKeyboard(){
        view.endEditing(true)
    }
}

