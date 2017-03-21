//
//  ViewController.swift
//  WKWebViewQRcode
//
//  Created by Daniate on 2017/3/21.
//  Copyright © 2017年 Daniate. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler {
    
    private let scriptMessageHandlerName: String = "webImgLongPressHandler"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let userContentController = WKUserContentController()
        userContentController.add(self, name: scriptMessageHandlerName)
        
        let jqPath = Bundle.main.path(forResource: "jquery-3.1.1.min", ofType: "js")
        let jsPath = Bundle.main.path(forResource: "image-element-long-press", ofType: "js")
        let jqContent = try! String.init(contentsOfFile: jqPath!)
        let jsContent = try! String.init(contentsOfFile: jsPath!)
        let injectionContent = String.init(format: "%@\n%@", jqContent, jsContent)

        let userScript = WKUserScript.init(source: injectionContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(userScript)

        let config = WKWebViewConfiguration.init()
        config.userContentController = userContentController

        let webView = WKWebView.init(frame: self.view.bounds, configuration: config)
        
        webView.translatesAutoresizingMaskIntoConstraints = false;
        
        self.view.addSubview(webView)
        
        webView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
        
        let pagePath = Bundle.main.path(forResource: "index", ofType: "html")
        let html = try! String.init(contentsOfFile: pagePath!)
        webView.loadHTMLString(html, baseURL: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func QRcodesInImage(_ image: UIImage?) -> Array<String>? {
        if image == nil {
            return nil
        }
        let scanner = ZBarImageScanner()
        let barImg = ZBarImage.init(cgImage: image!.cgImage)
        let count = scanner.scanImage(barImg)
        if count == 0 {
            return nil
        }
        var codes = [String]()
        let symbolSet = scanner.results
        var symbol: OpaquePointer? = nil
        for i in 0 ..< symbolSet!.count {
            if i == 0 {
                symbol = zbar_symbol_set_first_symbol(symbolSet!.zbarSymbolSet)
            } else if symbol != nil {
                symbol = zbar_symbol_next(symbol)
            }
            if symbol != nil {
                let data = zbar_symbol_get_data(symbol)
                if let code = String.init(utf8String: data!) {
                    codes.append(code)
                }
            }
        }
        return codes.count > 0 ? codes : nil
    }

    // MARK: - WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name ==  self.scriptMessageHandlerName {
            if let urlString = message.body as? String {
                if let url = URL.init(string: urlString) {
                    let sessionConfig = URLSessionConfiguration.default
                    sessionConfig.requestCachePolicy = .returnCacheDataElseLoad
                    let session = URLSession.init(configuration: sessionConfig)
                    let dataTask = session.dataTask(with: url, completionHandler: { (data, response, error) in
                        if data != nil {
                            let img = UIImage.init(data: data!)
                            let codes = self.QRcodesInImage(img)
                            if codes != nil && codes!.count > 0 {
                                print("QRcodes: \(self.QRcodesInImage(img))")
                                DispatchQueue.main.async {
                                    // 弹出提示
                                    let sheet = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
                                    sheet.addAction(UIAlertAction.init(title: "识别二维码", style: .default, handler: { (action) in
                                        var urls = [URL]()
                                        for code in codes! {
                                            if let url = URL.init(string: code) {
                                                if UIApplication.shared.canOpenURL(url) {
                                                    urls.append(url)
                                                }
                                            }
                                        }
                                        let urlSheet = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
                                        for url in urls {
                                            let title = String.init(format: "打开%@", url.absoluteString)
                                            urlSheet.addAction(UIAlertAction.init(title: title, style: .default, handler: { (action) in
                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                            }))
                                        }
                                        urlSheet.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (action) in
                                            
                                        }))
                                        self.present(urlSheet, animated: true, completion: nil)
                                    }))
                                    sheet.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (action) in
                                        
                                    }))
                                    self.present(sheet, animated: true, completion: nil)
                                }
                            }
                        }
                    })
                    dataTask.resume()
                }
            }
        }
    }
}

