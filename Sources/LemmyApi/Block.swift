import Foundation
import Combine

extension LemmyApi {
    func blockCommunity(id: Int, block: Bool, receiveValue: @escaping (LemmyApi.CommunityView?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "community/block", responseType: CommunityView.self, body: CommunityBlockInfo(auth: jwt!, block: block, community_id: id), receiveValue: receiveValue)
    }
    
    func blockUser(id: Int, block: Bool, receiveValue: @escaping (LemmyApi.PersonView?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequestWithBody(path: "user/block", responseType: PersonView.self, body: UserBlockInfo(auth: jwt!, block: block, person_id: id), receiveValue: receiveValue)
    }
    
    struct CommunityBlockInfo: Codable, WithMethod {
        let method = "POST"
        let auth: String
        let block: Bool
        let community_id: Int
    }
    
    struct UserBlockInfo: Codable, WithMethod {
        let method = "POST"
        let auth: String
        let block: Bool
        let person_id: Int
    }
}
