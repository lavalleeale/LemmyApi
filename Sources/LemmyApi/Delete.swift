import Foundation
#if canImport(Combine)
import CXShim
#else
import CombineX
#endif

public extension LemmyApi {
    func deleteComment(id: Int, deleted: Bool, receiveValue: @escaping (LemmyApi.CommentResponse?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment/delete", responseType: CommentResponse.self, body: DeleteCommentPayload(auth: jwt!, comment_id: id, deleted: deleted), receiveValue: receiveValue)
    }
    
    func removeComment(id: Int, removed: Bool, receiveValue: @escaping (LemmyApi.CommentResponse?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment/remove", responseType: CommentResponse.self, body: RemoveCommentPayload(auth: jwt!, comment_id: id, removed: removed), receiveValue: receiveValue)
    }
    
    func deletePost(id: Int, deleted: Bool, receiveValue: @escaping (LemmyApi.GetPostResponse?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/delete", responseType: GetPostResponse.self, body: DeletePostPayload(auth: jwt!, post_id: id, deleted: deleted), receiveValue: receiveValue)
    }
    
    func removePost(id: Int, removed: Bool, receiveValue: @escaping (LemmyApi.GetPostResponse?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/remove", responseType: GetPostResponse.self, body: RemovePostPayload(auth: jwt!, post_id: id, removed: removed), receiveValue: receiveValue)
    }
    
    func deleteAccount(password: String, receiveValue: @escaping (LemmyApi.DeleteAccountResponse?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "user/delete_account", responseType: DeleteAccountResponse.self, body: DeleteAccountPayload(password: password, auth: jwt!), receiveValue: receiveValue)
    }
    
    func banUser(userId: Int, communityId: Int, ban: Bool, reason: String, remove: Bool, expires: Int?, receiveValue: @escaping (LemmyApi.PersonView?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "community/ban_user", responseType: PersonView.self, body: BanUserPayload(auth: jwt!, ban: ban, community_id: communityId, person_id: userId, reason: reason, remove_data: remove, expires: expires), receiveValue: receiveValue)
    }

    struct BanUserPayload: WithMethod, Codable {
        public let method = "POST"
        let auth: String
        let ban: Bool
        let community_id: Int
        let person_id: Int
        let reason: String
        let remove_data: Bool
        let expires: Int?
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
    
    struct DeleteAccountResponse: Codable {}
    
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
    
    struct RemoveCommentPayload: WithMethod, Codable {
        public init(auth: String, comment_id: Int, removed: Bool) {
            self.auth = auth
            self.comment_id = comment_id
            self.removed = removed
        }
        
        public let method = "POST"
        public let auth: String
        public let comment_id: Int
        public let removed: Bool
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
    
    struct RemovePostPayload: WithMethod, Codable {
        public init(auth: String, post_id: Int, removed: Bool) {
            self.auth = auth
            self.post_id = post_id
            self.removed = removed
        }
        
        public let method = "POST"
        public let auth: String
        public let post_id: Int
        public let removed: Bool
    }
}
