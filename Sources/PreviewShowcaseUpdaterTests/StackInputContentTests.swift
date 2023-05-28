//
//  StackInputContentTests.swift
//  
//
//  Created by Balázs Szamódy on 20/5/2023.
//

import XCTest
@testable import PreviewShowcaseUpdater

final class StackInputContentTests: XCTestCase {
    var sut: PreviewShowcaseUpdater!

    override func setUpWithError() throws {
        sut = PreviewShowcaseUpdater()
    }

    func testGetStackContent_EmptyStack() throws {
        // Given
        let inputContent = try MockFile.inputFile_EmptyStack.getMockText()
        let indent = try sut.getMainVStackIndent(inputContent)
        
        // When
        let stackContent = try sut.getStackContent(from: inputContent, closingIndent: indent)
        
        // Then
        XCTAssertEqual(stackContent, "")
    }
    
    func testGetStackContent_ExistingContent() throws {
        // Given
        let inputContent = try MockFile.inputFile_ExistingPreviews.getMockText()
        let indent = try sut.getMainVStackIndent(inputContent)
        let expectedContent = """
            \t\t\t\tGroup {
            \t\t\t\t\tMyView_Previews.previews
            \t\t\t\t\tMyView2_Previews.previews
            \t\t\t\t\tContentView_Previews.previews
            \t\t\t\t\tOtherView.previews
            \t\t\t\t}
            
            """
        
        // When
        let stackContent = try sut.getStackContent(from: inputContent, closingIndent: indent)
        
        // Then
        XCTAssertEqual(stackContent, expectedContent)
    }

}
