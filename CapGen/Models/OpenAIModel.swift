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
        
        self.generatedPromptString = "You are a professional social media content creator. You've been curating social media posts for 15 years with extremely well written and catchy captions that both millennials and Gen Z users would vibe with. Do NOT be corny. I want you to generate 5 captions for an \(platform) post. The tone should be \(tone) and the length of each caption should be between \(captionLength). The user's prompt is: \(prompt == "" ? "Make me feel good" : prompt). \(includeEmojis ? "Use emojis" : "Do not use emojis"). \(includeHashtags ? "Use hashtags" : "Do not use hashtags")."
    }
}
