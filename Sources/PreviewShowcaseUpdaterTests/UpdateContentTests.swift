//
//  UpdateContentTests.swift
//  
//
//  Created by Balázs Szamódy on 28/5/2023.
//

import XCTest
@testable import PreviewShowcaseUpdater

final class UpdateContentTests: XCTestCase {

    func testUpdateContent_EmptyOldContent() throws {
        // Given
		let stackIndent = "\t"
        let inputContent = """
        ScrollView {
        \tLazyVStack {
        
        \t}
        }
        """
        let newContent = """
		\tLazyVStack {
		\t\tMyView.previews
		\t\tConetntView.previews
		\t}
		"""
        let expected = """
		ScrollView {
		\tLazyVStack {
		\t\tMyView.previews
		\t\tConetntView.previews
		\t}
		}
		"""
        
        // When
        let sut = PreviewShowcaseUpdater().updatedContent(with: newContent, in: inputContent, stackIndent: stackIndent)
        
        // Then
        XCTAssertEqual(sut, expected)
    }
	
	func testUpdateContent_WithOldContent() throws {
		// Given
		let stackIndent = "\t"
		let inputContent = """
		ScrollView {
		\tLazyVStack {
		\t\tView1.previews
		\t}
		}
		"""
		let newContent = """
		\tLazyVStack {
		\t\tView1.previews
		\t\tMyView.previews
		\t\tConetntView.previews
		\t}
		"""
		let expected = """
		ScrollView {
		\tLazyVStack {
		\t\tView1.previews
		\t\tMyView.previews
		\t\tConetntView.previews
		\t}
		}
		"""
		
		// When
		let sut = PreviewShowcaseUpdater().updatedContent(with: newContent, in: inputContent, stackIndent: stackIndent)
		
		// Then
		XCTAssertEqual(sut, expected)
	}

}
