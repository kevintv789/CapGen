//
//  OpenAIConnector.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import Foundation

public class OpenAIConnector {
    let openAIURL = URL(string: "https://api.openai.com/v1/engines/text-davinci-003/completions")
    let openAIKey: String = "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"
    
    public func processPrompt(prompt: String) -> String? {
        var request = URLRequest(url: self.openAIURL!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(self.openAIKey)", forHTTPHeaderField: "Authorization")
        
        let httpBody: [String: Any] = [
            "prompt": prompt,
            "max_tokens": 2000,
            "temperature": 0.5
        ]
        
        var httpBodyJson: Data
        
        do {
            httpBodyJson = try JSONSerialization.data(withJSONObject: httpBody, options: .prettyPrinted)
        } catch {
            print("Unable to convert to JSON \(error)")
            return nil
        }
        
        request.httpBody = httpBodyJson
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            let jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
            print(jsonStr)
            
            let responseHandler = OpenAIResponseHandler()
            return responseHandler.decodeJson(jsonString: jsonStr)?.choices[0].text
        }
        
        return nil
    }
    
    private func executeRequest(request: URLRequest, withSessionConfig sessionConfig: URLSessionConfiguration?) -> Data? {
        // Use semaphore to keep track of waiting threads, this creates a queue of sequential actions starting from 0 counter
        let semaphore = DispatchSemaphore(value: 0)
        let session: URLSession
        
        // Starts a URL session to request data from an external API source
        // with the configurations (headers)
        if (sessionConfig != nil) {
            session = URLSession(configuration: sessionConfig!)
        } else {
            session = URLSession.shared
        }
        
        var requestData: Data?
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            if (error != nil) {
                print("Error: \(error!.localizedDescription)")
            } else if (data != nil) {
                requestData = data
            }
            
            print("Semaphore signaled")
            semaphore.signal()
        }
        
        task.resume()
        
        // Handle async with semaphores with a max wait of 20 seconds
        let timeout = DispatchTime.now() + .seconds(20)
        print("Waiting for semaphore signal")
        let retVal = semaphore.wait(timeout: timeout)
        print("Done waiting, obtained \(retVal)")
        
        return requestData
    }
}
