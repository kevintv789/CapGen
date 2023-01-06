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
        
        self.generatedPromptString = "Generate 5 captions for \(platform) with prompt: \(prompt). Captions should have a \(tone) voice. This should have a \(captionLength). Exclude word count from emojis. \(includeEmojis ? "Use emojis" : "Do not use emojis"). \(includeHashtags ? "Use hashtags" : "Do not use hashtags")."
    }
}
