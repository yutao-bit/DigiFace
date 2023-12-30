//
//  FilePost.swift
//  TrueDepthStreamer
//
//  Created by iosDeveloper on 2021/10/18.
//  Copyright © 2021 Apple. All rights reserved.
//
import Foundation
import Moya
let MyServiceProvider = MoyaProvider<MyService>()
public enum MyService {
    case uploadFile(value1: String, value2: String,value3:String,
        fx:String,fy:String,cx:String,cy:String,resColorH:String,resColorW:String,
        fxDepth:String,fyDepth:String,cxDepth:String,cyDepth:String,resDepthH:String,resDepthW:String,
        frame:String,file2URL:URL, file3URL:URL,patientName:String)
    case login(value1: String, value2:String)
    //上传文件
}
//请求配置
extension MyService: TargetType {
    //服务器地址
    public var baseURL: URL {
        return URL(string: "http://thss10402.tpddns.cn:10218")!
//        return URL(string: "http://192.168.137.225:8081")!
        
    }
     
    //各个请求的具体路径
    public var path: String {
        switch self {
        case .uploadFile:
            return "/appapi/create"
        case .login:
            return "/appapi/login"
        }
        
    }
     
    //请求类型
    public var method: Moya.Method {
        return .post
    }
     
    //请求任务事件（这里附带上参数）
    public var task: Task {
        switch self {
        case let .uploadFile(value1,value2,value3,fx,fy,cx,cy,resColorH,resColorW,
                             fxDepth,fyDepth,cxDepth,cyDepth,resDepthH,resDepthW,frame,file2URL, file3URL,patientName):
            //字符串
            let strData1 = value1.data(using: .utf8)
            let formData1 = MultipartFormData(provider: .data(strData1!), name: "username")
            
            let strData2 = value2.data(using: .utf8)
            let formData2 = MultipartFormData(provider: .data(strData2!), name: "password")
            
            let strData3 = value3.data(using: .utf8)
            let formData3 = MultipartFormData(provider: .data(strData3!), name: "token")
            
            //文件2
            let formData4 = MultipartFormData(provider: .file(file2URL), name: "videod",
                                              fileName: "d.mkv", mimeType: "video/x-matroska")
            //文件2
            let formData5 = MultipartFormData(provider: .file(file3URL), name: "videog",
                                              fileName: "g.mkv", mimeType: "video/x-matroska")
            
            let strData6 = fx.data(using: .utf8)
            let formData6 = MultipartFormData(provider: .data(strData6!), name: "fx")
            let strData7 = fy.data(using: .utf8)
            let formData7 = MultipartFormData(provider: .data(strData7!), name: "fy")
            let strData8 = cx.data(using: .utf8)
            let formData8 = MultipartFormData(provider: .data(strData8!), name: "cx")
            let strData9 = cy.data(using: .utf8)
            let formData9 = MultipartFormData(provider: .data(strData9!), name: "cy")
            let strData10 = resColorH.data(using: .utf8)
            let formData10 = MultipartFormData(provider: .data(strData10!), name: "resColorH")
            let strData11 = resColorW.data(using: .utf8)
            let formData11 = MultipartFormData(provider: .data(strData11!), name: "resColorW")
            
            let strData12 = fxDepth.data(using: .utf8)
            let formData12 = MultipartFormData(provider: .data(strData12!), name: "fxDepth")
            let strData13 = fyDepth.data(using: .utf8)
            let formData13 = MultipartFormData(provider: .data(strData13!), name: "fyDepth")
            let strData14 = cxDepth.data(using: .utf8)
            let formData14 = MultipartFormData(provider: .data(strData14!), name: "cxDepth")
            let strData15 = cyDepth.data(using: .utf8)
            let formData15 = MultipartFormData(provider: .data(strData15!), name: "cyDepth")
            let strData16 = resDepthH.data(using: .utf8)
            let formData16 = MultipartFormData(provider: .data(strData16!), name: "resDepthH")
            let strData17 = resDepthW.data(using: .utf8)
            let formData17 = MultipartFormData(provider: .data(strData17!), name: "resDepthW")
            
            let strData18 = frame.data(using: .utf8)
            let formData18 = MultipartFormData(provider: .data(strData18!), name: "frame")
            let strData19 = patientName.data(using: .utf8)
            let formData19 = MultipartFormData(provider: .data(strData19!), name: "patientName")
            
            print(file2URL,file3URL)
            let multipartData = [formData1, formData2, formData3,formData3,formData4,formData5,formData6,formData7,formData8,formData9,formData10,formData11,formData12,formData13,formData14,formData15,formData16,formData17,formData18,formData19]
            return .uploadMultipart(multipartData)
            
        case .login(value1: let value1, value2: let value2):
            return .requestParameters(parameters: ["username": value1,"password":value2], encoding:URLEncoding.default)
        }
    }
     
    //是否执行Alamofire验证
    public var validate: Bool {
        return false
    }
     
    //这个就是做单元测试模拟的数据，只会在单元测试文件中有作用
    public var sampleData: Data {
        return "{}".data(using: String.Encoding.utf8)!
    }
     
    //请求头
    public var headers: [String: String]? {
        return nil
    }
}
