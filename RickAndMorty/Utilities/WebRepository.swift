//
//  WebRepository.swift
//  RickAndMorty
//
//  Created by Daniel Parra Martin on 29/7/23.
//

import Foundation
import Combine

protocol WebRepository {
    var session: URLSession { get }
    var baseURL: String { get }
    var bgQueue: DispatchQueue { get }
}

extension WebRepository {
    func call<Value>(endpoint: APICall, httpCodes: HTTPCodes = .success, page: Int) -> AnyPublisher<Value, Error>
    where Value: Decodable {
        do {
            let request = try endpoint.urlRequest(baseURL: baseURL, add: String(page))
            return session
                .dataTaskPublisher(for: request)
                .requestJSON(httpCodes: httpCodes)
                .ensureTimeSpan(0.5)
        } catch let error {
            return Fail<Value, Error>(error: error).eraseToAnyPublisher()
        }
    }
    
    func call<Value>(endpoint: APICall, httpCodes: HTTPCodes = .success, name: String) -> AnyPublisher<Value, Error>
    where Value: Decodable {
        do {
            let request = try endpoint.urlRequest(baseURL: baseURL, add: name)
            return session
                .dataTaskPublisher(for: request)
                .requestJSON(httpCodes: httpCodes)
                .ensureTimeSpan(0.5)
        } catch let error {
            return Fail<Value, Error>(error: error).eraseToAnyPublisher()
        }
    }
    
}

// MARK: - Helpers

private extension Publisher where Output == URLSession.DataTaskPublisher.Output {
    func requestJSON<Value>(httpCodes: HTTPCodes) -> AnyPublisher<Value, Error> where Value: Decodable {
        return tryMap {
            assert(!Thread.isMainThread)
            guard let code = ($0.1 as? HTTPURLResponse)?.statusCode else {
                throw APIError.unexpectedResponse
            }
            guard httpCodes.contains(code) else {
                throw APIError.httpCode(code)
            }
            return $0.0
        }
        .extractUnderlyingError()
        .decode(type: Value.self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}


