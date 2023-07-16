import CXShim
import Foundation
#if canImport(OSLog)
import OSLog
#endif

let VERSION = "v3"

let formatter1 = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .gmt
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    return formatter
}()

let formatter2 = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .gmt
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return formatter
}()

let decoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder -> Date in
        let container = try decoder.singleValueContainer()
        let dateStr = try container.decode(String.self)
        var date: Date?
        if dateStr.contains(".") {
            date = formatter1.date(from: dateStr)
        } else {
            date = formatter2.date(from: dateStr)
        }
        guard let date_ = date else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateStr)")
        }
        return date_
    }
    return decoder
}()

public class LemmyApi {
    public var apiUrl: URL
    public var baseUrl: String
    private var cancellable: Set<AnyCancellable> = Set()
    public var jwt: String?
    private var encoder = JSONEncoder()
    
    public enum LemmyError: Swift.Error {
        case invalidUrl
    }

    public init(baseUrl: String) throws {
        var baseUrl = baseUrl
        let regex = /https?:\/\//
        if !baseUrl.contains(regex) {
            baseUrl = "https://" + baseUrl
        }
        self.baseUrl = baseUrl.lowercased().replacing("/+$", with: "")
        guard let apiUrl = URL(string: "\(self.baseUrl)/api/\(VERSION)") else {
            throw LemmyError.invalidUrl
        }
        self.apiUrl = apiUrl
    }
    
    public func setJwt(jwt: String?) {
        self.jwt = jwt
    }
    
    public func makeRequestWithBody<ResponseType: Decodable, BodyType: Encodable>(path: String, query: [URLQueryItem] = [], responseType: ResponseType.Type, body: BodyType, receiveValue: @escaping (ResponseType?, NetworkError?) -> Void) -> AnyCancellable where BodyType: WithMethod {
        var url = apiUrl.appending(path: path).appending(queryItems: query)
#if canImport(OSLog)
        os_log("url %{public}s", url.absoluteString)
#else
        print(url.absoluteString)
#endif
        if jwt != nil {
            url = url.appending(queryItems: [URLQueryItem(name: "auth", value: jwt!)])
        }
        var request = URLRequest(url: url)
        request.setValue("ios:com.axlav.lemmios:v1.0.0 (by @mrlavallee@lemmy.world)", forHTTPHeaderField: "User-Agent")
        request.httpMethod = body.method
        if !(body is NoBody) {
            request.httpBody = try! encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return URLSession.shared.dataTaskPublisher(for: request)
            // #1 URLRequest fails, throw APIError.network
            .mapError { error in
                let networkError = NetworkError.network(code: error.code.rawValue, description: error.localizedDescription)
#if canImport(OSLog)
                os_log("\(networkError)")
#else
                print(networkError)
#endif
                return networkError
            }
            .tryMap { v in
                let code = (v.response as! HTTPURLResponse).statusCode
                if code != 200 {
#if canImport(OSLog)
                    os_log("body %{public}s", String(data: v.data, encoding: .utf8) ?? "")
#else
                    print(String(v.data, encoding: .utf8) ?? "")
#endif
                    if let decoded = try? decoder.decode(ErrorData.self, from: v.data) {
                        throw NetworkError.lemmyError(message: decoded.error, code: code)
                    }
                    throw NetworkError.network(code: code, description: String(data: v.data, encoding: .utf8) ?? "")
                }
                return v
            }
            .retryWithDelay(retries: 10, delay: 5, scheduler: DispatchQueue.global())
            .flatMap { v in
                Just(v.data)
                
                    // #2 try to decode data as a `Response`
                    .decode(type: ResponseType.self, decoder: decoder)
                
                    .mapError { error in
                        let decodingError = NetworkError.decoding(
                            message: String(data: v.data, encoding: .utf8) ?? "",
                            error: error as! DecodingError
                        )
#if canImport(OSLog)
                        os_log("\(error)")
#else
                        print(error)
#endif
                        return decodingError
                    }
                    // #3 if decoding fails,
                    .tryCatch { decodingError in
                        Just(v.data)
                            // #3.1 ... decode as an `ErrorResponse`
                            .decode(type: ErrorData.self, decoder: decoder)
                                    
                            // #4 if both fail, throw APIError.decoding
                            .mapError { _ in decodingError }
                                    
                            // #3.2 ... and throw `APIError.api
                            .tryMap { throw NetworkError.lemmyError(message: $0.error, code: 200) }
                    }
            }
            .mapError { $0 as! LemmyApi.NetworkError }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
//                    print("completed")
                    break
                case let .failure(error):
                    receiveValue(nil, error)
                }
            }, receiveValue: { value in
                receiveValue(value, nil)
            })
    }
    
    private struct NoBody: Encodable, WithMethod {
        let method = "GET"
    }
    
    public func makeRequest<ResponseType: Decodable>(path: String, query: [URLQueryItem] = [], responseType: ResponseType.Type, receiveValue: @escaping (ResponseType?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: path, query: query, responseType: responseType, body: NoBody(), receiveValue: receiveValue)
    }
    
    public func getUser(name: String, page: Int, sort: LemmyApi.Sort, time: LemmyApi.TopTime, saved: Bool, receiveValue: @escaping (LemmyApi.PersonView?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        var sortString: String = sort.rawValue
        if sort == .Top {
            sortString += time.rawValue
        }
        var query = [URLQueryItem(name: "sort", value: sortString), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "username", value: name)]
        if saved {
            query.append(URLQueryItem(name: "saved_only", value: "true"))
        }
        return makeRequest(path: "user", query: query, responseType: PersonView.self, receiveValue: receiveValue)
    }
    
    public func getPost(id: Int, receiveValue: @escaping (LemmyApi.PostView?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        let query = [URLQueryItem(name: "id", value: String(id))]
        return makeRequest(path: "post", query: query, responseType: PostView.self, receiveValue: receiveValue)
    }
    
    public func getComment(id: Int, receiveValue: @escaping (LemmyApi.CommentView?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        let query = [URLQueryItem(name: "id", value: String(id))]
        return makeRequest(path: "comment", query: query, responseType: CommentView.self, receiveValue: receiveValue)
    }
    
    public func getCommunity(name: String, receiveValue: @escaping (LemmyApi.CommunityView?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        let query = [URLQueryItem(name: "name", value: name)]
        return makeRequest(path: "community", query: query, responseType: CommunityView.self, receiveValue: receiveValue)
    }
    
    public func getSiteInfo(receiveValue: @escaping (LemmyApi.SiteInfo?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequest(path: "site", query: [], responseType: SiteInfo.self, receiveValue: receiveValue)
    }
    
    public func getUnreadCount(receiveValue: @escaping (LemmyApi.UnreadCount?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequest(path: "user/unread_count", query: [], responseType: UnreadCount.self, receiveValue: receiveValue)
    }
    
    public func follow(communityId: Int, follow: Bool, receiveValue: @escaping (CommunityView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "community/follow", responseType: CommunityView.self, body: FollowPaylod(auth: jwt!, community_id: communityId, follow: follow), receiveValue: receiveValue)
    }
    
    public func register(info: RegisterPayload, receiveValue: @escaping (AuthResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "user/register", responseType: AuthResponse.self, body: info, receiveValue: receiveValue)
    }
    
    public func login(info: LoginPayload, receiveValue: @escaping (AuthResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "user/login", responseType: AuthResponse.self, body: info, receiveValue: receiveValue)
    }
    
    public func getCaptcha(receiveValue: @escaping (CaptchaResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequest(path: "user/get_captcha", responseType: CaptchaResponse.self, receiveValue: receiveValue)
    }
    
    public func readReply(replyId: Int, read: Bool, receiveValue: @escaping (CommentReplyView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment/mark_as_read", responseType: CommentReplyView.self, body: ReadPayload(auth: jwt!, comment_reply_id: replyId, private_message_id: nil, read: read), receiveValue: receiveValue)
    }
    
    public func readMessage(messageId: Int, read: Bool, receiveValue: @escaping (PrivateMessageView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "private_message/mark_as_read", responseType: PrivateMessageView.self, body: ReadPayload(auth: jwt!, comment_reply_id: nil, private_message_id: messageId, read: read), receiveValue: receiveValue)
    }
    
    public func sendMessage(to: Int, content: String, receiveValue: @escaping (PrivateMessageView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "private_message", responseType: PrivateMessageView.self, body: MessagePayload(auth: jwt!, content: content, recipient_id: to), receiveValue: receiveValue)
    }
    
    public struct ErrorData: Codable {
        public let error: String
    }
    
    public struct MessagePayload: Codable, WithMethod {
        public let method = "POST"
        public let auth: String
        public let content: String
        public let recipient_id: Int
    }
    
    public struct CommentReplyView: Codable {
        public let comment_reply_view: ApiComment
    }
    
    public struct ReadPayload: Codable, WithMethod {
        public let method = "POST"
        public let auth: String
        public let comment_reply_id: Int?
        public let private_message_id: Int?
        public let read: Bool
    }
    
    public struct Replies: Codable {
        public let replies: [ApiComment]
    }
    
    public struct ReplyInfo: Codable {
        public var read: Bool
        public let id: Int
    }
    
    public struct UnreadCount: Codable {
        public let replies: Int
        public let mentions: Int
        public let private_messages: Int
    }
    
    public struct LoginPayload: Codable, WithMethod {
        public init(username_or_email: String, password: String, totp_2fa_token: String? = nil) {
            self.username_or_email = username_or_email
            self.password = password
            self.totp_2fa_token = totp_2fa_token
        }

        public let method = "POST"
        public let username_or_email: String
        public let password: String
        public let totp_2fa_token: String?
    }
    
    public struct CaptchaResponse: Codable {
        public let ok: CaptchaInfo
    }
    
    public struct CaptchaInfo: Codable {
        public let png: String
        public let uuid: String
    }
    
    public struct RegisterPayload: Codable, WithMethod {
        public init(username: String, password: String, password_verify: String, email: String, captcha_answer: String, captcha_uuid: String) {
            self.username = username
            self.password = password
            self.password_verify = password_verify
            self.email = email
            self.captcha_answer = captcha_answer
            self.captcha_uuid = captcha_uuid
        }

        public let method = "POST"
        public let username: String
        public let password: String
        public let password_verify: String
        public let email: String
        public let captcha_answer: String
        public let captcha_uuid: String
        public let show_nsfw = false
    }
    
    public struct AuthResponse: Codable {
        public let jwt: String?
        public let registration_created: Bool?
        public let verify_email_sent: Bool?
    }
    
    public struct ErrorResponse: Codable {
        public let error: String
    }
    
    public struct FollowPaylod: Codable, WithMethod {
        public let method = "POST"
        public let auth: String
        public let community_id: Int
        public let follow: Bool
    }

    public enum NetworkError: Swift.Error {
        case network(code: Int, description: String)
        case lemmyError(message: String, code: Int)
        case decoding(message: String, error: DecodingError)
    }
    
    public struct CommentView: Codable {
        public let comment_view: ApiComment
    }
    
    public struct PersonView: Codable, Identifiable {
        public var id: Int {
            person_view.person.id
        }
        
        public let person_view: ApiUser
        public let comments: [ApiComment]?
        public let posts: [ApiPost]?
    }
    
    public struct ApiUser: Codable, Identifiable, Equatable {
        public static func == (lhs: LemmyApi.ApiUser, rhs: LemmyApi.ApiUser) -> Bool {
            lhs.id == rhs.id
        }
        
        public var id: Int {
            person.id
        }

        public let person: ApiUserData
        public let counts: ApiUserCounts
    }
    
    public struct CommunityView: Codable {
        public let community_view: ApiCommunity
    }
    
    public struct PostView: Codable {
        public let post_view: ApiPost
    }
    
    public struct ApiComment: Codable, Identifiable, Equatable, WithCounts {
        public static func == (lhs: LemmyApi.ApiComment, rhs: LemmyApi.ApiComment) -> Bool {
            lhs.id == rhs.id
        }
        
        public var id: Int { comment.id }
        
        public let comment: ApiCommentData
        public let creator: ApiUserData
        public let post: ApiPostData
        public let counts: ApiCommentCounts
        public let my_vote: Int?
        public let saved: Bool?
        public var comment_reply: ReplyInfo?
    }
    
    public struct ApiCommentData: Codable {
        public let id: Int
        public let content: String
        public let path: String
        public let ap_id: URL
        public let local: Bool
    }
    
    public struct ApiPost: Codable, Identifiable, Hashable, WithCounts {
        public init(post: LemmyApi.ApiPostData, creator: LemmyApi.ApiUserData, community: LemmyApi.ApiCommunityData, counts: LemmyApi.ApiPostCounts, my_vote: Int? = nil, saved: Bool? = nil) {
            self.post = post
            self.creator = creator
            self.community = community
            self.counts = counts
            self.my_vote = my_vote
            self.saved = saved
        }
        
        public static func == (lhs: LemmyApi.ApiPost, rhs: LemmyApi.ApiPost) -> Bool {
            lhs.id == rhs.id
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        public var id: Int { post.id }
        
        public let post: ApiPostData
        public let creator: ApiUserData
        public let community: ApiCommunityData
        public let counts: ApiPostCounts
        public let my_vote: Int?
        public let saved: Bool?
    }
    
    public struct ApiUserData: Codable, WithPublished, WithNameHost, Identifiable {
        public let name: String
        public let id: Int
        public let actor_id: URL
        public let published: Date
        public let avatar: URL?
        public let local: Bool
        
        public var icon: URL? {
            avatar
        }
    }
    
    public struct ApiCommunity: Codable, Identifiable, Equatable {
        public static func == (lhs: LemmyApi.ApiCommunity, rhs: LemmyApi.ApiCommunity) -> Bool {
            lhs.id == rhs.id
        }
        
        public var id: Int { community.id }
        public let community: ApiCommunityData
        public let subscribed: String
        public let counts: ApiCommunityCounts
        public let blocked: Bool?
    }
    
    public struct ApiCommunityCounts: Codable {
        public let published: Date
        public let subscribers: Int
    }
    
    public struct ApiCommunityData: Codable, Identifiable, WithNameHost {
        public let id: Int
        public let name: String
        public let icon: URL?
        public let actor_id: URL
        public let local: Bool
    }
    
    public struct ApiPostData: Codable {
        public let id: Int
        public let name: String
        
        public let body: String?
        public let thumbnail_url: URL?
        public let url: URL?
        public let creator_id: Int
        public let nsfw: Bool
        public let ap_id: URL
        public let local: Bool
        public let featured_community: Bool
        public let featured_local: Bool
    }
    
    public struct ApiPostCounts: Codable, WithPublished {
        public let score: Int
        public let comments: Int
        public let published: Date
    }
    
    public struct ApiCommentCounts: Codable, WithPublished {
        public let score: Int
        public let child_count: Int
        public let published: Date
    }
    
    public struct ApiUserCounts: Codable {
        public let comment_score: Int
        public let post_score: Int
        public let comment_count: Int
        public let post_count: Int
    }
    
    public struct SiteInfo: Codable {
        public let my_user: MyUser?
        public let site_view: SiteView
    }
    
    public struct SiteView: Codable {
        public let site: Site
    }
    
    public struct Site: Codable {
        public let name: String
        public let description: String?
    }
    
    public struct MyUser: Codable {
        public let follows: [Follower]
        public let local_user_view: ApiUser
    }
    
    public struct Follower: Codable {
        public let community: ApiCommunityData
    }
    
    public enum TopTime: String, CaseIterable, Codable {
        case Hour, SixHour, TwelveHour, Day, Week, Month, Year, All
    }
    
    public enum Sort: String, CaseIterable, Codable {
        case Hot, Active, New, Old, MostComments, NewComments, Top
        
        public var image: String {
            switch self {
            case .Top: return "rosette"
            case .Hot: return "flame"
            case .New: return "clock.badge"
            case .MostComments, .NewComments: return "bubble.left.and.bubble.right"
            case .Active: return "chart.bar"
            case .Old: return "clock"
            }
        }

        public var comments: Bool {
            switch self {
            case .MostComments, .NewComments, .Active: return false
            default: return true
            }
        }
        
        public var hasTime: Bool {
            switch self {
            case .Top: return true
            default: return false
            }
        }
    }
}

public protocol WithPublished {
    var published: Date { get }
}

public protocol WithCounts: Identifiable {
    associatedtype T: WithPublished
    var counts: T { get }
    var id: Int { get }
    var saved: Bool? { get }
}

public extension Publisher {
    /**
     Creates a new publisher which will upon failure retry the upstream publisher a provided number of times, with the provided delay between retry attempts.
     If the upstream publisher succeeds the first time this is bypassed and proceeds as normal.

     - Parameters:
        - retries: The number of times to retry the upstream publisher.
        - delay: Delay in seconds between retry attempts.
        - scheduler: The scheduler to dispatch the delayed events.

     - Returns: A new publisher which will retry the upstream publisher with a delay upon failure.

     let url = URL(string: "https://api.myService.com")!

     URLSession.shared.dataTaskPublisher(for: url)
         .retryWithDelay(retries: 4, delay: 5, scheduler: DispatchQueue.global())
         .sink { completion in
             switch completion {
             case .finished:
                 print("Success 😊")
             case .failure(let error):
                 print("The last and final failure after retry attempts: \(error)")
             }
         } receiveValue: { output in
             print("Received value: \(output)")
         }
         .store(in: &cancellables)
     */
    func retryWithDelay<S>(
        retries: Int,
        delay: S.SchedulerTimeType.Stride,
        scheduler: S
    ) -> AnyPublisher<Output, Failure> where S: Scheduler {
        delayIfFailure(for: delay, scheduler: scheduler) { error in
            if let error = error as? LemmyApi.NetworkError {
                switch error {
                case .lemmyError(message: _, code: let code), .network(code: let code, description: _):
                    debugPrint(code)
                    return !(code <= 0 || (code >= 400 && code < 500))
                default:
                    return true
                }
            }
            return true
        }
        .retry(times: retries) { error in
            if let error = error as? LemmyApi.NetworkError {
                switch error {
                case .lemmyError(message: _, code: let code), .network(code: let code, description: _):
                    return !(code <= 0 || (code >= 400 && code < 500))
                default:
                    return true
                }
            }
            return true
        }
        .eraseToAnyPublisher()
    }

    private func delayIfFailure<S>(
        for delay: S.SchedulerTimeType.Stride,
        scheduler: S,
        condition: @escaping (Error) -> Bool
    ) -> AnyPublisher<Output, Failure> where S: Scheduler {
        return self.catch { error in
            Future { completion in
                scheduler.schedule(after: scheduler.now.advanced(by: condition(error) ? delay : 0)) {
                    completion(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    internal func retry(times: Int, if condition: @escaping (Failure) -> Bool) -> Publishers.RetryIf<Self> {
        Publishers.RetryIf(publisher: self, times: times, condition: condition)
    }
}

extension Publishers {
    struct RetryIf<P: Publisher>: Publisher {
        typealias Output = P.Output
        typealias Failure = P.Failure
        
        let publisher: P
        let times: Int
        let condition: (P.Failure) -> Bool
                
        func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            guard times > 0 else { return publisher.receive(subscriber: subscriber) }
            
            publisher.catch { (error: P.Failure) -> AnyPublisher<Output, Failure> in
                if condition(error) {
                    return RetryIf(publisher: publisher, times: times - 1, condition: condition).eraseToAnyPublisher()
                } else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .receive(subscriber: subscriber)
        }
    }
}

public protocol WithMethod {
    var method: String { get }
}

public protocol WithNameHost {
    var actor_id: URL { get }
    var name: String { get }
    var icon: URL? { get }
    var local: Bool { get }
}
