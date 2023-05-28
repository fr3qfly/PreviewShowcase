//
//  PreviewProviderStructNameTests.swift
//  
//
//  Created by Balázs Szamódy on 21/5/2023.
//

import XCTest
@testable import PreviewShowcaseUpdater

final class PreviewProviderStructNameTests: XCTestCase {
    var sut: PreviewShowcaseUpdater!

    override func setUpWithError() throws {
        sut = PreviewShowcaseUpdater()
    }

    func testGetPreviewProviderStructNames_SinglePreview_NoIndent() throws {
        // Given
        let content = """
            struct MyView: PreviewProvider {
                some code
            }
            """
        
        // When
        let previewProviders = sut.getPreviewProviderNames(from: content)
        
        // Then
        XCTAssertEqual(previewProviders.count, 1)
        XCTAssertEqual(previewProviders.first, "MyView")
    }
    
    func testGetPreviewProviderStructNames_SinglePreview_WithIndent() throws {
        // Given
        let content = """
                    struct MyView: PreviewProvider {
                        some code
                    }
            """
        
        // When
        let previewProviders = sut.getPreviewProviderNames(from: content)
        
        // Then
        XCTAssertEqual(previewProviders.count, 1)
        XCTAssertEqual(previewProviders.first, "MyView")
    }
    
    func testGetPreviewProviderStructNames_MultiPreview_WithIndent() throws {
        // Given
        let content = """
            struct MyView: PreviewProvider {
                some code
            }
            
                        struct OtherView_Previews: PreviewProvider {
                            some code
                        }
            """
        
        // When
        let previewProviders = sut.getPreviewProviderNames(from: content)
        
        // Then
        XCTAssertEqual(previewProviders.count, 2)
        XCTAssertEqual(previewProviders, ["MyView", "OtherView_Previews"])
    }

}
