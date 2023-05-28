//
//  ExistingPreviewTests.swift
//  
//
//  Created by Balázs Szamódy on 21/5/2023.
//

import XCTest
@testable import PreviewShowcaseUpdater

final class ExistingPreviewTests: XCTestCase {
    var sut: PreviewShowcaseUpdater!

    override func setUpWithError() throws {
        sut = PreviewShowcaseUpdater()
    }
    
    func testGetExistingPreviewStructNames_EmptyContent() throws {
        // Given
        let inputContent = try MockFile.inputFile_EmptyStack.getMockText()
        let indent = try sut.getMainVStackIndent(inputContent)
        let stackContent = try sut.getStackContent(from: inputContent, closingIndent: indent)
        
        // When
        let existingPreviewNames = try sut.getExistingPreviewStructNames(from: stackContent)
        
        // Then
        XCTAssertEqual(existingPreviewNames, [])
    }

    func testGetExistingPreviewStructNames_ExistingContent() throws {
        // Given
        let inputContent = try MockFile.inputFile_ExistingPreviews.getMockText()
        let indent = try sut.getMainVStackIndent(inputContent)
        let stackContent = try sut.getStackContent(from: inputContent, closingIndent: indent)
        let expectedResult = [
            "MyView_Previews",
            "MyView2_Previews",
            "ContentView_Previews",
            "OtherView"
        ]
        
        // When
        let existingPreviewNames = try sut.getExistingPreviewStructNames(from: stackContent)
        
        // Then
        XCTAssertEqual(existingPreviewNames, expectedResult)
    }

}
