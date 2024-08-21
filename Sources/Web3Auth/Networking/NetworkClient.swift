import Foundation

enum Router: NetworkManagerProtocol {
    case get([URLQueryItem])
    case set(T: Encodable)
    case getRegistrationOptions(T: Encodable)
    case verifyRegistration(T: Encodable)
    case getAuthenticationOptions(T: Encodable)
    case verifyAuthentication(T: Encodable)

    var path: String {
        switch self {
        case .get:
            return "/api/configuration"
        case .set:
            return "/api/configuration"
        case .getRegistrationOptions:
            return "/api/v3/auth/passkey/fast/register/options"
        case .verifyRegistration:
            return "/api/v3/auth/passkey/fast/register/verify"
        case .getAuthenticationOptions:
            return "/api/v3/auth/passkey/fast/authenticate/options"
        case .verifyAuthentication:
            return "/api/v3/auth/passkey/fast/authenticate/verify"
        }
    }

    static var baseURL: String = ""

    var httpMethod: HTTPMethod {
        switch self {
        case let .get(params):
            return .get(params)
        case let .set(params):
            return .post(T: params)
        case let .getRegistrationOptions(params):
            return .post(T: params)
        case let .verifyRegistration(params):
            return .post(T: params)
        case let .getAuthenticationOptions(params):
            return .post(T: params)
        case let .verifyAuthentication(params):
            return .post(T: params)
        }
    }

    var headers: [String: String] {
        switch self {
        case .get, .set, .getRegistrationOptions, .verifyRegistration, .getAuthenticationOptions, .verifyAuthentication:
            return ["Content-Type": "application/json"]
        }
    }
}

class Service {
    static func request(router: Router) async -> Result<Data, Error> {
        do {
            guard let url = URL(string: "\(Router.baseURL + router.path)") else { throw NetworkingError.invalidURL }
            var request = URLRequest(url: url)
            request.httpMethod = router.httpMethod.name
            request.allHTTPHeaderFields = router.headers
            switch router.httpMethod {
            case let .get(params):
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.queryItems = params
                guard let url = components?.url else { throw NetworkingError.invalidURL }
                request = URLRequest(url: url)
            case let .post(data):
                let data = try JSONEncoder().encode(data)
                request.httpBody = data
            }
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode <= 299 else { throw NetworkingError.invalidResponse }
            return .success(data)
        } catch let error {
            return .failure(error)
        }
    }
}
