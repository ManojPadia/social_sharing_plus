/// Enum representing the various social media platforms.
enum SocialPlatform {
  /// Represents Facebook.
  ///
  /// For [iOS], only URL sharing is supported.
  ///
  /// For [Android], you can share both text, images and video in groups, as a profile picture, as a post/story or message.
  facebook,

  /// Represents LinkedIn.
  ///
  /// For [iOS], only text sharing is supported.
  ///
  /// For [Android], you can share both text, images and video in groups, as a post or message.
  linkedin,

  /// Represents Reddit.
  ///
  /// For [iOS], only text sharing is supported.
  ///
  /// For [Android], you can share both text, images and video as a post.
  reddit,

  /// Represents Reddit.
  ///
  /// For [iOS], only text sharing is supported.
  ///
  /// For [Android], you can share both text, images and video in groups, as a tweet or message.
  twitter,

  /// Represents WhatsApp.
  ///
  /// For [iOS], only text sharing is supported.
  ///
  /// For [Android], you can share both text, images and videos.
  whatsapp,

  /// Represents Telegram.
  ///
  /// For [iOS], only text sharing is supported.
  ///
  /// For [Android], you can share both text, images and videos.
  telegram,

  /// Represents Instagram (feed).
  ///
  /// For [iOS], sharing uses the native share sheet. For [Android], you can
  /// share text plus a single image or video directly to the Instagram app.
  instagram,

  /// Represents Instagram story.
  ///
  /// For [iOS] and [Android], a media asset (image or video) is required.
  instagramStory;

  /// Returns the method name corresponding to each social media platform.
  String get methodName {
    switch (this) {
      case SocialPlatform.facebook:
        return 'shareToFacebook';
      case SocialPlatform.linkedin:
        return 'shareToLinkedIn';
      case SocialPlatform.reddit:
        return 'shareToReddit';
      case SocialPlatform.twitter:
        return 'shareToTwitter';
      case SocialPlatform.whatsapp:
        return 'shareToWhatsApp';
      case SocialPlatform.telegram:
        return 'shareToTelegram';
      case SocialPlatform.instagram:
        return 'shareToInstagram';
      case SocialPlatform.instagramStory:
        return 'shareToInstagramStory';
    }
  }
}
