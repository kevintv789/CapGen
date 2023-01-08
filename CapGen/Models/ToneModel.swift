//
//  ToneModel.swift
//  CapGen
//
//  Created by Kevin Vu on 12/30/22.
//

import Foundation

struct ToneModel: Identifiable, Decodable {
    let id: Int
    let title: String
    let description: String
}

var tones: [ToneModel] = load("Tones.json")

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
