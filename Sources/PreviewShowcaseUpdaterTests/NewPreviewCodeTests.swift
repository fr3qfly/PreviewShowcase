//
//  NewPreviewCodeTests.swift
//  
//
//  Created by Balázs Szamódy on 27/5/2023.
//

import XCTest
import RegexBuilder
@testable import PreviewShowcaseUpdater

final class NewPreviewCodeTests: XCTestCase {
    
    func testNewPreviewCode_NoExistingPreviews() {
        // Given
        let existingPreviews = [String]()
        let newPreviews = [
            "MyView",
            "AView",
            "ContentView",
        ]
        let stackIndent = "\t"
        let expected = """
        \tLazyVStack {
        \t\tAView.previews
        \t\tContentView.previews
        \t\tMyView.previews
        \t}
        """
        
        // When
        let sut = PreviewShowcaseUpdater().generateNewPreviewCode(existingStructNames: existingPreviews, newStructNames: newPreviews, stackIndent: stackIndent)
        
        // Then
        XCTAssertEqual(sut, expected)
    }
    
    func testNewPreviewCode_WithExistingPreviews() {
        // Given
        let existingPreviews = [
            "View1",
            "View2",
            "View3"
            ]
        let newPreviews = [
            "MyView",
            "AView",
            "ContentView",
        ]
        let stackIndent = "\t"
        let expected = """
        \tLazyVStack {
        \t\tView1.previews
        \t\tView2.previews
        \t\tView3.previews
        \t\tAView.previews
        \t\tContentView.previews
        \t\tMyView.previews
        \t}
        """
        
        // When
        let sut = PreviewShowcaseUpdater().generateNewPreviewCode(existingStructNames: existingPreviews, newStructNames: newPreviews, stackIndent: stackIndent)
        
        // Then
        XCTAssertEqual(sut, expected)
    }
    
    func testNewPreviewCode_WithExistingPreviews_AndGroup() {
        // Given
        let existingPreviews = Array(1...8).map({ "View\($0)" })
        let newPreviews = [
            "MyView",
            "AView",
            "ContentView",
        ]
        let stackIndent = "\t"
        let expected = """
        \tLazyVStack {
        \t\tGroup {
        \t\t\tView1.previews
        \t\t\tView2.previews
        \t\t\tView3.previews
        \t\t\tView4.previews
        \t\t\tView5.previews
        \t\t\tView6.previews
        \t\t\tView7.previews
        \t\t\tView8.previews
        \t\t\tAView.previews
        \t\t\tContentView.previews
        \t\t}
        \t\tGroup {
        \t\t\tMyView.previews
        \t\t}
        \t}
        """
        
        // When
        let sut = PreviewShowcaseUpdater().generateNewPreviewCode(existingStructNames: existingPreviews, newStructNames: newPreviews, stackIndent: stackIndent)
        
        // Then
        XCTAssertEqual(sut, expected)
    }

    func testSingleLevel_NoIndent() throws {
        // Given
		let input = Array(1...10).map({ "Line\($0)" })
        
        // When
        let sut = PreviewShowcaseUpdater().toGroups(input, scopeIndent: "")
        
        // Then
        XCTAssertEqual(sut, """
        Line1
        Line2
        Line3
        Line4
        Line5
        Line6
        Line7
        Line8
        Line9
        Line10
        """)
    }
    
    func testSingleLevel_WithIndent() throws {
        // Given
		let input = Array(1...10).map({ "Line\($0)" })
        let indent = "\t"
        
        // When
        let sut = PreviewShowcaseUpdater().toGroups(input, scopeIndent: indent)
        
        // Then
        XCTAssertEqual(sut, """
        \tLine1
        \tLine2
        \tLine3
        \tLine4
        \tLine5
        \tLine6
        \tLine7
        \tLine8
        \tLine9
        \tLine10
        """)
    }
    
    func testTwoLevels_NoStartingIndent() throws {
        // Given
        let input = Array(1...11).map({ "Line\($0)" })
        let indent = ""
        
        // When
        let sut = PreviewShowcaseUpdater().toGroups(input, scopeIndent: indent)
        
        // Then
        XCTAssertEqual(sut, """
        Group {
        \tLine1
        \tLine2
        \tLine3
        \tLine4
        \tLine5
        \tLine6
        \tLine7
        \tLine8
        \tLine9
        \tLine10
        }
        Group {
        \tLine11
        }
        """)
    }
	
	func testTwoLevels_WithStartingIndent() throws {
		// Given
		let input = Array(1...11).map({ "Line\($0)" })
		let indent = "\t"
		
		// When
		let sut = PreviewShowcaseUpdater().toGroups(input, scopeIndent: indent)
		
		// Then
		XCTAssertEqual(sut, """
		\tGroup {
		\t\tLine1
		\t\tLine2
		\t\tLine3
		\t\tLine4
		\t\tLine5
		\t\tLine6
		\t\tLine7
		\t\tLine8
		\t\tLine9
		\t\tLine10
		\t}
		\tGroup {
		\t\tLine11
		\t}
		""")
	}
    
    func testThreeLevels_NoIndent() throws {
        // Given
        let input = Array(1...101).map({ _ in "Line" })
        let expectedFullGroupWithIndent = """
            \tGroup {
            \t\tLine
            \t\tLine
            \t\tLine
            \t\tLine
            \t\tLine
            \t\tLine
            \t\tLine
            \t\tLine
            \t\tLine
            \t\tLine
            \t}
            """
        let fullGroupRegex = Regex {
            Capture {
                expectedFullGroupWithIndent
            }
        }
        let expectedOrphanGroup = """
            Group {
            \tGroup {
            \t\tLine
            \t}
            }
            """
        let orphanGroupRegex = Regex {
            Capture {
                expectedOrphanGroup
            }
        }
        
        // When
        let sut = PreviewShowcaseUpdater().toGroups(input, scopeIndent: "")
        let fullGroupMatches = sut.matches(of: fullGroupRegex)
        let orphanGroupMatch = try orphanGroupRegex.firstMatch(in: sut)
        
        // Then
        XCTAssertEqual(fullGroupMatches.count, 10)
        XCTAssertNotNil(orphanGroupMatch)
    }
	
	func testTokens_SingleLevel() {
		// Given
		let input = Array(1...10).map({ "Line\($0)" })
		
		// When
		let sut = input.toContentTokens()
		
		// Then
		XCTAssertEqual(sut, [
			.line("Line1"),
			.line("Line2"),
			.line("Line3"),
			.line("Line4"),
			.line("Line5"),
			.line("Line6"),
			.line("Line7"),
			.line("Line8"),
			.line("Line9"),
			.line("Line10"),
		])
	}
	
	func testTokens_TwoLevel() {
		// Given
		let input = Array(1...11).map({ "Line\($0)" })
		
		// When
		let sut = input.toContentTokens()
		
		// Then
		XCTAssertEqual(sut, [
			.group([
				.line("Line1"),
				.line("Line2"),
				.line("Line3"),
				.line("Line4"),
				.line("Line5"),
				.line("Line6"),
				.line("Line7"),
				.line("Line8"),
				.line("Line9"),
				.line("Line10")
			]),
			.group([
				.line("Line11")
			])
		])
	}
	func testTokens_ThreeLevel() {
		// Given
		let input = Array(1...101).map({ _ in "Line" })
		
		// When
		let sut = input.toContentTokens()
		
		// Then
		XCTAssertEqual(sut, [
			.group(Array(
				repeating: .group(Array(
					repeating: .line("Line"),
					count: 10)),
				count: 10)),
			.group([.group([.line("Line")])])
		])
		XCTAssertEqual(sut[0], .group(Array(
			repeating: .group(Array(
				   repeating: .line("Line"),
				   count: 10)),
			   count: 10)))
		XCTAssertEqual(sut[1], .group([.group([.line("Line")])]))
	}

}
