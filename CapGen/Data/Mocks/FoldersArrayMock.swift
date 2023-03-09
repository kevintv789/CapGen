//
//  FoldersArrayMock.swift
//  CapGen
//
//  Created by Kevin Vu on 2/22/23.
//

import Foundation

let foldersMock: [FolderModel] = [
    FolderModel(id: "1", name: "A super", dateCreated: "Mar 8, 4:50 PM", folderType: .General, captions: [
        CaptionModel(captionLength: "veryShort", captionDescription: "Don't let fear hold you back, take that leap of faith and chase your dreams.", includeEmojis: false, includeHashtags: false, folderId: "1", prompt: "Short caption prompt", title: "Short caption title", tones: [ToneModel(id: 1, title: "Formal", description: "Professional, respectful, and polite.", icon: "🤵")], color: "#8C88C9", index: 0),
        CaptionModel(captionLength: "moderate", captionDescription: "Medium caption descriptionMedium caption descriptionMedium caption descriptionMedium caption descriptionMedium caption descriptionMedium caption description", includeEmojis: true, includeHashtags: true, folderId: "1", prompt: "Medium caption prompt", title: "Medium caption title", tones: [ToneModel(id: 1, title: "Formal", description: "Professional, respectful, and polite.", icon: "🤵"), ToneModel(id: 2, title: "Friendly", description: "Warm, open, and casual.", icon: "🙆‍♀️")], color: "#8C88C9", index: 0),
        CaptionModel(captionLength: "veryLong", captionDescription: "Someone call a plumber, because this sauce is leakin'. 💦", includeEmojis: true, includeHashtags: true, folderId: "1", prompt: "Long caption prompt", title: "Long caption title", tones: [], color: "#8C88C9", index: 0),
    ], index: 0),
    FolderModel(name: "Instagram folder", folderType: .Instagram, captions: [], index: 1),
    FolderModel(name: "Twitter folder", folderType: .Twitter, captions: [], index: 2),
    FolderModel(name: "Facebook folder", folderType: .Facebook, captions: [], index: 3),
    FolderModel(name: "LinkedIn folder", folderType: .LinkedIn, captions: [], index: 4),
    FolderModel(name: "Pinterest folder", folderType: .Pinterest, captions: [], index: 5),
    FolderModel(name: "Snapchat folder", folderType: .Snapchat, captions: [], index: 6),
    FolderModel(name: "YouTube folder", folderType: .YouTube, captions: [], index: 7),
    FolderModel(name: "TikTok folder", folderType: .TikTok, captions: [], index: 8),
    FolderModel(name: "Reddit folder", folderType: .Reddit, captions: [], index: 9),
]
