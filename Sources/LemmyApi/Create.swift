#if canImport(Combine)
import CXShim
#else
import CombineX
#endif
import Foundation

public extension LemmyApi {
    func createPost(title: String, content: String, url: String, communityId: Int, receiveValue: @escaping (GetPostResponse?, NetworkError?) -> Void) -> AnyCancellable {
        let body = SentPost(auth: self.jwt!, community_id: communityId, name: title, url: url == "" ? nil : url, body: content)
        return makeRequestWithBody(path: "post", responseType: GetPostResponse.self, body: body, receiveValue: receiveValue)
    }
    
    func addComment(content: String, postId: Int, parentId: Int?, receiveValue: @escaping (CommentResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment", responseType: CommentResponse.self, body: SentComment(auth: jwt!, content: content, parent_id: parentId, post_id: postId), receiveValue: receiveValue)
    }
    
    func editComment(content: String, commentId: Int, receiveValue: @escaping (CommentResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment", responseType: CommentResponse.self, body: EditedComment(auth: jwt!, content: content, comment_id: commentId), receiveValue: receiveValue)
    }
    
    func editPost(title: String, content: String, url: String, postId: Int, receiveValue: @escaping (GetPostResponse?, NetworkError?) -> Void) -> AnyCancellable {
        let body = EditedPost(post_id: postId, auth: self.jwt!, name: title, url: url == "" ? nil : url, body: content)
        return makeRequestWithBody(path: "post", responseType: GetPostResponse.self, body: body, receiveValue: receiveValue)
    }
    
    struct EditedPost: Codable, WithMethod {
        public let method = "PUT"
        public let post_id: Int
        public let auth: String
        public let name: String
        public let url: String?
        public let body: String?
    }
    
    struct SentPost: Codable, WithMethod {
        public let method = "POST"
        public let auth: String
        public let community_id: Int
        public let name: String
        public let url: String?
        public let body: String?
    }
    
    struct SentComment: Codable, WithMethod {
        public let method = "POST"
        public let auth: String
        public let content: String
        public let parent_id: Int?
        public let post_id: Int
    }
    
    struct EditedComment: Codable, WithMethod {
        public let method = "PUT"
        public let auth: String
        public let content: String
        public let comment_id: Int
    }
}
