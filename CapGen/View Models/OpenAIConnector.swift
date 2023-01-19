//
//  OpenAIConnector.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import Foundation

public class OpenAIConnector: ObservableObject {
    let openAIURL = URL(string: "https://api.openai.com/v1/engines/text-davinci-003/completions")

    @MainActor
    public func processPrompt(prompt: String, apiKey: String?) async -> String? {
        print("PROMPT", prompt)
        
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
