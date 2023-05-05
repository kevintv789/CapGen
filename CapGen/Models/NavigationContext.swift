//
//  NavigationContext.swift
//  CapGen
//
//  Created by Kevin Vu on 5/1/23.
//

import Foundation

enum NavigationContext {
    /**
      Called directly from the FolderView(), this context allows the list to filter out to specific folder IDs versus
      generating a list of captions from all available folders
     */
    case folder

    /**
      This is the default context that generates a list of captions based on all available folders
     */
    case list

    /**
      Called directly from the SearchView()
     */
    case search
    
    case optimization
    
    case regular
    
    case captionList
    
    // saveToFolder context - On click of folder will add a caption to the folder
    // This context should be provided when saving a caption to a folder after generating a caption
    case saveToFolder
    
    // View context - Original context for HomeView. On click of folder will navigate user to the folder view
    // This context should be provided in the homepage, at the bottom view
    case view
    
    // Context for providing an image versus prompt to generate caption
    case image
    case camera
    case photosPicker
    
    case prompt
}
