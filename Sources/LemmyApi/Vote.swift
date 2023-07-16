import CXShim
#if canImport(Combine)
import Combine
#else
import CombineX
#endif

public extension LemmyApi {
    func voteComment(id: Int, target: Int, receiveValue: @escaping (CommentView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment/like", responseType: CommentView.self, body: CommentVote(auth: jwt!, comment_id: id, score: target), receiveValue: receiveValue)
    }

    func votePost(id: Int, target: Int, receiveValue: @escaping (PostView?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/like", responseType: PostView.self, body: PostVote(auth: jwt!, post_id: id, score: target), receiveValue: receiveValue)
    }
    
    struct CommentVote: Codable, WithMethod {
        public let method = "POST"
        public let auth: String
        public let comment_id: Int
        public let score: Int
    }
    
    struct PostVote: Codable, WithMethod {
        public let method = "POST"
        public let auth: String
        public let post_id: Int
        public let score: Int
    }
}
