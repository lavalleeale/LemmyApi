import Foundation
#if canImport(Combine)
import Combine
#else
import CombineX
#endif

public extension LemmyApi {
    func getModlog(communityId: Int, page: Int, receiveValue: @escaping (LemmyApi.ModLog?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequest(path: "modlog", query: [URLQueryItem(name: "community_id", value: String(communityId)), URLQueryItem(name: "page", value: String(page))], responseType: ModLog.self, receiveValue: receiveValue)
    }
    
    struct ModLog: Codable {
      public let removed_posts: [ModRemovePostView]
//      public let locked_posts: [ModLockPostView]
//      public let featured_posts: [ModFeaturePostView]
      public let removed_comments: [ModRemoveCommentView]
//      public let removed_communities: [ModRemoveCommunityView]
      public let banned_from_community: [ModBanFromCommunityView]
//      public let banned: [ModBanView]
//      public let added_to_community: [ModAddCommunityView]
//      public let transferred_to_community: [ModTransferCommunityView]
//      public let added: [ModAddView]
//      public let admin_purged_persons: [AdminPurgePersonView]
//      public let admin_purged_communities: [AdminPurgeCommunityView]
//      public let admin_purged_posts: [AdminPurgePostView]
//      public let admin_purged_comments: [AdminPurgeCommentView]
//      public let hidden_communities: [ModHideCommunityView]
    }
    
    struct ModBanFromCommunityView: ModLogEntry {
        public var id: String {
            "mod_ban_from_community\(mod_ban_from_community.id)"
        }
        
        public var date: Date {
            mod_ban_from_community.when_
        }

        public let mod_ban_from_community: ModBanFromCommunity
        public let moderator: Person?
        public let community: Community
        public let banned_person: Person
    }
    
    struct ModBanFromCommunity: Codable {
        public let id: Int
        public let mod_person_id: Int
        public let other_person_id: Int
        public let community_id: Int
        public let reason: String?
        public let banned: Bool
        public let expires: Date?
        public let when_: Date
    }
    
    struct ModRemovePostView: ModLogEntry {
        public var id: String {
            "mod_remove_post\(mod_remove_post.id)"
        }
        
        public var date: Date {
            mod_remove_post.when_
        }

        public let mod_remove_post: ModRemovePost
        public let moderator: Person?
        public let post: Post
        public let community: Community
    }
    
    struct ModRemovePost: Codable {
        public let id: Int
        public let mod_person_id: Int
        public let post_id: Int
        public let reason: String?
        public let removed: Bool
        public let when_: Date
    }
    
    struct ModRemoveCommentView: ModLogEntry {
        public var id: String {
            "mod_remove_comment\(mod_remove_comment.id)"
        }
        
        public var date: Date {
            mod_remove_comment.when_
        }
        
        public let mod_remove_comment: ModRemoveComment
        public let moderator: Person?
        public let comment: Comment
        public let commenter: Person
        public let post: Post
        public let community: Community
    }
    
    struct ModRemoveComment: Codable {
        public let id: Int
        public let mod_person_id: Int
        public let comment_id: Int
        public let reason: String?
        public let removed: Bool
        public let when_: Date
    }
}

public protocol ModLogEntry: Codable, Identifiable {
    var id: String { get }
    var moderator: LemmyApi.Person? { get }
    var date: Date { get }
}
