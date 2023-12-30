//
//  IWManagerVideosViewController.swift
//  PoseNet
//
//  Created by iosDeveloper on 2021/1/12.
//  Copyright © 2021 tensorflow. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Photos

class IWManagerVideosViewController: UIViewController {
    
    //  MARK: - Static constant
    private let Margin:CGFloat = 5
    private let ViewHeight:CGFloat = 50
    private let cellIdentifier = "videoCell"
    
    //  MARK: - Properties
    //  所有视频完整路径
    private var allVideosHolePaths: [String]?
    private var allImageArray = [UIImage]()
    //  表示是否被选中的数组
    private var cellStatusArray = [Bool]()
    //  载体 collectionView
    private var videosCollectionView: UICollectionView?
    //  视频是否处于可选择状态
    private var videoIsSelectedAble = false
    //  操作数组
    private var operatorVideosArray = [String]()
    //  选中cell的图片
    private var operatorVideosImage = [UIImage]()
    //  上传、删除按钮
    private var bottomView: UIView?
    //  操作数量Label
    private var countLabel = UILabel()
    

    //  MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "视频管理"
        //  获取全部本地视频路径
        allVideosHolePaths = getAllVideoPaths()
        
        //  获取截图
        getVideoImages(videoUrls: allVideosHolePaths!)


        //  collectionView
        videosCollectionView = prepareCollectionView()
        
        //  添加选择按钮
        addChooseButton()
        
        //  添加操作视图
        addBottomView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //  MARK: - Private Methods
    /**
     获取全部视频了路径
     
     - returns: 路径数组
     */
    private func getAllVideoPaths() -> [String] {
        var pathArray = [String]()
        //  Documents 文件夹
        let pathFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        //  文件夹路径
        let pathString = pathFolder[0] as String
        //  拼接获取每一个文件的完整路径
        if let lists = try? FileManager.default.contentsOfDirectory(atPath: pathString) {
            for item in lists {
                if(item.contains("mkv") == false ){
                    pathArray.append(pathString + "/" + item)
                }
            }
        }
        
        //  添加标识数组
        for _ in pathArray {
            cellStatusArray.append(false)
        }
        return pathArray
    }
    
    /**
     添加 collectionView
     
     - returns: collectionVIew
     */
    private func prepareCollectionView() -> UICollectionView {
        let flowLayout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        view.addSubview(collectionView)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        flowLayout.itemSize = CGSize(width: (view.bounds.width - 6 * Margin) / 5, height: (view.bounds.width - 6 * Margin) / 2.8)
        collectionView.contentInset = UIEdgeInsets(top: Margin, left: Margin, bottom: Margin, right: Margin)
        flowLayout.minimumLineSpacing = Margin
        flowLayout.minimumInteritemSpacing = Margin
        collectionView.register(videoCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.backgroundColor = .white
        
        return collectionView
    }
    
    /**
     添加选择按钮
     */
    private func addChooseButton() {
        let chooseButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 30))
        chooseButton.setTitle("选择", for: .normal)
        chooseButton.setTitle("取消", for: .selected)
        chooseButton.setTitleColor(.blue, for: .normal)
        chooseButton.addTarget(self, action: #selector(chooseButtonAction(btn:)), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: chooseButton)
    }
    
    /**
     底部操作视图
     */
    private func addBottomView() {
        bottomView = UIView(frame: CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: ViewHeight))
        view.addSubview(bottomView!)
        
        let uploadBtn = setBottomButtons(title: "上传", center: CGPoint(x: view.bounds.width / 4, y: ViewHeight / 2))
        let deleteBtn = setBottomButtons(title: "删除", center: CGPoint(x: view.bounds.width * 3 / 4, y: ViewHeight / 2))
        
        uploadBtn.addTarget(self, action: #selector(uploadAction), for: .touchUpInside)
        deleteBtn.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
        
        //  数量
        countLabel.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        countLabel.clipsToBounds = true
        countLabel.layer.cornerRadius = 15
        countLabel.backgroundColor = UIColor.red
        countLabel.textColor = UIColor.white
        countLabel.textAlignment = .center
        countLabel.text = "0"
        countLabel.center = CGPoint(x: bottomView!.bounds.width / 2, y: bottomView!.bounds.height / 2)
        bottomView?.addSubview(countLabel)
    }
    
    /// 是否展示下面的操作安妮
    private func showBottomView(isShow: Bool) {
        if isShow {
            UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                self.bottomView?.frame.origin.y -= self.ViewHeight
            })
        } else {
            UIView.animate(withDuration: 0.2) {
                self.bottomView?.frame.origin.y += self.ViewHeight
            }
        }
    }
    // MARK: - 临时写个弹窗方法
    func HsuAlert(title: String, message: String?, ensureTitle: String, cancleTitle: String?, ensureAction: ((UIAlertAction) -> Void)?, cancleAction: ((UIAlertAction) -> Void)?) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if cancleTitle != nil {
            alertVC.addAction(UIAlertAction(title: cancleTitle, style: .default, handler: cancleAction))
        }
        alertVC.addAction(UIAlertAction(title: ensureTitle, style: .default, handler: ensureAction))
        UIApplication.shared.keyWindow?.rootViewController?.present(alertVC, animated: true, completion: nil)
    }

    /// 统一风格上传、删除按钮
    private func setBottomButtons(title: String, center: CGPoint) -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: view.bounds.width / 3, height: ViewHeight - 10))
        button.center = center
        button.backgroundColor = .red
        button.clipsToBounds = true
        button.layer.cornerRadius = 15
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        bottomView?.addSubview(button)
        return button
    }
    
    //  删除事件
    @objc private func deleteAction() {
        //  删除本地文件
        for item in operatorVideosArray {
            do {
                let indexs = item.index(item.startIndex, offsetBy: item.count - 4)
                let itemName = item[..<indexs]
                let itemD = itemName + "d.mkv"
                let itemG = itemName + "g.mkv"
                print(item,itemD,itemG)
              try FileManager.default.removeItem(atPath: item)
                try FileManager.default.removeItem(atPath: String(itemD))
                try FileManager.default.removeItem(atPath: String(itemG))
            } catch let error {
                HsuAlert(title: "删除失败: \(error.localizedDescription)", message: nil, ensureTitle: "知道了", cancleTitle: nil, ensureAction: nil, cancleAction: nil)
            }
        }
        
        //  删除界面元素
        operatorVideosImage.forEach { (removeImg) in
            allImageArray.removeAll(where: { (img) -> Bool in
                removeImg == img
            })
        }
        
        //  重新解析地址
        allVideosHolePaths?.removeAll()
        operatorVideosImage.removeAll()
        allVideosHolePaths = getAllVideoPaths()
        operatorVideosArray.removeAll()
        countLabel.text = "0"
        
        //  刷新
        handleChooseAction(isChoose: true)
    }

    //  上传事件
    @objc private func uploadAction() {
        if(CameraViewController.islogin == false){
            self.view.makeToast("Please Login!",duration: 1.0, position: .center)
            return;
        }
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        for item in operatorVideosArray {
            do {
                let indexs = item.index(item.startIndex, offsetBy: item.count - 4)
                let itemName = item[..<indexs]
                let itemD = itemName + "d.mkv"
                let itemG = itemName + "g.mkv"
                var las = itemName.lastIndex(of: "/")!
                las = itemName.index(after:las)
                var name = itemName.substring(from: las)
//        let outputFileURL1 =  "\(path)/d.mkv"
//        let outputFileURL2 =  "\(path)/g.mkv"
                print(name)
                let outputFileURL1 =  itemD
                let outputFileURL2 =  itemG
                let file2URL = URL(fileURLWithPath: String(outputFileURL1))
                let file3URL = URL(fileURLWithPath: String(outputFileURL2))
                print("sendfile")
                print(outputFileURL1)
                print(outputFileURL2)
                self.view.makeToastActivityWithText(.center)
                let username = CameraViewController.username
                let password = CameraViewController.password
                let token = CameraViewController.token
                let patientName = name
                print(username,password,token,patientName)
                MyServiceProvider.request(.uploadFile(value1: username,value2:password,value3:token,
                    fx:CameraViewController.camerafx,fy:CameraViewController.camerafy,cx:CameraViewController.cameracx,cy:CameraViewController.cameracy,resColorH:CameraViewController.resColorH,resColorW:CameraViewController.resColorW,
                    fxDepth:CameraViewController.cameraDepthfx,fyDepth:CameraViewController.cameraDepthfy,cxDepth:CameraViewController.cameraDepthcx,cyDepth:CameraViewController.cameraDepthcy,resDepthH:CameraViewController.resDepthH,resDepthW:CameraViewController.resDepthW,
                    frame:CameraViewController.cameraframe,file2URL: file2URL, file3URL:file3URL,patientName:patientName),progress:{
                    progress in
                    var prog = Int(progress.progress*100)
                    UIView.sharedlabel.text = "\(prog)%"
                }) {
                    result in
                    switch result{
                        case let .success(response):
                            print("sendfile succeed")
                            //解析数据
                            self.view.makeToast("Upload Succeed",duration: 1.0, position: .center)
                            let data = try? response.mapString()
                            print(data ?? "")
                            break
                        case let .failure(error):
                            self.view.makeToast("Upload Failed",duration: 1.0, position: .center)
                            print(error.errorDescription)
                            break
                        }
                        self.view.hideToastActivity()
                }
            }
        }
        
    }
    
    //  点击选择按钮事件
    @objc private func chooseButtonAction(btn: UIButton) {
        btn.isSelected = !btn.isSelected
        showBottomView(isShow: btn.isSelected)
        handleChooseAction(isChoose: btn.isSelected)
    }
    
    //  处理
    private func handleChooseAction(isChoose: Bool) {
        videoIsSelectedAble = isChoose
        operatorVideosArray.removeAll()
        if videoIsSelectedAble {
            for index in 0 ..< cellStatusArray.count {
                cellStatusArray[index] = false
            }
        } else {
            for index in 0 ..< cellStatusArray.count {
                cellStatusArray[index] = true
            }
        }
        
        videosCollectionView?.reloadData()

    }
    
    /// 通过文件路径获取截图:
    private func getVideoImages(videoUrls: [String]) {
        //  获取截图
        allImageArray.removeAll()
        for item in videoUrls {
            let videoAsset = AVURLAsset(url: URL(fileURLWithPath: item))
            let cmTime = CMTime(seconds: 1, preferredTimescale: 10)
            let imageGenerator = AVAssetImageGenerator(asset: videoAsset)
            imageGenerator.appliesPreferredTrackTransform = true
            if let cgImg = try? imageGenerator.copyCGImage(at: cmTime, actualTime: nil) {
                let img = UIImage(cgImage: cgImg)
                self.allImageArray.append(img)
            } else {
                print("获取缩略图失败")
            }
        }
    }
    /// 通过文件路径获取文件名:
    private func getVideoName(videoUrl: URL) -> String {
        return videoUrl.lastPathComponent;
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension IWManagerVideosViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allVideosHolePaths?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! videoCollectionViewCell
        if allImageArray.count > 0 {
            cell.videoInterface?.image = allImageArray[indexPath.row % allImageArray.count]
        }
        //  蒙版状态
        cell.selectedButton.isHidden = !videoIsSelectedAble
        cell.videoNameLabel.text = getVideoName(videoUrl: URL(fileURLWithPath: allVideosHolePaths![indexPath.row]))
        cell.videoIsChooose = cellStatusArray[indexPath.row % cellStatusArray.count]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let cell = collectionView.cellForItem(at: indexPath) as! videoCollectionViewCell
        guard videoIsSelectedAble else {
            //  不可选择，点击预览
            let player = AVPlayer(url: URL(fileURLWithPath: allVideosHolePaths![indexPath.row]))
            let playerController = AVPlayerViewController()
            playerController.player = player
            present(playerController, animated: true, completion: nil)
            return
        }
        
        //  可选择
        cell.videoIsChooose = !cell.videoIsChooose!
        if cell.videoIsChooose == true {
            operatorVideosArray.append(allVideosHolePaths![indexPath.row])
            operatorVideosImage.append(allImageArray[indexPath.row])
        } else {
            let index = (operatorVideosArray as NSArray).index(of: allVideosHolePaths![indexPath.row])
            operatorVideosArray.remove(at: index)
            operatorVideosImage.remove(at: index)
        }
        
        countLabel.text = "\(operatorVideosArray.count)"
        cellStatusArray[indexPath.row] = cell.videoIsChooose!
    }
}


//  MARK: - Define Cell
class videoCollectionViewCell: UICollectionViewCell {
    
    //  封面
    var videoInterface: UIImageView?
    //  蒙版
    var effectView = UIVisualEffectView()
    //  是否选中图标
    var selectedButton = UIButton()
    var videoNameLabel = UILabel()
    var videoIsChooose: Bool? {
        willSet {
           selectedButton.isSelected = newValue!
            if newValue == true {
                effectView.alpha = 0
            } else {
                effectView.alpha = 0.4
            }
        }
    }
    
    //  初始化调用方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        videoIsChooose = false
        self.backgroundColor = UIColor.groupTableViewBackground
        
        makeInterfaceImage()
    }
    
    // 添加封面
    func makeInterfaceImage() {
        videoInterface = UIImageView(frame:CGRect(x:0,y:0,width: self.contentView.bounds.width,height: self.contentView.bounds.height - 40))
//        print(self.contentView.bounds.width,self.contentView.bounds.height)
        self.contentView.addSubview(videoInterface!)
        
        //  添加图标
        let playIconImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        playIconImageView.image = UIImage(named: "iw_playIcon")
        playIconImageView.center = CGPoint(x: videoInterface!.bounds.width / 2, y: videoInterface!.bounds.height / 2)
        videoInterface?.addSubview(playIconImageView)
        
        //  添加是否选中图标
        selectedButton.frame =  CGRect(x: 3, y: 3, width: 20, height: 20)
        selectedButton.setBackgroundImage(UIImage(named: "iw_unselected"), for: .normal)
        selectedButton.setBackgroundImage(UIImage(named: "iw_selected"), for: .selected)
        videoInterface?.addSubview(selectedButton)
        selectedButton.isHidden = true
        
        // 添加路径
        videoNameLabel.text = "测试文件名"
        videoNameLabel.frame = CGRect(x:0,y:videoInterface!.bounds.height ,width:videoInterface!.bounds.width,height: 40)
        videoNameLabel.textAlignment = NSTextAlignment.center
        self.contentView.addSubview(videoNameLabel)
        
        //  添加蒙版
        effectView.frame = videoInterface!.bounds
        effectView.effect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        effectView.alpha = 0.0
        videoInterface?.addSubview(effectView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
