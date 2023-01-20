//
//  OpenAIConnector.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import Foundation

public class OpenAIConnector: ObservableObject {
    @Published var requestModel: AIRequest = AIRequest()
    @Published var prompt: String = ""
    @Published var captionLengthType: String = ""
    let openAIURL = URL(string: "https://api.openai.com/v1/engines/text-davinci-003/completions")

    func generatePrompt(platform: String, prompt: String, tone: String, includeEmojis: Bool, includeHashtags: Bool, captionLength: String, captionLengthType: String) {
        self.requestModel = AIRequest(platform: platform, prompt: prompt, tone: tone, includeEmojis: includeEmojis, includeHashtags: includeHashtags, captionLength: captionLength)
        
        self.captionLengthType = captionLengthType
        
        self.prompt = "Generate 5 captions and a title. Conform each caption to the standards of an \(platform) post. The title should be a catchy title that is no more than 5 words. The tone should be \(tone) and the length of each caption should be between \(captionLength). Emojis, Hashtags and Numbers should be excluded from the word count. The user's prompt is: \(prompt == "" ? "Make me feel good" : prompt). \(includeEmojis ? "Include emojis in each caption" : "Do not use emojis"). \(includeHashtags ? "Include hashtags in each caption" : "Do not use hashtags"). Each caption should be displayed as a numbered list. The caption title should be the sixth item on the list, listed as 6. and without the Title word."
    }
    
    func createCaptionGroup(title: String, captions: [GeneratedCaptions]) {
        // At this point, the requestModel should be initialized, now we just add new data
        self.requestModel.captionLength = self.captionLengthType
        self.requestModel.title = title
        self.requestModel.captions = captions
    }
    
    @MainActor
    public func processPrompt(apiKey: String?) async -> String? {
        print("PROMPT", self.prompt)
        
        guard let openAIKey = apiKey else {
            print("Error retrieving Open AI Key")
            return nil
        }
        
        var request = URLRequest(url: self.openAIURL!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        
        let httpBody: [String: Any] = [
            "prompt": prompt,
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        var httpBodyJson: Data
        
        do {
            httpBodyJson = try JSONSerialization.data(withJSONObject: httpBody, options: .prettyPrinted)
        } catch {
            print("Unable to convert to JSON \(error)")
            return nil
        }
        
        request.httpBody = httpBodyJson
        if let requestData = await executeRequest(request: request, withSessionConfig: nil) {
            print(requestData)
            return requestData.choices[0].text
        }
        
        return nil
    }
    
    private func executeRequest(request: URLRequest, withSessionConfig sessionConfig: URLSessionConfiguration?) async -> OpenAIResponseModel? {
        let session: URLSession
        
        // Starts a URL session to request data from an external API source
        // with the configurations (headers)
        if (sessionConfig != nil) {
            session = URLSession(configuration: sessionConfig!)
        } else {
            session = URLSession.shared
        }
        
        do {
            let (data, response) = try await session.data(for: request as URLRequest)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                
                // Create fallback screens for responses - 4xx, 5xx
                // 503 - Overloaded with server requests
                print("ERROR OpenAIConnect HttpResponse:", response)
                return nil
            }
            
            if let requestData = self.parseJSON(data) {
                return requestData
            }
            
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func parseJSON(_ data: Data) -> OpenAIResponseModel? {
        let decoder = JSONDecoder()
        
        do {
            let decodedData = try decoder.decode(OpenAIResponseModel.self, from: data)
            return decodedData
        } catch {
            return nil
        }
    }
}
