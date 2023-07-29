import Foundation
#if canImport(Combine)
import Combine
#else
import CombineX
#endif

public extension LemmyApi {
    func savePost(save: Bool, post_id: Int, receiveValue: @escaping (LemmyApi.GetPostResponse?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/save", query: [], responseType: GetPostResponse.self, body: PostSave(auth: jwt!, post_id: post_id, save: save), receiveValue: receiveValue)
    }
    
    struct PostSave: Codable, WithMethod {
        public let method = "PUT"
        public let auth: String
        public let post_id: Int
        public let save: Bool
    }
}
