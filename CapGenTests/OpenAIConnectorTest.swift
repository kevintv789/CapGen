//
//  CapGenTests.swift
//  CapGenTests
//
//  Created by Kevin Vu on 12/27/22.
//

import XCTest

final class OpenAIConnectorTest: XCTestCase {
    private var sut: OpenAIConnector!
    
    
    override func setUpWithError() throws {
        sut = OpenAIConnector()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func test_generatePrompt() {
        let tones: [ToneModel] = [ToneModel(id: 1, title: "Formal", description: "Professional, respectful, and polite.", icon: "🤵")]
        let mockPromptOptions: AIRequest = AIRequest(id: "123", platform: "Instagram", prompt: "Give me a caption about my dogs", tones: tones, includeEmojis: false, includeHashtags: false, captionLength: "veryShort", title: "", dateCreated: "", captions: [])
        
        sut.generatePrompt(platform: mockPromptOptions.platform, prompt: mockPromptOptions.prompt, tones: mockPromptOptions.tones, includeEmojis: mockPromptOptions.includeEmojis, includeHashtags: mockPromptOptions.includeHashtags, captionLength: mockPromptOptions.captionLength, captionLengthType: mockPromptOptions.captionLength)
        
        let actualPrompt = sut.prompt
        
        let expectedPrompt = "Generate 5 captions and a title. Conform each caption to the standards of an Instagram post. The title should be a catchy title that is no more than 5 words. The tone should be Formal, Professional, respectful, and polite. and the length of each caption should be veryShort. Emojis, Hashtags and Numbers should be excluded from the word count. The user's prompt is: Give me a caption about my dogs. Do not use emojis. Do not use hashtags. Each caption should be displayed as a numbered list. The caption title should be the sixth item on the list, listed as 6. and without the Title word."
        
        XCTAssertEqual(actualPrompt, expectedPrompt)
    }

}
