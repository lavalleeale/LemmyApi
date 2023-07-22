import Foundation
#if canImport(Combine)
import Combine
#else
import CombineX
#endif

public extension LemmyApi {
    func resolveObject<T: Codable>(ap_id: URL, receiveValue: @escaping (T?, LemmyApi.NetworkError?) -> Void) -> AnyCancellable {
        return makeRequest(path: "resolve_object", query: [URLQueryItem(name: "q", value: ap_id.absoluteString)], responseType: T.self, receiveValue: receiveValue)
    }

    struct UnknownResolveError: Error {}
}
