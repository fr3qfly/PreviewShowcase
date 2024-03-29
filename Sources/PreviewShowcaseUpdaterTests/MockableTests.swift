//
//  MockableTests.swift
//  
//
//  Created by Balázs Szamódy on 20/5/2023.
//

import XCTest

final class MockableTests: XCTestCase {

    func testGetMock_String() {
        do {
            let mockString = try MockFile.inputFile_EmptyStack.getMockText()
            
            XCTAssertTrue(mockString.contains("LazyVStack"))
        } catch let error as LocalizedError {
            XCTFail(error.errorDescription ?? "Unknown error")
        } catch {
            XCTFail(String(describing: error))
        }
    }

}
