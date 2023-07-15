import Foundation
import Combine

public extension LemmyApi {
    func savePost(save: Bool, post_id: Int, receiveValue: @escaping (LemmyApi.PostView?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/save", query: [], responseType: PostView.self, body: PostSave(auth: jwt!, post_id: post_id, save: save), receiveValue: receiveValue)
    }
    
    struct PostSave: Codable, WithMethod {
        public let method = "PUT"
        public let auth: String
        public let post_id: Int
        public let save: Bool
    }
}
