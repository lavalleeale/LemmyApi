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
        public let person: ApiUser
    }
    struct PostResolveResponse: ResolveResponse {
        public let post: ApiPost
    }
    struct CommetResolveResponse: ResolveResponse {
        public let comment: ApiComment
    }
    struct CommunityResolveResponse: ResolveResponse {
        
        public let community: ApiCommunity
    }
    struct UnknownResolveError: Error {
        
    }
}

public protocol ResolveResponse: Decodable, Equatable {
}
