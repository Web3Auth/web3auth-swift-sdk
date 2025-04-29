import Foundation

public enum AuthConnection: String, Codable {
    case GOOGLE = "google"
    case FACEBOOK = "facebook"
    case REDDIT = "reddit"
    case DISCORD = "discord"
    case TWITCH = "twitch"
    case APPLE = "apple"
    case LINE = "line"
    case GITHUB = "github"
    case KAKAO = "kakao"
    case LINKEDIN = "linkedin"
    case TWITTER = "twitter"
    case WEIBO = "weibo"
    case WECHAT = "wechat"
    case EMAIL_PASSWORDLESS = "email_passwordless"
    case CUSTOM = "custom"
    case SMS_PASSWORDLESS = "sms_passwordless"
    case FARCASTER = "farcaster"
}
