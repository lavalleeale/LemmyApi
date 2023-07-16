import Foundation

import CXShim
import Foundation

public extension LemmyApi {
    func reportComment(commentId: Int, reason: String, receiveValue: @escaping (CommentReportResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment/report", responseType: CommentReportResponse.self, body: CommentReport(auth: jwt!, comment_id: commentId, reason: reason), receiveValue: receiveValue)
    }
    
    func reportPost(postId: Int, reason: String, receiveValue: @escaping (PostReportResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/report", responseType: PostReportResponse.self, body: PostReport(auth: jwt!, post_id: postId, reason: reason), receiveValue: receiveValue)
    }

    struct PostReportResponse: Codable {
        public let post_report_view: ApiPost
    }
    
    struct PostReport: Codable, WithMethod {
        public let method = "POST"
        public let auth: String
        public let post_id: Int
        public let reason: String
    }

    struct CommentReportResponse: Codable {
        public let comment_report_view: ApiComment
    }

    struct CommentReport: Codable, WithMethod {
        public let method = "POST"
        public let auth: String
        public let comment_id: Int
        public let reason: String
    }
}
