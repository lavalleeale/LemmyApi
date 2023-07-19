import Foundation
#if canImport(Combine)
import CXShim
#else
import CombineX
#endif

public extension LemmyApi {
    func deleteComment(id: Int, deleted: Bool, receiveValue: @escaping (LemmyApi.CommentView?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment/delete", responseType: CommentView.self, body: DeleteCommentPayload(auth: jwt!, comment_id: id, deleted: deleted), receiveValue: receiveValue)
    }
    
    func deletePost(id: Int, deleted: Bool, receiveValue: @escaping (LemmyApi.PostView?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/delete", responseType: PostView.self, body: DeletePostPayload(auth: jwt!, post_id: id, deleted: deleted), receiveValue: receiveValue)
    }
    
    func deleteAccount(password: String, receiveValue: @escaping (LemmyApi.DeleteAccountResponse?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "user/delete_account", responseType: DeleteAccountResponse.self, body:DeleteAccountPayload(password: password, auth: jwt!), receiveValue: receiveValue)
    }
    
    struct DeleteAccountPayload: WithMethod, Codable {
        public init(password: String, auth: String) {
            self.password = password
            self.auth = auth
        }
        
        public let method = "POST"
        public let password: String
        public let auth: String
    }
    
    struct DeleteAccountResponse: Codable {
        
    }
    
    struct DeleteCommentPayload: WithMethod, Codable {
        public init(auth: String, comment_id: Int, deleted: Bool) {
            self.auth = auth
            self.comment_id = comment_id
            self.deleted = deleted
        }
        
        public let method = "POST"
        public let auth: String
        public let comment_id: Int
        public let deleted: Bool
    }
    struct DeletePostPayload: WithMethod, Codable {
        public init(auth: String, post_id: Int, deleted: Bool) {
            self.auth = auth
            self.post_id = post_id
            self.deleted = deleted
        }
        
        public let method = "POST"
        public let auth: String
        public let post_id: Int
        public let deleted: Bool
    }
}
