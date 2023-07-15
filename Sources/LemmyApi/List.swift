import Combine
import Foundation

extension LemmyApi {
    func getPosts(path: String, page: Int, sort: LemmyApi.Sort, time: LemmyApi.TopTime, receiveValue: @escaping (LemmyApi.ApiPosts?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        var sortString: String = sort.rawValue
        if sort == .Top {
            sortString += time.rawValue
        }
        var query = [URLQueryItem(name: "sort", value: sortString), URLQueryItem(name: "page", value: String(page))]
        if path == "Subscribed" {
            if self.jwt != nil {
                query.append(URLQueryItem(name: "type_", value: "Subscribed"))
            }
        } else if path == "All" {
            query.append(URLQueryItem(name: "type_", value: "All"))
        } else if path != "Local" && path != "" {
            query.append(URLQueryItem(name: "community_name", value: path))
        }
        return makeRequest(path: "post/list", query: query, responseType: ApiPosts.self, receiveValue: receiveValue)
    }

    func getComments(postId: Int, parentId: Int? = nil, sort: LemmyApi.Sort, receiveValue: @escaping (LemmyApi.ApiComments?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        var query = [URLQueryItem(name: "sort", value: sort.rawValue), URLQueryItem(name: "post_id", value: String(postId)), URLQueryItem(name: "max_depth", value: "8"), URLQueryItem(name: "type_", value: "All")]
        if let parentId = parentId {
            query.append(URLQueryItem(name: "parent_id", value: String(parentId)))
        }
        return makeRequest(path: "comment/list", query: query, responseType: ApiComments.self, receiveValue: receiveValue)
    }
    
    func getReplies(page: Int, sort: Sort, unread: Bool, receiveValue: @escaping (LemmyApi.Replies?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        let query = [URLQueryItem(name: "sort", value: sort.rawValue), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "unread_only", value: String(unread))]
        return makeRequest(path: "user/replies", query: query, responseType: Replies.self, receiveValue: receiveValue)
    }
    
    func getMessages(page: Int, sort: Sort, unread: Bool, receiveValue: @escaping (LemmyApi.Messages?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        let query = [URLQueryItem(name: "sort", value: sort.rawValue), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "unread_only", value: String(unread))]
        return makeRequest(path: "private_message/list", query: query, responseType: Messages.self, receiveValue: receiveValue)
    }
    
    func getCommunities(page: Int, sort: LemmyApi.Sort, time: LemmyApi.TopTime, limit: Int = 10, receiveValue: @escaping (LemmyApi.ApiCommunities?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        var sortString: String = sort.rawValue
        if sort == .Top {
            sortString += time.rawValue
        }
        let query = [URLQueryItem(name: "sort", value: sortString), URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: String(limit))]
        return makeRequest(path: "community/list", query: query, responseType: ApiCommunities.self, receiveValue: receiveValue)
    }
    
    struct PrivateMessageView: Codable {
        let private_message_view: Message
    }

    struct ApiComments: Codable {
        let comments: [ApiComment]
    }
    
    struct ApiPosts: Codable {
        let posts: [ApiPost]
    }
    
    struct ApiCommunities: Codable {
        let communities: [ApiCommunity]
    }
    
    struct ApiUsers: Codable {
        let users: [ApiUser]
    }
    
    struct Messages: Codable {
        let private_messages: [Message]
    }
    
    struct Message: Codable {
        var id: Int {
            private_message.id
        }
        let creator: ApiUserData
        var private_message: MessageContent
    }
    
    struct MessageContent: Codable, WithPublished {
        let content: String
        let published: Date
        var read: Bool
        let id: Int
    }
}
