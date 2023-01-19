//
//  OpenAIModel.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import Foundation

struct OpenAIResponseModel: Codable {
    var id: String
    var object: String
    var created: Int
    var model: String
    var choices: [Choice]
}

struct Choice: Codable {
    var text: String
    var index: Int
    var logprobs: String?
    var finish_reason: String
}

struct AIRequest: Hashable {
    let platform: String
    let prompt: String
    let tone: String
    let includeEmojis: Bool
    let includeHashtags: Bool
    let captionLength: String
    var generatedPromptString: String
    
    init(platform: String, prompt: String, tone: String, includeEmojis: Bool, includeHashtags: Bool, captionLength: String) {
        self.platform = platform
        self.prompt = prompt
        self.tone = tone
        self.includeEmojis = includeEmojis
        self.includeHashtags = includeHashtags
        self.captionLength = captionLength
        
        self.generatedPromptString = "Generate 5 captions and a title for an \(platform) post. The title should be a catchy title that is less than 5 words. The tone should be \(tone) and the length of each caption should have a minimum of \(captionLength). Emojis, Hashtags and Numbers should be excluded from the word count. The user's prompt is: \(prompt == "" ? "Make me feel good" : prompt). \(includeEmojis ? "Use emojis" : "Do not use emojis"). \(includeHashtags ? "Use hashtags" : "Do not use hashtags"). Each caption should be displayed as a numbered list. The caption title should be the sixth item on the list, listed as 6. and without the Title word."
    }
}
