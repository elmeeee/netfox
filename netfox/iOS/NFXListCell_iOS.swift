//
//  NFXListCell.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

import Foundation

#if os(iOS)

    import UIKit

    class NFXListCell: UITableViewCell {

        let padding: CGFloat = 12
        let cardPadding: CGFloat = 16

        var cardContainerView: UIView!
        var URLLabel: UILabel!
        var statusView: UIView!
        var statusGradientLayer: CAGradientLayer?
        var requestTimeLabel: UILabel!
        var timeIntervalLabel: UILabel!
        var typeLabel: UILabel!
        var methodLabel: UILabel!
        var methodBadge: UIView!
        var statusCodeLabel: UILabel!

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            backgroundColor = UIColor.NFXGray95Color()
            selectionStyle = .none

            // Card container with shadow and rounded corners
            cardContainerView = UIView(frame: .zero)
            cardContainerView.backgroundColor = UIColor.NFXCardBackgroundColor()
            cardContainerView.layer.cornerRadius = 16
            cardContainerView.layer.shadowColor = UIColor.black.cgColor
            cardContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
            cardContainerView.layer.shadowRadius = 8
            cardContainerView.layer.shadowOpacity = 0.08
            contentView.addSubview(cardContainerView)

            // Status view with gradient
            statusView = UIView(frame: .zero)
            statusView.layer.cornerRadius = 12
            statusView.layer.masksToBounds = true
            cardContainerView.addSubview(statusView)

            // Status code label
            statusCodeLabel = UILabel(frame: .zero)
            statusCodeLabel.textAlignment = .center
            statusCodeLabel.textColor = UIColor.white
            statusCodeLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            statusView.addSubview(statusCodeLabel)

            // Request time label
            requestTimeLabel = UILabel(frame: .zero)
            requestTimeLabel.textAlignment = .center
            requestTimeLabel.textColor = UIColor.white
            requestTimeLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
            requestTimeLabel.alpha = 0.9
            statusView.addSubview(requestTimeLabel)

            // Time interval label with badge style
            timeIntervalLabel = UILabel(frame: .zero)
            timeIntervalLabel.textAlignment = .center
            timeIntervalLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
            timeIntervalLabel.layer.cornerRadius = 8
            timeIntervalLabel.layer.masksToBounds = true
            timeIntervalLabel.backgroundColor = UIColor.NFXGray95Color()
            cardContainerView.addSubview(timeIntervalLabel)

            // URL Label with better typography
            URLLabel = UILabel(frame: .zero)
            URLLabel.textColor = UIColor.NFXBlackColor()
            URLLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            URLLabel.numberOfLines = 0
            URLLabel.lineBreakMode = .byCharWrapping
            cardContainerView.addSubview(URLLabel)

            // Method badge
            methodBadge = UIView(frame: .zero)
            methodBadge.layer.cornerRadius = 6
            methodBadge.layer.masksToBounds = true
            cardContainerView.addSubview(methodBadge)

            // Method label
            methodLabel = UILabel(frame: .zero)
            methodLabel.textAlignment = .center
            methodLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            methodBadge.addSubview(methodLabel)

            // Type label with icon-like style
            typeLabel = UILabel(frame: .zero)
            typeLabel.textColor = UIColor.NFXGray44Color()
            typeLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            cardContainerView.addSubview(typeLabel)
        }

        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            // Card container with padding
            cardContainerView.frame = CGRect(
                x: cardPadding,
                y: 6,
                width: frame.width - (cardPadding * 2),
                height: frame.height - 12
            )

            // Status view - rounded square on left
            statusView.frame = CGRect(
                x: 12, y: 12, width: 54, height: 54)

            // Status code label
            statusCodeLabel.frame = CGRect(
                x: 0, y: statusView.frame.height / 2 - 18, width: statusView.frame.width, height: 20
            )

            // Request time label
            requestTimeLabel.frame = CGRect(
                x: 0, y: statusCodeLabel.frame.maxY + 2, width: statusView.frame.width, height: 12)

            // Time interval badge - will be positioned on right side
            // (positioned after method/type to avoid overlap)

            // URL Label
            let urlWidth = cardContainerView.frame.width - statusView.frame.maxX - padding - 30
            let urlSize = URLLabel.sizeThatFits(
                CGSize(width: urlWidth, height: .greatestFiniteMagnitude))
            URLLabel.frame = CGRect(
                x: statusView.frame.maxX + padding,
                y: 12,
                width: urlWidth,
                height: max(20, urlSize.height)
            )

            // Method badge
            let methodWidth: CGFloat = 55
            methodBadge.frame = CGRect(
                x: statusView.frame.maxX + padding,
                y: URLLabel.frame.maxY + 8,
                width: methodWidth,
                height: 18
            )

            // Method label
            methodLabel.frame = methodBadge.bounds

            // Type label
            typeLabel.frame = CGRect(
                x: methodBadge.frame.maxX + 8,
                y: URLLabel.frame.maxY + 8,
                width: 100,
                height: 18
            )

            // Time interval badge - right side, same row
            timeIntervalLabel.frame = CGRect(
                x: cardContainerView.frame.width - 70,
                y: URLLabel.frame.maxY + 8,
                width: 65,
                height: 18
            )
        }

        func configForObject(_ obj: NFXHTTPModel) {
            setURL(obj.requestURL ?? "-")
            setStatus(obj.responseStatus ?? 999)
            setTimeInterval(obj.timeInterval ?? 999)
            setRequestTime(obj.requestTime ?? "-")
            setType(obj.responseType ?? "-")
            setMethod(obj.requestMethod ?? "-")
        }

        func setURL(_ url: String) {
            URLLabel.text = url
        }

        func setStatus(_ status: Int) {
            statusCodeLabel.text = status == 999 ? "..." : "\(status)"

            // Remove old gradient efficiently
            statusGradientLayer?.removeFromSuperlayer()
            statusGradientLayer = nil

            if status == 999 {
                // Pending/Loading - Gray
                statusView.backgroundColor = UIColor.NFXGray44Color()
                timeIntervalLabel.textColor = UIColor.NFXGray44Color()
            } else if status < 400 {
                // Success - Green gradient (optimized)
                statusView.backgroundColor = UIColor.NFXGreenColor()

                let gradientLayer = CAGradientLayer()
                gradientLayer.frame = statusView.bounds
                gradientLayer.colors = [
                    UIColor.NFXGreenColor().cgColor,
                    UIColor.NFXDarkGreenColor().cgColor,
                ]
                gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                gradientLayer.endPoint = CGPoint(x: 1, y: 1)
                gradientLayer.cornerRadius = 12

                // Performance optimization
                gradientLayer.shouldRasterize = true
                gradientLayer.rasterizationScale = UIScreen.main.scale

                statusView.layer.insertSublayer(gradientLayer, at: 0)
                statusGradientLayer = gradientLayer
                timeIntervalLabel.textColor = UIColor.NFXGreenColor()
            } else {
                // Error - Red gradient (optimized)
                statusView.backgroundColor = UIColor.NFXRedColor()

                let gradientLayer = CAGradientLayer()
                gradientLayer.frame = statusView.bounds
                gradientLayer.colors = [
                    UIColor.NFXRedColor().cgColor,
                    UIColor.NFXDarkRedColor().cgColor,
                ]
                gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                gradientLayer.endPoint = CGPoint(x: 1, y: 1)
                gradientLayer.cornerRadius = 12

                // Performance optimization
                gradientLayer.shouldRasterize = true
                gradientLayer.rasterizationScale = UIScreen.main.scale

                statusView.layer.insertSublayer(gradientLayer, at: 0)
                statusGradientLayer = gradientLayer
                timeIntervalLabel.textColor = UIColor.NFXRedColor()
            }
        }

        func setRequestTime(_ requestTime: String) {
            requestTimeLabel.text = requestTime
        }

        func setTimeInterval(_ timeInterval: Float) {
            if timeInterval == 999 {
                timeIntervalLabel.text = " - "
            } else {
                timeIntervalLabel.text = String(format: " %.2fs ", timeInterval)
            }
        }

        func setType(_ type: String) {
            typeLabel.text = "• \(type)"
        }

        func setMethod(_ method: String) {
            methodLabel.text = method

            // Color code method badges
            switch method {
            case "GET":
                methodBadge.backgroundColor = UIColor.NFXAccentColor().withAlphaComponent(0.15)
                methodLabel.textColor = UIColor.NFXAccentColor()
            case "POST":
                methodBadge.backgroundColor = UIColor.NFXGreenColor().withAlphaComponent(0.15)
                methodLabel.textColor = UIColor.NFXGreenColor()
            case "PUT", "PATCH":
                methodBadge.backgroundColor = UIColor.NFXYellowColor().withAlphaComponent(0.15)
                methodLabel.textColor = UIColor.NFXYellowColor()
            case "DELETE":
                methodBadge.backgroundColor = UIColor.NFXRedColor().withAlphaComponent(0.15)
                methodLabel.textColor = UIColor.NFXRedColor()
            default:
                methodBadge.backgroundColor = UIColor.NFXGray44Color().withAlphaComponent(0.15)
                methodLabel.textColor = UIColor.NFXGray44Color()
            }
        }
    }

#endif
