import Foundation
#if canImport(Combine)
import Combine
#else
import CombineX
#endif

public extension LemmyApi {
    func resolveObject<T: ResolveResponse>(ap_id: URL, receiveValue: @escaping (T?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequest(path: "resolve_object", query: [URLQueryItem(name: "q", value: ap_id.absoluteString)], responseType: T.self, receiveValue: receiveValue)
    }

    struct PersonResolveResponse: ResolveResponse {
        public typealias returnResponse = PersonView

        public let person: ApiUser
        
        public var child: ApiUser {
            person
        }

        public static func getLocal(id: String, lemmyApi: LemmyApi, receiveValue: @escaping (returnResponse?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
            return lemmyApi.getUser(name: id, page: 1, sort: .New, time: .All, saved: false, receiveValue: receiveValue)
        }
    }

    struct PostResolveResponse: ResolveResponse {
        public typealias returnResponse = PostView

        public let post: ApiPost
        
        public var child: ApiPost {
            post
        }

        public static func getLocal(id: String, lemmyApi: LemmyApi, receiveValue: @escaping (returnResponse?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
            return lemmyApi.getPost(id: Int(id)!, receiveValue: receiveValue)
        }
    }

    struct CommentResolveResponse: ResolveResponse {
        public typealias returnResponse = CommentView
        public let comment: ApiComment
        
        public var child: ApiComment {
            comment
        }

        public static func getLocal(id: String, lemmyApi: LemmyApi, receiveValue: @escaping (LemmyApi.CommentView?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
            return lemmyApi.getComment(id: Int(id)!, receiveValue: receiveValue)
        }
    }

    struct CommunityResolveResponse: ResolveResponse {
        public typealias returnResponse = CommunityView
        public let community: ApiCommunity
        
        public var child: ApiCommunity {
            community
        }

        public static func getLocal(id: String, lemmyApi: LemmyApi, receiveValue: @escaping (returnResponse?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
            return lemmyApi.getCommunity(name: id, receiveValue: receiveValue)
        }
    }

    struct UnknownResolveError: Error {}
}

public protocol ResolveResponse: Decodable, Equatable {
    associatedtype returnResponse: withWrapped
    typealias childType = returnResponse.bodyType
    var child: childType { get }
    static func getLocal(id: String, lemmyApi: LemmyApi, receiveValue: @escaping (returnResponse?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable
}

public protocol withWrapped {
    associatedtype bodyType: Equatable, Codable
    var body: bodyType { get }
}
