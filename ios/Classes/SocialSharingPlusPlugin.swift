import Flutter
import UIKit
import Photos
import UniformTypeIdentifiers
import FBSDKCoreKit
import FBSDKShareKit
import Social

public class SocialSharingPlusPlugin: NSObject, FlutterPlugin {
    
    // MARK: - FlutterPlugin Protocol Methods
    
    /// Registers the plugin with the Flutter engine.
    ///
    /// - Parameters:
    ///   - registrar: FlutterPluginRegistrar object.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "social_sharing_plus", binaryMessenger: registrar.messenger())
        let instance = SocialSharingPlusPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    // MARK: - Method Call Handler
    
    /// Handles method calls from Flutter.
    ///
    /// - Parameters:
    ///   - call: Flutter method call object.
    ///   - result: FlutterResult object to complete the call.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(code: "ARGUMENT_ERROR", message: "Invalid arguments", details: nil))
            return
        }
        
        let isOpenBrowser = arguments["isOpenBrowser"] as? Bool ?? false

        switch call.method {
        case "shareToFacebook":
            shareToFacebook(arguments: arguments, result: result, isOpenBrowser: isOpenBrowser)
        case "shareToTwitter":
            shareToTwitter(arguments: arguments, result: result, isOpenBrowser: isOpenBrowser)
        case "shareToLinkedIn":
            shareToLinkedIn(arguments: arguments, result: result, isOpenBrowser: isOpenBrowser)
        case "shareToWhatsApp":
            shareToWhatsApp(arguments: arguments, result: result, isOpenBrowser: isOpenBrowser)
        case "shareToReddit":
            shareToReddit(arguments: arguments, result: result, isOpenBrowser: isOpenBrowser)
        case "shareToTelegram":
            shareToTelegram(arguments: arguments, result: result, isOpenBrowser: isOpenBrowser)
        case "shareToInstagram":
            shareToInstagram(arguments: arguments, result: result, isOpenBrowser: isOpenBrowser)
        case "shareToInstagramStory":
            shareToInstagramStory(arguments: arguments, result: result, isOpenBrowser: isOpenBrowser)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Share Methods
    
    /// Shares content to Facebook.
    ///
    /// - Parameters:
    ///   - arguments: Arguments dictionary containing content, media data, and appId.
    ///   - result: FlutterResult object to complete the call.
    ///   - isOpenBrowser: Flag indicating whether to open in browser if app not installed.
    private func shareToFacebook(arguments: [String: Any], result: @escaping FlutterResult, isOpenBrowser: Bool) {
        let content = arguments["content"] as? String
        let appId = arguments["appId"] as? String
        let mediaArgument = arguments["media"]
        let mediaUri: String? = (mediaArgument as? String) ?? (mediaArgument as? [String])?.first

        if let mediaUri = mediaUri {
            guard let image = UIImage(contentsOfFile: mediaUri) else {
                result(FlutterError(code: "IMAGE_ERROR", message: "Invalid image path for Facebook sharing", details: nil))
                return
            }

            let photo = SharePhoto(image: image, isUserGenerated: true)
            let photoContent = SharePhotoContent()
            photoContent.photos = [photo]
            if let content = content, !content.isEmpty {
                photoContent.hashtag = Hashtag(content)
            }

            DispatchQueue.main.async {
                guard let topController = self.topViewController() else {
                    result(FlutterError(code: "VIEW_ERROR", message: "Unable to find a view controller to present Facebook dialog", details: nil))
                    return
                }

                let dialog = ShareDialog(viewController: topController, content: photoContent, delegate: nil)
                do {
                    try dialog.validate()
                } catch {
                    result(FlutterError(code: "FACEBOOK_SHARE_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
                dialog.show()
                result(nil)
            }
        } else if let content = content {
            var webUrlString = "https://www.facebook.com/sharer/sharer.php?u=\(content)"
            if let appId = appId, !appId.isEmpty {
                webUrlString += "&app_id=\(appId)"
            }
            openUrl(urlString: webUrlString, webUrlString: webUrlString, result: result, isOpenBrowser: isOpenBrowser)
        } else {
            result(FlutterError(code: "CONTENT_REQUIRED", message: "Facebook sharing requires content or media", details: nil))
        }
    }

    /// Shares content to Twitter.
    ///
    /// - Parameters:
    ///   - arguments: Arguments dictionary containing content and image URIs.
    ///   - result: FlutterResult object to complete the call.
    ///   - isOpenBrowser: Flag indicating whether to open in browser if app not installed.
    private func shareToTwitter(arguments: [String: Any], result: @escaping FlutterResult, isOpenBrowser: Bool) {
        let content = arguments["content"] as? String
        let mediaArgument = arguments["media"]
        let mediaUris: [String] = (mediaArgument as? [String]) ?? ((mediaArgument as? String).map { [$0] } ?? [])
        
        guard content != nil || !mediaUris.isEmpty else {
            result(FlutterError(code: "CONTENT_REQUIRED", message: "Twitter sharing requires text or media", details: nil))
            return
        }
        
        guard let twitterURL = URL(string: "twitter://") else {
            result(FlutterError(code: "URL_ERROR", message: "Invalid Twitter URL scheme", details: nil))
            return
        }
        
        guard UIApplication.shared.canOpenURL(twitterURL) else {
            if let content = content, isOpenBrowser {
                let webUrlString = "https://x.com/intent/tweet?text=\(content)"
                openUrl(urlString: webUrlString, webUrlString: webUrlString, result: result, isOpenBrowser: true)
            } else {
                result(FlutterError(code: "APP_NOT_INSTALLED", message: "Twitter is not installed and browser option is not enabled", details: nil))
            }
            return
        }
        
        guard let composer = SLComposeViewController(forServiceType: SLServiceTypeTwitter) else {
            result(FlutterError(code: "TWITTER_COMPOSER_ERROR", message: "Unable to create Twitter composer", details: nil))
            return
        }
        
        if let content = content {
            composer.setInitialText(content)
            if #unavailable(iOS 16.0), let url = URL(string: content) {
                composer.add(url)
            }
        }
        
        for mediaPath in mediaUris {
            if let image = UIImage(contentsOfFile: mediaPath) {
                composer.add(image)
            }
        }
        
        DispatchQueue.main.async {
            guard let topController = self.topViewController() else {
                result(FlutterError(code: "VIEW_ERROR", message: "Unable to find a view controller to present Twitter composer", details: nil))
                return
            }
            
            topController.present(composer, animated: true, completion: nil)
            result(nil)
        }
    }

    /// Shares content to LinkedIn.
    ///
    /// - Parameters:
    ///   - arguments: Arguments dictionary containing content URI.
    ///   - result: FlutterResult object to complete the call.
    ///   - isOpenBrowser: Flag indicating whether to open in browser if app not installed.
    private func shareToLinkedIn(arguments: [String: Any], result: @escaping FlutterResult, isOpenBrowser: Bool) {
        if let content = arguments["content"] as? String {
            let urlString = "linkedin://shareArticle?mini=true&url=\(content)"
            let webUrlString = "https://www.linkedin.com/sharing/share-offsite/?url=\(content)"
            openUrl(urlString: urlString, webUrlString: webUrlString, result: result, isOpenBrowser: isOpenBrowser)
        }
    }

    /// Shares content to WhatsApp.
    ///
    /// - Parameters:
    ///   - arguments: Arguments dictionary containing content and image URIs.
    ///   - result: FlutterResult object to complete the call.
    ///   - isOpenBrowser: Flag indicating whether to open in browser if app not installed.
    private func shareToWhatsApp(arguments: [String: Any], result: @escaping FlutterResult, isOpenBrowser: Bool) {
        if let content = arguments["content"] as? String, let imageUri = arguments["media"] as? String {
            shareContentAndImageToSpecificApp(content: content, imageUri: imageUri, appUrlScheme: "whatsapp://", webUrlString: "https://api.whatsapp.com/send?text=\(content)", result: result, isOpenBrowser: isOpenBrowser)
        } else if let content = arguments["content"] as? String {
            let urlString = "whatsapp://send?text=\(content)"
            let webUrlString = "https://api.whatsapp.com/send?text=\(content)"
            openUrl(urlString: urlString, webUrlString: webUrlString, result: result, isOpenBrowser: isOpenBrowser)
        } else if let imageUri = arguments["media"] as? String {
            shareImageToSpecificApp(imageUri: imageUri, appUrlScheme: "whatsapp://", result: result, isOpenBrowser: isOpenBrowser)
        }
    }

    /// Shares content to Reddit.
    ///
    /// - Parameters:
    ///   - arguments: Arguments dictionary containing content URI.
    ///   - result: FlutterResult object to complete the call.
    ///   - isOpenBrowser: Flag indicating whether to open in browser if app not installed.
    private func shareToReddit(arguments: [String: Any], result: @escaping FlutterResult, isOpenBrowser: Bool) {
        if let content = arguments["content"] as? String {
            let urlString = "reddit://submit?url=\(content)"
            let webUrlString = "https://www.reddit.com/submit?title=\(content)"
            openUrl(urlString: urlString, webUrlString: webUrlString, result: result, isOpenBrowser: isOpenBrowser)
        }
    }

    /// Shares content to Telegram.
    ///
    /// - Parameters:
    ///   - arguments: Arguments dictionary containing content and image URIs.
    ///   - result: FlutterResult object to complete the call.
    ///   - isOpenBrowser: Flag indicating whether to open in browser if app not installed.
    private func shareToTelegram(arguments: [String: Any], result: @escaping FlutterResult, isOpenBrowser: Bool) {
        if let content = arguments["content"] as? String, let imageUri = arguments["media"] as? String {
            shareContentAndImageToSpecificApp(content: content, imageUri: imageUri, appUrlScheme: "tg://", webUrlString: "https://t.me/share/url?url=\(content)", result: result, isOpenBrowser: isOpenBrowser)
        } else if let content = arguments["content"] as? String {
            let urlString = "tg://msg?text=\(content)"
            let webUrlString = "https://t.me/share/url?url=\(content)"
            openUrl(urlString: urlString, webUrlString: webUrlString, result: result, isOpenBrowser: isOpenBrowser)
        } else if let imageUri = arguments["media"] as? String {
            shareImageToSpecificApp(imageUri: imageUri, appUrlScheme: "tg://", result: result, isOpenBrowser: isOpenBrowser)
        }
    }
    
    /// Shares media to Instagram feed via the native share sheet.
    ///
    /// - Parameters:
    ///   - arguments: Arguments dictionary containing content, media path, and appId.
    ///   - result: FlutterResult object to complete the call.
    ///   - isOpenBrowser: Flag indicating whether to open in browser if app not installed.
    private func shareToInstagram(arguments: [String: Any], result: @escaping FlutterResult, isOpenBrowser: Bool) {
        let appId = arguments["appId"] as? String
        let mediaArgument = arguments["media"]
        let mediaUri: String? = (mediaArgument as? String) ?? (mediaArgument as? [String])?.first

        guard let mediaUri = mediaUri else {
            if isOpenBrowser {
                openUrl(urlString: "https://www.instagram.com/", webUrlString: "https://www.instagram.com/", result: result, isOpenBrowser: true)
            } else {
                result(FlutterError(code: "MEDIA_REQUIRED", message: "Instagram sharing requires an image or video path", details: nil))
            }
            return
        }

        let isImageFile = self.isImage(filePath: mediaUri)
        if isImageFile {
            shareImageToInstagramFeed(mediaPath: mediaUri, appId: appId, isOpenBrowser: isOpenBrowser, result: result)
        } else {
            shareVideoToInstagramFeed(mediaPath: mediaUri, appId: appId, isOpenBrowser: isOpenBrowser, result: result)
        }
    }

    /// Shares media to Instagram story using the Instagram Stories scheme.
    ///
    /// - Parameters:
    ///   - arguments: Arguments dictionary containing content, media path, and appId.
    ///   - result: FlutterResult object to complete the call.
    ///   - isOpenBrowser: Flag indicating whether to open in browser if app not installed.
    private func shareToInstagramStory(arguments: [String: Any], result: @escaping FlutterResult, isOpenBrowser: Bool) {
        let content = arguments["content"] as? String
        let appId = arguments["appId"] as? String
        let mediaArgument = arguments["media"]
        let mediaUri: String? = (mediaArgument as? String) ?? (mediaArgument as? [String])?.first

        guard let mediaUri = mediaUri else {
            result(FlutterError(code: "MEDIA_REQUIRED", message: "Instagram story requires an image or video path", details: nil))
            return
        }

        let mediaURL = URL(fileURLWithPath: mediaUri)
        var pasteboardItem: [String: Any] = [:]

        if let image = UIImage(contentsOfFile: mediaUri), let imageData = image.pngData() {
            pasteboardItem["com.instagram.sharedSticker.backgroundImage"] = imageData
        } else if let videoData = try? Data(contentsOf: mediaURL) {
            pasteboardItem["com.instagram.sharedSticker.backgroundVideo"] = videoData
        }

        if let content = content {
            pasteboardItem["com.instagram.sharedSticker.attributionURL"] = content
        }

        guard !pasteboardItem.isEmpty else {
            result(FlutterError(code: "MEDIA_ERROR", message: "Unable to read media for Instagram story", details: nil))
            return
        }

        let options: [UIPasteboard.OptionsKey: Any] = [.expirationDate: Date().addingTimeInterval(300)]
        UIPasteboard.general.setItems([pasteboardItem], options: options)

        let sourceApplication = appId ?? Bundle.main.bundleIdentifier ?? ""
        guard let url = URL(string: "instagram-stories://share?source_application=\(sourceApplication)") else {
            result(FlutterError(code: "URL_ERROR", message: "Invalid Instagram story URL", details: nil))
            return
        }

        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                result(nil)
            } else if isOpenBrowser, let webUrl = URL(string: "https://www.instagram.com/") {
                UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
                result(nil)
            } else {
                result(FlutterError(code: "APP_NOT_INSTALLED", message: "Instagram is not installed and browser option is not enabled", details: nil))
            }
        }
    }
    
    // MARK: - URL Handling
    
    /// Opens the specified URL.
    ///
    /// - Parameters:
    ///   - urlString: URL string to open.
    ///   - webUrlString: Web URL string to open if app URL is not available.
    ///   - result: FlutterResult object to complete the call.
    ///   - isOpenBrowser: Flag indicating whether to open in browser if app not installed.
    private func openUrl(urlString: String, webUrlString: String, result: @escaping FlutterResult, isOpenBrowser: Bool) {
        if let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                result(nil)
            } else if isOpenBrowser, let webUrl = URL(string: webUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
                result(nil)
            } else {
                result(FlutterError(code: "APP_NOT_INSTALLED", message: "App not installed and browser option is not enabled", details: nil))
            }
        } else {
            result(FlutterError(code: "URL_ERROR", message: "Invalid URL", details: nil))
        }
    }
    
    // MARK: - Image Sharing
    
    /// Shares an image to a specific app.
    ///
    /// - Parameters:
    ///   - imageUri: Image file URI.
    ///   - appUrlScheme: App URL scheme to open.
    ///   - result: FlutterResult object to complete the call.
    ///   - isOpenBrowser: Flag indicating whether to open in browser if app not installed.
    private func shareImageToSpecificApp(imageUri: String, appUrlScheme: String, result: @escaping FlutterResult, isOpenBrowser: Bool) {
        guard let image = UIImage(contentsOfFile: imageUri) else {
            result(FlutterError(code: "IMAGE_ERROR", message: "Invalid image path", details: nil))
            return
        }
        guard let imageData = image.pngData() else {
            result(FlutterError(code: "IMAGE_DATA_ERROR", message: "Unable to get image data", details: nil))
            return
        }

        let pasteboard = UIPasteboard.general
        pasteboard.setData(imageData, forPasteboardType: "public.png")

        let urlString = "\(appUrlScheme)"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            result(nil)
        } else if isOpenBrowser {
            result(FlutterError(code: "APP_NOT_INSTALLED", message: "App not installed and browser option is not enabled", details: nil))
        } else {
            result(FlutterError(code: "APP_NOT_INSTALLED", message: "App not installed", details: nil))
        }
    }

    /// Shares content and image to a specific app.
    ///
    /// - Parameters:
    ///   - content: Content string to share.
    ///   - imageUri: Image file URI.
    ///   - appUrlScheme: App URL scheme to open.
    ///   - webUrlString: Web URL string to open if app URL is not available.
    ///   - result: FlutterResult object to complete the call.
    ///   - isOpenBrowser: Flag indicating whether to open in browser if app not installed.
    private func shareContentAndImageToSpecificApp(content: String, imageUri: String, appUrlScheme: String, webUrlString: String, result: @escaping FlutterResult, isOpenBrowser: Bool) {
        guard let image = UIImage(contentsOfFile: imageUri) else {
            result(FlutterError(code: "IMAGE_ERROR", message: "Invalid image path", details: nil))
            return
        }
        guard let imageData = image.pngData() else {
            result(FlutterError(code: "IMAGE_DATA_ERROR", message: "Unable to get image data", details: nil))
            return
        }

        let pasteboard = UIPasteboard.general
        pasteboard.setData(imageData, forPasteboardType: "public.png")

        var urlString = "\(appUrlScheme)"
        if appUrlScheme.contains("twitter://") {
            urlString += "post?message=\(content)"
        } else if appUrlScheme.contains("fb://") {
            urlString += "publish/profile/me?text=\(content)"
        } else if appUrlScheme.contains("whatsapp://") {
            urlString += "send?text=\(content)"
        } else if appUrlScheme.contains("tg://") {
            urlString += "msg?text=\(content)"
        }

        if let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            result(nil)
        } else if isOpenBrowser, let webUrl = URL(string: webUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
            result(nil)
        } else {
            result(FlutterError(code: "APP_NOT_INSTALLED", message: "App not installed and browser option is not enabled", details: nil))
        }
    }

    // MARK: - Helpers

    /// Returns the top-most view controller for presenting UI.
    private func topViewController(from root: UIViewController? = UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
        guard let root = root else { return nil }

        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        } else if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        } else if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }

        return root
    }

    // MARK: - Common share helpers

    private func buildShareItems(content: String?, mediaUri: String) -> [Any] {
        var items: [Any] = []
        if let content = content {
            items.append(content)
        }
        let mediaURL = URL(fileURLWithPath: mediaUri)
        if let image = UIImage(contentsOfFile: mediaUri) {
            items.append(image)
        } else {
            items.append(mediaURL)
        }
        return items
    }

    private func presentShareSheet(items: [Any], errorCode: String, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            guard let topController = self.topViewController() else {
                result(FlutterError(code: "VIEW_ERROR", message: "Unable to find a view controller to present share sheet", details: nil))
                return
            }

            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityVC.completionWithItemsHandler = { _, _, _, error in
                if let error = error {
                    result(FlutterError(code: errorCode, message: error.localizedDescription, details: nil))
                } else {
                    result(nil)
                }
            }

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topController.view
                popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
            }

            topController.present(activityVC, animated: true, completion: nil)
        }
    }

    // MARK: - Instagram Helpers (Feed)

    private func isImage(filePath: String) -> Bool {
        let url = URL(fileURLWithPath: filePath)
        if #available(iOS 14.0, *) {
            if let utType = UTType(filenameExtension: url.pathExtension) {
                return utType.conforms(to: .image)
            }
        }
        // Fallback: try loading as UIImage
        return UIImage(contentsOfFile: filePath) != nil
    }

    private func requestPhotoPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                completion(newStatus == .authorized || newStatus == .limited)
            }
        default:
            completion(false)
        }
    }

    private func shareImageToInstagramFeed(mediaPath: String, appId: String?, isOpenBrowser: Bool, result: @escaping FlutterResult) {
        requestPhotoPermissionIfNeeded { granted in
            guard granted else {
                result(FlutterError(code: "PHOTO_PERMISSION_DENIED", message: "Photo library access is required for Instagram sharing", details: nil))
                return
            }

            guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: mediaPath)) else {
                result(FlutterError(code: "IMAGE_ERROR", message: "Unable to load image data", details: nil))
                return
            }

            PHPhotoLibrary.shared().performChanges({
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let filePath = "\(documentsPath)/\(Date().description).jpeg"
                try? imageData.write(to: URL(fileURLWithPath: filePath), options: .atomic)
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(fileURLWithPath: filePath))
            }, completionHandler: { success, error in
                if success, let identifier = self.fetchLatestAssetIdentifier(mediaType: .image) {
                    self.openInstagramLibrary(with: identifier, appId: appId, isOpenBrowser: isOpenBrowser, result: result)
                } else if let error = error {
                    result(FlutterError(code: "INSTAGRAM_SHARE_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    result(FlutterError(code: "INSTAGRAM_SHARE_ERROR", message: "Unknown error while sharing to Instagram", details: nil))
                }
            })
        }
    }

    private func shareVideoToInstagramFeed(mediaPath: String, appId: String?, isOpenBrowser: Bool, result: @escaping FlutterResult) {
        requestPhotoPermissionIfNeeded { granted in
            guard granted else {
                result(FlutterError(code: "PHOTO_PERMISSION_DENIED", message: "Photo library access is required for Instagram sharing", details: nil))
                return
            }

            guard let videoData = try? Data(contentsOf: URL(fileURLWithPath: mediaPath)) else {
                result(FlutterError(code: "VIDEO_ERROR", message: "Unable to load video data", details: nil))
                return
            }

            PHPhotoLibrary.shared().performChanges({
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let filePath = "\(documentsPath)/\(Date().description).mp4"
                try? videoData.write(to: URL(fileURLWithPath: filePath), options: .atomic)
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
            }, completionHandler: { success, error in
                if success, let identifier = self.fetchLatestAssetIdentifier(mediaType: .video) {
                    self.openInstagramLibrary(with: identifier, appId: appId, isOpenBrowser: isOpenBrowser, result: result)
                } else if let error = error {
                    result(FlutterError(code: "INSTAGRAM_SHARE_ERROR", message: error.localizedDescription, details: nil))
                } else {
                    result(FlutterError(code: "INSTAGRAM_SHARE_ERROR", message: "Unknown error while sharing to Instagram", details: nil))
                }
            })
        }
    }

    private func fetchLatestAssetIdentifier(mediaType: PHAssetMediaType) -> String? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: mediaType, options: fetchOptions)
        return fetchResult.firstObject?.localIdentifier
    }

    private func openInstagramLibrary(with identifier: String, appId: String?, isOpenBrowser: Bool, result: @escaping FlutterResult) {
        var urlString = "instagram://library?LocalIdentifier=\(identifier)"
        if let appId = appId, !appId.isEmpty {
            urlString += "&source_application=\(appId)"
        }
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            result(FlutterError(code: "URL_ERROR", message: "Invalid Instagram URL", details: nil))
            return
        }

        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                result(nil)
            } else if isOpenBrowser, let webUrl = URL(string: "https://www.instagram.com/") {
                UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
                result(nil)
            } else {
                result(FlutterError(code: "APP_NOT_INSTALLED", message: "Instagram is not installed and browser option is not enabled", details: nil))
            }
        }
    }
}
