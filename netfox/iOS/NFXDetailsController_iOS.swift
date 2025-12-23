//
//  NFXDetailsController.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

#if os(iOS)

    import Foundation
    import UIKit
    import MessageUI

    private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
        switch (lhs, rhs) {
        case (let l?, let r?):
            return l < r
        case (nil, _?):
            return true
        default:
            return false
        }
    }

    private func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
        switch (lhs, rhs) {
        case (let l?, let r?):
            return l > r
        default:
            return rhs < lhs
        }
    }

    class NFXDetailsController_iOS: NFXDetailsController, MFMailComposeViewControllerDelegate {
        var infoButton: UIButton = UIButton()
        var requestButton: UIButton = UIButton()
        var responseButton: UIButton = UIButton()

        private var copyAlert: UIAlertController?

        var infoView: UIScrollView = UIScrollView()
        var requestView: UIScrollView = UIScrollView()
        var responseView: UIScrollView = UIScrollView()

        private lazy var headerButtons: [UIButton] = {
            return [self.infoButton, self.requestButton, self.responseButton]
        }()

        private lazy var infoViews: [UIScrollView] = {
            return [self.infoView, self.requestView, self.responseView]
        }()

        internal var sharedContent: String?

        // Offset for iOS 26 above
        private var headerTopInset: CGFloat = 0

        override func viewDidLoad() {
            super.viewDidLoad()

            title = "Details Response"

            // iOS 26+ modern background
            if #available(iOS 26.0, *) {
                view.backgroundColor = UIColor.NFXGray95Color()
            } else {
                view.backgroundColor = UIColor.white
            }

            // calculate offset inset for iOS 26+
            if #available(iOS 26.0, *) {
                headerTopInset = view.safeAreaInsets.top
            }

            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .action, target: self,
                action: #selector(NFXDetailsController_iOS.actionButtonPressed(_:)))

            // Header buttons
            infoButton = createHeaderButton(
                "Info", x: 0, selector: #selector(NFXDetailsController_iOS.infoButtonPressed))
            requestButton = createHeaderButton(
                "Request", x: infoButton.frame.maxX,
                selector: #selector(NFXDetailsController_iOS.requestButtonPressed))
            responseButton = createHeaderButton(
                "Response", x: requestButton.frame.maxX,
                selector: #selector(NFXDetailsController_iOS.responseButtonPressed))

            if #available(iOS 26.0, *) {
                [infoButton, requestButton, responseButton].forEach {
                    var f = $0.frame
                    f.origin.y += headerTopInset
                    $0.frame = f
                }
            }
            headerButtons.forEach { view.addSubview($0) }

            // Info views
            infoView = createDetailsView(getInfoStringFromObject(selectedModel), forView: .info)
            requestView = createDetailsView(
                getRequestStringFromObject(selectedModel), forView: .request)
            responseView = createDetailsView(
                getResponseStringFromObject(selectedModel), forView: .response)
            [infoView, requestView, responseView].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = true
                view.addSubview($0)
            }

            if #available(iOS 26.0, *) {
                [infoView, requestView, responseView].forEach {
                    var f = $0.frame
                    f.origin.y += headerTopInset
                    f.size.height -= headerTopInset
                    $0.frame = f
                }
            }

            let left = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            left.direction = .left
            let right = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            right.direction = .right
            view.addGestureRecognizer(left)
            view.addGestureRecognizer(right)

            infoButtonPressed()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()

            // iOS 26+ comprehensive safe area layout
            if #available(iOS 26.0, *) {
                let safeInsets = view.safeAreaInsets
                let topInset = safeInsets.top
                let bottomInset = safeInsets.bottom
                let leftInset = safeInsets.left
                let rightInset = safeInsets.right

                // Position header buttons within safe area
                let buttonWidth = (view.frame.width - leftInset - rightInset) / 3
                [infoButton, requestButton, responseButton].enumerated().forEach { idx, button in
                    button.frame = CGRect(
                        x: leftInset + (CGFloat(idx) * buttonWidth),
                        y: topInset,
                        width: buttonWidth,
                        height: 44
                    )
                }

                // Position content views within safe area
                let contentTop = topInset + 44
                let contentHeight = view.frame.height - contentTop - bottomInset
                let contentWidth = view.frame.width - leftInset - rightInset

                [infoView, requestView, responseView].forEach {
                    $0.frame = CGRect(
                        x: leftInset,
                        y: contentTop,
                        width: contentWidth,
                        height: contentHeight
                    )

                    // Update scroll view content insets for safe area
                    $0.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
                    $0.scrollIndicatorInsets = $0.contentInset
                }
            }
        }

        func createHeaderButton(_ title: String, x: CGFloat, selector: Selector) -> UIButton {
            var tempButton: UIButton
            tempButton = UIButton()
            tempButton.frame = CGRect(x: x, y: 0, width: view.frame.width / 3, height: 44)
            tempButton.autoresizingMask = [
                .flexibleLeftMargin, .flexibleRightMargin, .flexibleWidth,
            ]
            tempButton.backgroundColor = UIColor.NFXStarkWhiteColor()
            tempButton.setTitle(title, for: .init())
            tempButton.setTitleColor(UIColor.NFXGray44Color(), for: .init())
            tempButton.setTitleColor(UIColor.white, for: .selected)
            tempButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            tempButton.addTarget(self, action: selector, for: .touchUpInside)
            return tempButton
        }

        @objc fileprivate func copyLabel(lpgr: UILongPressGestureRecognizer) {
            guard let text = (lpgr.view as? UILabel)?.text ?? (lpgr.view as? UITextView)?.text,
                copyAlert == nil
            else { return }

            UIPasteboard.general.string = text

            let alert = UIAlertController(
                title: "Text Copied!", message: nil, preferredStyle: .alert)
            copyAlert = alert

            present(alert, animated: true) { [weak self] in
                guard let `self` = self else { return }

                Timer.scheduledTimer(
                    timeInterval: 0.45,
                    target: self,
                    selector: #selector(NFXDetailsController_iOS.dismissCopyAlert),
                    userInfo: nil,
                    repeats: false)
            }
        }

        @objc fileprivate func dismissCopyAlert() {
            copyAlert?.dismiss(animated: true) { [weak self] in self?.copyAlert = nil }
        }

        func createDetailsView(_ content: NSAttributedString, forView: EDetailsView) -> UIScrollView
        {
            var scrollView: UIScrollView
            scrollView = UIScrollView()

            let topY = 44 + headerTopInset
            scrollView.frame = CGRect(
                x: 0, y: topY, width: view.frame.width, height: view.frame.height - topY)
            scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            scrollView.autoresizesSubviews = true

            // Modern background for iOS 26+
            if #available(iOS 26.0, *) {
                scrollView.backgroundColor = UIColor.NFXGray95Color()
            } else {
                scrollView.backgroundColor = UIColor.clear
            }

            var textView: UITextView
            textView = UITextView()
            textView.frame = CGRect(
                x: 20, y: 20, width: scrollView.frame.width - 40,
                height: scrollView.frame.height - 20)
            textView.backgroundColor = UIColor.clear
            textView.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            textView.textColor = UIColor.NFXGray44Color()
            textView.isEditable = false
            textView.attributedText = content
            textView.sizeToFit()
            textView.isUserInteractionEnabled = true
            textView.delegate = self

            // iOS 26+ better text padding
            if #available(iOS 26.0, *) {
                textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            }

            scrollView.addSubview(textView)

            let lpgr = UILongPressGestureRecognizer(
                target: self, action: #selector(NFXDetailsController_iOS.copyLabel))
            textView.addGestureRecognizer(lpgr)

            // Modern styled button
            var moreButton: UIButton
            moreButton = UIButton.init(
                frame: CGRect(
                    x: 20, y: textView.frame.maxY + 16, width: scrollView.frame.width - 40,
                    height: 44))

            // Modern button styling
            moreButton.backgroundColor = UIColor.NFXOrangeColor()
            moreButton.setTitleColor(UIColor.white, for: .normal)
            moreButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            moreButton.layer.cornerRadius = 12
            moreButton.layer.shadowColor = UIColor.NFXOrangeColor().cgColor
            moreButton.layer.shadowOffset = CGSize(width: 0, height: 4)
            moreButton.layer.shadowRadius = 8
            moreButton.layer.shadowOpacity = 0.3

            if (forView == EDetailsView.request) && (selectedModel.requestBodyLength > 1024) {
                moreButton.setTitle("Show request body", for: .init())
                moreButton.addTarget(
                    self, action: #selector(NFXDetailsController_iOS.requestBodyButtonPressed),
                    for: .touchUpInside)
                scrollView.addSubview(moreButton)
                scrollView.contentSize = CGSize(
                    width: textView.frame.width, height: moreButton.frame.maxY + 16)

            } else if (forView == EDetailsView.response)
                && (selectedModel.responseBodyLength > 1024)
            {
                moreButton.setTitle("Show response body", for: .init())
                moreButton.addTarget(
                    self, action: #selector(NFXDetailsController_iOS.responseBodyButtonPressed),
                    for: .touchUpInside)
                scrollView.addSubview(moreButton)
                scrollView.contentSize = CGSize(
                    width: textView.frame.width, height: moreButton.frame.maxY + 16)

            } else {
                scrollView.contentSize = CGSize(
                    width: textView.frame.width, height: textView.frame.maxY + 16)
            }

            return scrollView
        }

        @objc func actionButtonPressed(_ sender: UIBarButtonItem) {
            let actionSheetController: UIAlertController = UIAlertController(
                title: nil, message: nil, preferredStyle: .actionSheet)

            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
            actionSheetController.addAction(cancelAction)

            let simpleLog: UIAlertAction = UIAlertAction(title: "Simple log", style: .default) {
                [unowned self] action -> Void in
                self.shareLog(full: false, sender: sender)
            }
            actionSheetController.addAction(simpleLog)

            let fullLogAction: UIAlertAction = UIAlertAction(title: "Full log", style: .default) {
                [unowned self] action -> Void in
                self.shareLog(full: true, sender: sender)
            }
            actionSheetController.addAction(fullLogAction)

            if let reqCurl = selectedModel.requestCurl {
                let curlAction: UIAlertAction = UIAlertAction(
                    title: "Export request as curl", style: .default
                ) { [unowned self] action -> Void in
                    let activityViewController = UIActivityViewController(
                        activityItems: [reqCurl], applicationActivities: nil)
                    activityViewController.popoverPresentationController?.barButtonItem = sender
                    self.present(activityViewController, animated: true, completion: nil)
                }
                actionSheetController.addAction(curlAction)
            }

            actionSheetController.view.tintColor = UIColor.NFXOrangeColor()
            actionSheetController.popoverPresentationController?.barButtonItem = sender

            present(actionSheetController, animated: true, completion: nil)
        }

        @objc func infoButtonPressed() {
            buttonPressed(infoButton)
        }

        @objc func requestButtonPressed() {
            buttonPressed(requestButton)
        }

        @objc func responseButtonPressed() {
            buttonPressed(responseButton)
        }

        @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            guard let currentButtonIdx = headerButtons.firstIndex(where: { $0.isSelected }) else {
                return
            }
            let numButtons = headerButtons.count

            switch gesture.direction {
            case .left:
                let nextIdx = currentButtonIdx + 1
                buttonPressed(headerButtons[nextIdx > numButtons - 1 ? 0 : nextIdx])
            case .right:
                let previousIdx = currentButtonIdx - 1
                buttonPressed(headerButtons[previousIdx < 0 ? numButtons - 1 : previousIdx])
            default: break
            }
        }

        func buttonPressed(_ sender: UIButton) {
            guard let selectedButtonIdx = headerButtons.firstIndex(of: sender) else { return }
            let infoViews = [infoView, requestView, responseView]

            UIView.animate(
                withDuration: 0.4,
                delay: 0.0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.7,
                options: .curveEaseInOut,
                animations: { [unowned self] in
                    self.headerButtons.indices.forEach {
                        let button = self.headerButtons[$0]
                        let view = infoViews[$0]

                        button.isSelected = button == sender

                        // Update button appearance with gradient
                        if button.isSelected {
                            // Add gradient background
                            let gradientLayer = CAGradientLayer()
                            gradientLayer.frame = button.bounds
                            gradientLayer.colors = [
                                UIColor.NFXGradientStartColor().cgColor,
                                UIColor.NFXGradientEndColor().cgColor,
                            ]
                            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                            gradientLayer.endPoint = CGPoint(x: 1, y: 0)
                            button.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
                            button.layer.insertSublayer(gradientLayer, at: 0)
                        } else {
                            button.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
                            button.backgroundColor = UIColor.NFXStarkWhiteColor()
                        }

                        view.frame = CGRect(
                            x: CGFloat(-selectedButtonIdx + $0) * view.frame.size.width,
                            y: view.frame.origin.y,
                            width: view.frame.size.width,
                            height: view.frame.size.height)
                    }
                },
                completion: nil)
        }

        @objc func responseBodyButtonPressed() {
            bodyButtonPressed().bodyType = NFXBodyType.response
        }

        @objc func requestBodyButtonPressed() {
            bodyButtonPressed().bodyType = NFXBodyType.request
        }

        func bodyButtonPressed() -> NFXGenericBodyDetailsController {

            var bodyDetailsController: NFXGenericBodyDetailsController

            if selectedModel.shortType == .IMAGE {
                bodyDetailsController = NFXImageBodyDetailsController()
            } else {
                bodyDetailsController = NFXRawBodyDetailsController()
            }
            bodyDetailsController.selectedModel(selectedModel)
            navigationController?.pushViewController(bodyDetailsController, animated: true)
            return bodyDetailsController
        }

        func shareLog(full: Bool, sender: UIBarButtonItem) {
            var tempString = String()

            tempString += "** INFO **\n"
            tempString += "\(getInfoStringFromObject(selectedModel).string)\n\n"

            tempString += "** REQUEST **\n"
            tempString += "\(getRequestStringFromObject(selectedModel).string)\n\n"

            tempString += "** RESPONSE **\n"
            tempString += "\(getResponseStringFromObject(selectedModel).string)\n\n"

            tempString += "logged via netfox - [https://github.com/elmeeee/netfox]\n"

            if full {
                let requestFileURL = selectedModel.getRequestBodyFileURL()
                if let requestFileData = try? String(contentsOf: requestFileURL, encoding: .utf8) {
                    tempString += requestFileData
                }

                let responseFileURL = selectedModel.getResponseBodyFileURL()
                if let responseFileData = try? String(contentsOf: responseFileURL, encoding: .utf8)
                {
                    tempString += responseFileData
                }
            }

            displayShareSheet(shareContent: tempString, sender: sender)
        }

        func displayShareSheet(shareContent: String, sender: UIBarButtonItem) {
            self.sharedContent = shareContent
            let activityViewController = UIActivityViewController(
                activityItems: [self], applicationActivities: nil)
            activityViewController.popoverPresentationController?.barButtonItem = sender
            present(activityViewController, animated: true, completion: nil)
        }
    }

    extension NFXDetailsController_iOS: UIActivityItemSource {
        public typealias UIActivityType = UIActivity.ActivityType

        func activityViewControllerPlaceholderItem(
            _ activityViewController: UIActivityViewController
        ) -> Any {
            return "placeholder"
        }

        func activityViewController(
            _ activityViewController: UIActivityViewController,
            itemForActivityType activityType: UIActivityType?
        ) -> Any? {
            return sharedContent
        }

        func activityViewController(
            _ activityViewController: UIActivityViewController,
            subjectForActivityType activityType: UIActivityType?
        ) -> String {
            return "netfox log - \(selectedModel.requestURL!)"
        }
    }

    extension NFXDetailsController_iOS: UITextViewDelegate {

        func textView(
            _ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange
        ) -> Bool {
            let decodedURL = URL.absoluteString.removingPercentEncoding
            switch decodedURL {
            case "[URL]":
                guard let queryItems = selectedModel.requestURLQueryItems, queryItems.count > 0
                else {
                    return false
                }
                let urlDetailsController = NFXURLDetailsController()
                urlDetailsController.selectedModel = selectedModel
                navigationController?.pushViewController(urlDetailsController, animated: true)
                return true
            default:
                return false
            }
        }

    }

#endif
