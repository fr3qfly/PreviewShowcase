//
//  StackIndentTests.swift
//  
//
//  Created by Balázs Szamódy on 20/5/2023.
//

import XCTest
@testable import PreviewShowcaseUpdater

final class StackIndentTests: XCTestCase {
    var sut: PreviewShowcaseUpdater!

    override func setUpWithError() throws {
        sut = PreviewShowcaseUpdater()
    }

    func testGetMainVStackIndent_Spaces() throws {
        // Given
        let inputContent = try MockFile.inputFile_EmptyStack.getMockText()
        
        // When
        let indent = try sut.getMainVStackIndent(inputContent)
        
        // Then
        XCTAssertEqual(indent, "            ")
    }
    
    func testGetMainStackIndent_Tabs() throws {
        // Given
        let inputContent = try MockFile.inputFile_ExistingPreviews.getMockText()
        
        // When
        let indent = try sut.getMainVStackIndent(inputContent)
        
        // Then
        XCTAssertEqual(indent, "\t\t\t")
    }

}
