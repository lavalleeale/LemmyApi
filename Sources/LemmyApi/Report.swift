import Foundation

#if canImport(Combine)
import Combine
#else
import CombineX
#endif
import Foundation

public extension LemmyApi {
    func reportComment(commentId: Int, reason: String, receiveValue: @escaping (CommentReportResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment/report", responseType: CommentReportResponse.self, body: CreateCommentReport(auth: jwt!, comment_id: commentId, reason: reason), receiveValue: receiveValue)
    }
    
    func reportPost(postId: Int, reason: String, receiveValue: @escaping (PostReportResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/report", responseType: PostReportResponse.self, body: CreatePostReport(auth: jwt!, post_id: postId, reason: reason), receiveValue: receiveValue)
    }
    
    func updatePostReport(reportId: Int, resolved: Bool, receiveValue: @escaping (PostReportResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "post/report/resolve", responseType: PostReportResponse.self, body: ResolveReport(report_id: reportId, resolved: resolved, auth: jwt!), receiveValue: receiveValue)
    }
    
    func updateCommentReport(reportId: Int, resolved: Bool, receiveValue: @escaping (CommentReportResponse?, NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "comment/report/resolve", responseType: CommentReportResponse.self, body: ResolveReport(report_id: reportId, resolved: resolved, auth: jwt!), receiveValue: receiveValue)
    }
    
    struct ResolveReport: Codable, WithMethod {
        public let method = "PUT"
        public let report_id: Int
        public let resolved: Bool
        public let auth: String
    }

    struct PostReportResponse: Codable {
        public let post_report_view: PostReportView
    }
    
    struct CreatePostReport: Codable, WithMethod {
        public let method = "POST"
        public let auth: String
        public let post_id: Int
        public let reason: String
    }

    struct CommentReportResponse: Codable {
        public let comment_report_view: CommentReportView
    }

    struct CreateCommentReport: Codable, WithMethod {
        public let method = "POST"
        public let auth: String
        public let comment_id: Int
        public let reason: String
    }
    
    struct PostReportView: Codable, Identifiable, ReportView {
        public var id: String { "post_report_\(post_report.id)" }
        public var published: Date { post_report.published }
        public var reporter: Person { creator }
        public var reason: String { post_report.reason }
        public var resolved: Bool {post_report.resolved}
        
        public let post_report: PostReport
        public let post: Post
        public let community: Community
        public let creator: Person
        public let post_creator: Person
        public let creator_banned_from_community: Bool
        public let my_vote: Int?
        public let counts: PostAggregates
        public let resolver: Person?
        
        public var postView: PostView {
            PostView(post: post, creator: post_creator, community: community, counts: counts, my_vote: my_vote, creator_banned_from_community: creator_banned_from_community)
        }
    }
    
    struct CommentReportView: Codable, Identifiable, ReportView {
        public var id: String { "comment_report_\(comment_report.id)" }
        public var published: Date { comment_report.published }
        public var reporter: Person { creator }
        public var reason: String { comment_report.reason }
        public var resolved: Bool {comment_report.resolved}
        
        public let comment_report: CommentReport
        public let comment: Comment
        public let post: Post
        public let community: Community
        public let creator: Person
        public let comment_creator: Person
        public let counts: CommentAggregates
        public let creator_banned_from_community: Bool
        public let my_vote: Int?
        public let resolver: Person?
        
        public var commentView: CommentView {
            CommentView(comment: comment, creator: comment_creator, post: post, counts: counts, community: community, my_vote: my_vote, saved: false, creator_banned_from_community: creator_banned_from_community)
        }
    }
    
    struct PostReport: Codable {
        public let id: Int
        public let creator_id: Int
        public let post_id: Int
        public let original_post_name: String
        public let original_post_url: String?
        public let original_post_body: String?
        public let reason: String
        public let resolved: Bool
        public let resolver_id: Int?
        public let published: Date
        public let updated: Date?
    }
    
    struct CommentReport: Codable {
        public let id: Int
        public let creator_id: Int
        public let comment_id: Int
        public let original_comment_text: String
        public let reason: String
        public let resolved: Bool
        public let resolver_id: Int?
        public let published: Date
        public let updated: Date?
    }
}

public protocol ReportView {
    var id: String { get }
    var published: Date { get }
    var reporter: LemmyApi.Person { get }
    var reason: String { get }
    var resolver: LemmyApi.Person? { get }
    var resolved: Bool { get }
}
