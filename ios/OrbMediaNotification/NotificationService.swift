import UIKit
import UniformTypeIdentifiers
import UserNotifications

#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

/// Downloads a push image and attaches it so iOS can show a rich notification
/// even when the URL is in a custom data key (not only `fcm_options.image`).
final class NotificationService: UNNotificationServiceExtension {
  private var delivery: ((UNNotificationContent) -> Void)?
  private var mutableContent: UNMutableNotificationContent?
  private var downloadTask: URLSessionDownloadTask?

  private static let imageKeys: [String] = [
    "image",
    "image_url",
    "imageUrl",
    "image-url",
    "imageurl",
    "picture",
    "pic",
    "photo",
    "media",
    "media_url",
    "media-url",
    "mediaUrl",
    "attachment-url",
    "attachment_url",
    "attachment",
    "gcm.notification.image",
  ]

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    delivery = contentHandler
    mutableContent =
      request.content.mutableCopy() as? UNMutableNotificationContent

    guard let mutableContent else {
      contentHandler(request.content)
      return
    }

    if let imageURL = Self.imageURL(in: mutableContent.userInfo) {
      attach(imageURL, to: mutableContent)
      return
    }

    #if canImport(FirebaseMessaging)
    Messaging.serviceExtension().populateNotificationContent(
      mutableContent,
      withContentHandler: contentHandler
    )
    #else
    contentHandler(mutableContent)
    #endif
  }

  override func serviceExtensionTimeWillExpire() {
    downloadTask?.cancel()
    guard let delivery, let mutableContent else { return }
    delivery(mutableContent)
  }

  private func finish() {
    guard let delivery, let mutableContent else { return }
    delivery(mutableContent)
  }

  private func attach(_ url: URL, to content: UNMutableNotificationContent) {
    downloadTask = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
      defer { self?.finish() }
      guard let self, let tempURL, error == nil else { return }

      do {
        let file = try self.prepareAttachmentFile(
          from: tempURL,
          source: url,
          response: response
        )
        let attachment = try UNNotificationAttachment(
          identifier: "push-image",
          url: file,
          options: [
            UNNotificationAttachmentOptionsTypeHintKey: self.utiHint(for: file),
          ]
        )
        content.attachments = [attachment]
      } catch {
        // Deliver the banner without media rather than dropping the push.
      }
    }
    downloadTask?.resume()
  }

  private func prepareAttachmentFile(
    from tempURL: URL,
    source: URL,
    response: URLResponse?
  ) throws -> URL {
    let declared = Self.extensionHint(url: source, response: response)
    let bytes = try Data(contentsOf: tempURL, options: [.mappedIfSafe])
    let sniffed = Self.sniffExtension(bytes) ?? declared
    let dest = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)

    // UNNotificationAttachment officially accepts JPEG / PNG / GIF.
    // WebP and extension-less CDN URLs must be transcoded.
    if sniffed == "jpg" || sniffed == "png" || sniffed == "gif" {
      let file = dest.appendingPathExtension(sniffed)
      try bytes.write(to: file, options: .atomic)
      return file
    }

    guard let image = UIImage(data: bytes),
          let jpeg = image.jpegData(compressionQuality: 0.86) else {
      throw CocoaError(.fileReadCorruptFile)
    }
    let file = dest.appendingPathExtension("jpg")
    try jpeg.write(to: file, options: .atomic)
    return file
  }

  private func utiHint(for file: URL) -> String {
    switch file.pathExtension.lowercased() {
    case "png": return UTType.png.identifier
    case "gif": return UTType.gif.identifier
    default: return UTType.jpeg.identifier
    }
  }

  private static func imageURL(in payload: [AnyHashable: Any]) -> URL? {
    if let nested = payload["fcm_options"] as? [AnyHashable: Any],
       let url = url(from: nested["image"]) {
      return url
    }

    for key in imageKeys {
      if let url = url(from: payload[key]) {
        return url
      }
    }

    for container in ["data", "payload", "notification"] {
      if let nested = payload[container] as? [AnyHashable: Any],
         let url = imageURL(in: nested) {
        return url
      }
    }
    return nil
  }

  private static func url(from raw: Any?) -> URL? {
    guard let text = raw as? String else { return nil }
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.lowercased().hasPrefix("http"),
          let url = URL(string: trimmed) else { return nil }
    return url
  }

  private static func extensionHint(url: URL, response: URLResponse?) -> String {
    let pathExt = url.pathExtension.lowercased()
    if ["jpg", "jpeg", "png", "gif", "webp", "heic"].contains(pathExt) {
      return pathExt == "jpeg" ? "jpg" : pathExt
    }
    if let mime = (response as? HTTPURLResponse)?
      .value(forHTTPHeaderField: "Content-Type")?
      .lowercased() {
      if mime.contains("png") { return "png" }
      if mime.contains("gif") { return "gif" }
      if mime.contains("webp") { return "webp" }
      if mime.contains("jpeg") || mime.contains("jpg") { return "jpg" }
    }
    return "jpg"
  }

  private static func sniffExtension(_ data: Data) -> String? {
    if data.count >= 3 && data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF {
      return "jpg"
    }
    if data.count >= 4 && data[0] == 0x89 && data[1] == 0x50
      && data[2] == 0x4E && data[3] == 0x47 {
      return "png"
    }
    if data.count >= 4 && data[0] == 0x47 && data[1] == 0x49
      && data[2] == 0x46 && data[3] == 0x38 {
      return "gif"
    }
    if data.count >= 12,
       data[0] == 0x52, data[1] == 0x49, data[2] == 0x46, data[3] == 0x46,
       data[8] == 0x57, data[9] == 0x45, data[10] == 0x42, data[11] == 0x50 {
      return "webp"
    }
    return nil
  }
}
