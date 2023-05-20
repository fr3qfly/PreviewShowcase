//
//  File.swift
//  
//
//  Created by Balázs Szamódy on 20/5/2023.
//

import Foundation

enum MockFile: String, Mockable {
    case inputFile_EmptyStack
    
    var fileName: String {
        rawValue
    }
    
    var `extension`: String {
        "txt"
    }
    
    var bundle: Bundle {
        Bundle.module
    }
}

enum MockableError: LocalizedError {
    case urlNotFound
    case badStringEncoding(String.Encoding)
    
    var errorDescription: String? {
        String(describing: self)
    }
}

protocol Mockable {
    var fileName: String { get }
    var `extension`: String { get }
    var bundle: Bundle { get }
}

extension Mockable {
    func data() throws -> Data {
        guard let url = bundle.url(forResource: fileName, withExtension: self.extension) else {
            throw MockableError.urlNotFound
        }
        
        return try Data(contentsOf: url)
    }
    
    func getMock<T>(_ type: T.Type? = nil, decoder: JSONDecoder = JSONDecoder()) throws -> T where T: Codable {
        try decoder.decode(T.self, from: data())
    }
    
    func getMock(_ encoding: String.Encoding = .utf8) throws -> String {
        guard let string = try String(data: data(), encoding: encoding) else {
            throw MockableError.badStringEncoding(encoding)
        }
        
        return string
    }
}
