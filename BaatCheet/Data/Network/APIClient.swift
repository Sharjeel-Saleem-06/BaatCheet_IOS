//
//  APIClient.swift
//  BaatCheet
//
//  Created by BaatCheet Team
//

import Foundation

// MARK: - API Client
final class APIClient {
    // MARK: - Properties
    private let baseURL: String
    private let session: URLSession
    private let authProvider: AuthTokenProvider
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // MARK: - Init
    init(
        baseURL: String = APIConfig.baseURL,
        authProvider: AuthTokenProvider,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.authProvider = authProvider
        self.session = session
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    // MARK: - Request Methods
    
    /// Perform a GET request
    func get<T: Decodable>(
        endpoint: APIEndpoint,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = try buildRequest(
            endpoint: endpoint,
            method: .get,
            queryItems: queryItems,
            requiresAuth: requiresAuth
        )
        return try await perform(request)
    }
    
    /// Perform a POST request with JSON body
    func post<T: Decodable, B: Encodable>(
        endpoint: APIEndpoint,
        body: B,
        requiresAuth: Bool = true
    ) async throws -> T {
        var request = try buildRequest(
            endpoint: endpoint,
            method: .post,
            requiresAuth: requiresAuth
        )
        request.httpBody = try encoder.encode(body)
        request.setValue(APIConfig.contentTypeJSON, forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }
    
    /// Perform a POST request without body
    func post<T: Decodable>(
        endpoint: APIEndpoint,
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = try buildRequest(
            endpoint: endpoint,
            method: .post,
            requiresAuth: requiresAuth
        )
        return try await perform(request)
    }
    
    /// Perform a PUT request
    func put<T: Decodable, B: Encodable>(
        endpoint: APIEndpoint,
        body: B,
        requiresAuth: Bool = true
    ) async throws -> T {
        var request = try buildRequest(
            endpoint: endpoint,
            method: .put,
            requiresAuth: requiresAuth
        )
        request.httpBody = try encoder.encode(body)
        request.setValue(APIConfig.contentTypeJSON, forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }
    
    /// Perform a PATCH request
    func patch<T: Decodable, B: Encodable>(
        endpoint: APIEndpoint,
        body: B,
        requiresAuth: Bool = true
    ) async throws -> T {
        var request = try buildRequest(
            endpoint: endpoint,
            method: .patch,
            requiresAuth: requiresAuth
        )
        request.httpBody = try encoder.encode(body)
        request.setValue(APIConfig.contentTypeJSON, forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }
    
    /// Perform a DELETE request
    func delete<T: Decodable>(
        endpoint: APIEndpoint,
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = try buildRequest(
            endpoint: endpoint,
            method: .delete,
            requiresAuth: requiresAuth
        )
        return try await perform(request)
    }
    
    /// Perform a DELETE request with no response body
    func delete(
        endpoint: APIEndpoint,
        requiresAuth: Bool = true
    ) async throws {
        let request = try buildRequest(
            endpoint: endpoint,
            method: .delete,
            requiresAuth: requiresAuth
        )
        let _: EmptyResponse = try await perform(request)
    }
    
    // MARK: - Multipart Upload
    func upload<T: Decodable>(
        endpoint: APIEndpoint,
        fileData: Data,
        fileName: String,
        mimeType: String,
        fieldName: String = "file",
        additionalFields: [String: String]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        var request = try buildRequest(
            endpoint: endpoint,
            method: .post,
            requiresAuth: requiresAuth
        )
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = APIConfig.uploadTimeout
        
        var body = Data()
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add additional fields
        if let fields = additionalFields {
            for (key, value) in fields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        return try await perform(request)
    }
    
    // MARK: - Private Methods
    
    private func buildRequest(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool
    ) throws -> URLRequest {
        var components = URLComponents(url: endpoint.url, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = APIConfig.defaultTimeout
        
        // Add auth header if required
        if requiresAuth, let token = authProvider.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        #if DEBUG
        logRequest(request)
        #endif
        
        let (data, response) = try await session.data(for: request)
        
        #if DEBUG
        logResponse(response, data: data)
        #endif
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("Decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw response: \(jsonString)")
                }
                #endif
                throw APIError.decodingError(error)
            }
            
        case 401:
            throw APIError.unauthorized
            
        case 403:
            throw APIError.forbidden
            
        case 404:
            throw APIError.notFound
            
        case 429:
            throw APIError.rateLimited
            
        case 500...599:
            let errorMessage = parseErrorMessage(from: data)
            throw APIError.serverError(httpResponse.statusCode, errorMessage)
            
        default:
            let errorMessage = parseErrorMessage(from: data)
            throw APIError.httpError(httpResponse.statusCode, errorMessage)
        }
    }
    
    private func parseErrorMessage(from data: Data) -> String {
        if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
            return errorResponse.error ?? errorResponse.message ?? "Unknown error"
        }
        return "Unknown error"
    }
    
    // MARK: - Logging
    #if DEBUG
    private func logRequest(_ request: URLRequest) {
        print("🌐 API Request: \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("📤 Body: \(bodyString.prefix(500))")
        }
    }
    
    private func logResponse(_ response: URLResponse, data: Data) {
        if let httpResponse = response as? HTTPURLResponse {
            let emoji = (200...299).contains(httpResponse.statusCode) ? "✅" : "❌"
            print("\(emoji) Response: \(httpResponse.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 Data: \(jsonString.prefix(500))")
            }
        }
    }
    #endif
}

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serverError(Int, String)
    case httpError(Int, String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .unauthorized:
            return "Please sign in again"
        case .forbidden:
            return "You don't have permission to perform this action"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError(_, let message):
            return message
        case .httpError(_, let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Response Types
struct ErrorResponse: Decodable {
    let success: Bool?
    let error: String?
    let message: String?
}

struct EmptyResponse: Decodable {}

struct SuccessResponse: Decodable {
    let success: Bool
    let message: String?
}
