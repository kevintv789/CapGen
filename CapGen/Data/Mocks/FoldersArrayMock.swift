//
//  FoldersArrayMock.swift
//  CapGen
//
//  Created by Kevin Vu on 2/22/23.
//

import Foundation

let foldersMock: [FolderModel] = [
    FolderModel(name: "General folder", folderType: .General, captions: [
        CaptionModel(captionLength: "veryShort", captionDescription: "Short caption description", includeEmojis: false, includeHashtags: false, folderId: "1", prompt: "Short caption prompt", title: "Short caption title", tones: [ToneModel(id: 1, title: "Formal", description: "Professional, respectful, and polite.", icon: "🤵")], color: "#8C88C9"),
        CaptionModel(captionLength: "moderate", captionDescription: "Medium caption descriptionMedium caption descriptionMedium caption descriptionMedium caption descriptionMedium caption descriptionMedium caption description", includeEmojis: true, includeHashtags: true, folderId: "1", prompt: "Medium caption prompt", title: "Medium caption title", tones: [ToneModel(id: 1, title: "Formal", description: "Professional, respectful, and polite.", icon: "🤵"), ToneModel(id: 2, title: "Friendly", description: "Warm, open, and casual.", icon: "🙆‍♀️")], color: "#8C88C9"),
        CaptionModel(captionLength: "veryLong", captionDescription: "Long caption description", includeEmojis: true, includeHashtags: true, folderId: "1", prompt: "Long caption prompt", title: "Long caption title", tones: [], color: "#8C88C9"),
    ]),
    FolderModel(name: "Instagram folder", folderType: .Instagram, captions: []),
    FolderModel(name: "Twitter folder", folderType: .Twitter, captions: []),
    FolderModel(name: "Facebook folder", folderType: .Facebook, captions: []),
    FolderModel(name: "LinkedIn folder", folderType: .LinkedIn, captions: []),
    FolderModel(name: "Pinterest folder", folderType: .Pinterest, captions: []),
    FolderModel(name: "Snapchat folder", folderType: .Snapchat, captions: []),
    FolderModel(name: "YouTube folder", folderType: .YouTube, captions: []),
    FolderModel(name: "TikTok folder", folderType: .TikTok, captions: []),
    FolderModel(name: "Reddit folder", folderType: .Reddit, captions: []),
]
