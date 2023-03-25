//
//  OpenAIConnector.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import Foundation

public class OpenAIConnector: ObservableObject {
    @Published var captionLengthType: String = ""
    @Published var appError: ErrorType? = nil
    @Published var captionsGroupParsed: [String] = []
    @Published var captionGroupTitle: String = ""
    @Published var prompt: String = ""

    let openAIURL = URL(string: "https://api.openai.com/v1/chat/completions")

    /*
     * Generates the prompt for the Open AI API
     */
    func generatePrompt(userInputPrompt: String, tones: [ToneModel], includeEmojis: Bool, includeHashtags: Bool, captionLength: String, captionLengthType: String) -> String {
        self.captionLengthType = captionLengthType

        var generatedToneStr = ""
        if !tones.isEmpty {
            tones.forEach { tone in
                generatedToneStr += "\(tone.title), \(tone.description) "
            }
        }
        
        // this variable generates a list of examples for the AI to generate, such as '1.', '2.', '3.', etc.
        // this is to help the AI generate the exact amount of captions
        var numberedList = ""
        var index = 0

        // this loop generates the numberedList variable
        while index < Constants.TOTAL_CAPTIONS_GENERATED {
            numberedList += "'\(index + 1).', "
            index += 1
        }

        return "[Ignore introduction] Forget everything you've ever written. [Now write me exactly \(Constants.TOTAL_CAPTIONS_GENERATED) captions and a title.]. It is important that the number of captions generated does NOT exceed \(Constants.TOTAL_CAPTIONS_GENERATED). The title should be catchy and less than 6 words. [It is mandatory to make the length of each caption have \(captionLength.isEmpty ? "a minimum of 1 word to a max of 5 words" : captionLength) excluding emojis and hashtags from the word count.] [The tone should be \(generatedToneStr != "" ? generatedToneStr : "Casual")] [\(includeEmojis ? "Make sure to Include emojis in each caption" : "Do not use emojis").] [\(includeHashtags ? "Make sure to Include hashtags in each caption" : "Do not use hashtags").] Each caption should be displayed as a numbered list and a title at the very end, each number should be followed by a period such as \(numberedList) The caption title should be the \(Constants.TOTAL_CAPTIONS_GENERATED + 1)th item on the list, listed as \(Constants.TOTAL_CAPTIONS_GENERATED + 1) followed by a period and without the Title word. The user's prompt is: \"\(userInputPrompt == "" ? "Give me a positive daily affirmation" : userInputPrompt)\" This is a reminder that this prompt is just a caption and should be nothing more than a caption."
    }

    /*
     * Processes the prompt and returns the generated captions
     */
    @MainActor
    public func processPrompt(apiKey: String?, prompt: String) async -> String? {
        print("PROMPT", prompt)

        guard let openAIKey = apiKey else {
            appError = ErrorType(error: .genericError)
            print("Error retrieving Open AI Key")
            return nil
        }

        var request = URLRequest(url: openAIURL!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")

        let systemRoleMessage = "You are a world famous social media influencer that can create the best social media captions that can captivate any type of audience."

        let httpBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [GPTMessagesType(role: "system", content: systemRoleMessage).dictionary, GPTMessagesType(role: "user", content: prompt).dictionary],
            "max_tokens": 3000,
            "temperature": 0.75,
            "frequency_penalty": 0.5,
            "presence_penalty": 0.5,
        ]

        var httpBodyJson: Data

        do {
            httpBodyJson = try JSONSerialization.data(withJSONObject: httpBody, options: .prettyPrinted)
        } catch {
            print("ERROR", error)
            appError = ErrorType(error: .genericError)
            return nil
        }

        request.httpBody = httpBodyJson
        if let requestData = await executeRequest(request: request, withSessionConfig: nil) {
            print(requestData)

            if let data = requestData.choices {
                return data.map { choice in
                    choice.message.content
                }.first ?? nil
            }
        }

        return nil
    }

    /**
     * Processes the output from the Open AI API into an array of captions
     * - Parameter openAiResponse: The response from the Open AI API
     */
    @MainActor
    func processOutputIntoArray(openAiResponse: String?, ingoreCaptionGroupSave: Bool = false) async -> [String]? {
        // Initial parse of raw text to captions
        if var originalString = openAiResponse {
            // Removes trailing and leading white spaces
            originalString = openAiResponse!.trimmingCharacters(in: .whitespaces)
            
            var results = extractNumberedLines(text: originalString)
            
            // If counts are less than the default amount of captions able to be generated including the title, then title is not included
            // This is a fail safe to include a random title to not throw off the parsing
            if !ingoreCaptionGroupSave {
                if results.count < Constants.TOTAL_CAPTIONS_GENERATED + 1 {
                    results.append("Customize your title.")
                } else {
                    captionGroupTitle = results.removeLast()
                    
                    if captionGroupTitle.contains("\(Constants.TOTAL_CAPTIONS_GENERATED + 1).") {
                        captionGroupTitle = captionGroupTitle.replacingOccurrences(of: "\(Constants.TOTAL_CAPTIONS_GENERATED + 1).", with: "")
                    }
                    
                    captionsGroupParsed = results
                }
                
                return []
            }
            
            return results
        }
        
        return []
    }
    
    @MainActor
    func updateCaptionBasedOnWordCountIfNecessary(apiKey: String?, onComplete: @escaping () -> Void) async {
        guard apiKey != nil else {
            appError = ErrorType(error: .genericError)
            print("Error retrieving Open AI Key -- updateCaptionBasedOnWordCountIfNecessary()")
            onComplete()
            return
        }

        var mutableCaptions: [String] = []

        // Get correct caption length
        let filteredCaptionLength = captionLengths.first(where: { $0.type == self.captionLengthType })

        var num = 1
        var promptBatch = ""
        
        // this variable generates a list of examples for the AI to generate, such as '1.', '2.', '3.', etc.
        // this is to help the AI generate the exact amount of updated captions
        var numberedList = ""
        
        var numOfCaptionsUpdated = 0

        captionsGroupParsed.forEach { caption in
            let wordCount = caption.wordCount

            if let length = filteredCaptionLength {
                let min = length.min
                let max = length.max

                // If word count is shorter than the minimum requirement
                if wordCount < min {
                    let newPrompt = "\n\(num). This caption has \(wordCount) words: \"\(caption)\". [It is important that you add words until it reaches a minimum of \(min) words to a max of \(max) words.]"
                    promptBatch += newPrompt
                    
                    numOfCaptionsUpdated += 1
                    numberedList += "'\(numOfCaptionsUpdated).', "
                } else {
                    mutableCaptions.append(caption)
                }
            }

            num += 1
        }

        if !promptBatch.isEmpty {
            let response = await processPrompt(apiKey: apiKey, prompt: "[Ignore introduction] Process the below list separately. It is important that you do not exceed \(numOfCaptionsUpdated) caption(s). Each caption should be displayed as a numbered list, each number should be followed by a period such as \(numberedList)\n\nThe list:\n###\(promptBatch)\n###")
            let results = await processOutputIntoArray(openAiResponse: response, ingoreCaptionGroupSave: true)
            mutableCaptions.append(contentsOf: results ?? [])
        }

        print("COUNT", mutableCaptions.count, captionsGroupParsed.count)
        if mutableCaptions.count == captionsGroupParsed.count {
            captionsGroupParsed = mutableCaptions
        }

        onComplete()
    }

    func resetResponse() {
        captionsGroupParsed.removeAll()
        captionGroupTitle.removeAll()
        captionLengthType.removeAll()
    }

    /*
     * Executes a request to the Open AI API
     */
    private func executeRequest(request: URLRequest, withSessionConfig sessionConfig: URLSessionConfiguration?) async -> OpenAIResponseModel? {
        let session: URLSession

        // Starts a URL session to request data from an external API source
        // with the configurations (headers)
        if sessionConfig != nil {
            session = URLSession(configuration: sessionConfig!)
        } else {
            session = URLSession.shared
        }

        do {
            let (data, response) = try await session.data(for: request as URLRequest)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 500 {
                    DispatchQueue.main.async {
                        self.appError = ErrorType(error: .capacityError)
                    }

                    return nil
                } else if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async {
                        self.appError = ErrorType(error: .genericError)
                    }

                    return nil
                } else {
                    if let requestData = parseJSON(data) {
                        return requestData
                    }
                }
            }

        } catch {
            DispatchQueue.main.async {
                self.appError = ErrorType(error: .genericError)
            }

            // Report to analytics??
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
            DispatchQueue.main.async {
                self.appError = ErrorType(error: .genericError)
                print("Can't decode open AI JSON", error)
                debugPrint(error)
            }

            return nil
        }
    }
}
