//
//  OpenAIConnector.swift
//  CapGen
//
//  Created by Kevin Vu on 1/2/23.
//

import Foundation

public class OpenAIConnector: ObservableObject {
    @Published var requestModel: AIRequest = .init()
    @Published var mutableCaptionGroup: AIRequest?
    @Published var captionLengthType: String = ""
    @Published var appError: ErrorType? = nil
    @Published var captionsGroupParsed: [String] = []
    @Published var captionGroupTitle: String = ""
    @Published var prompt: String = ""

    let openAIURL = URL(string: "https://api.openai.com/v1/engines/text-davinci-003/completions")

    /*
     * Generates the prompt for the Open AI API
     */
    func generatePrompt(userInputPrompt: String, tones: [ToneModel], includeEmojis: Bool, includeHashtags: Bool, captionLength: String, captionLengthType: String) -> String {
        requestModel = AIRequest(prompt: userInputPrompt, tones: tones, includeEmojis: includeEmojis, includeHashtags: includeHashtags, captionLength: captionLength)

        self.captionLengthType = captionLengthType

        var generatedToneStr = ""
        if !tones.isEmpty {
            tones.forEach { tone in
                generatedToneStr += "\(tone.title), \(tone.description) "
            }
        }

        return "Forget everything we've ever written. Now write me exactly 5 captions and a title. The title should be catchy and less than 6 words. It is mandatory to make the length of each caption be a \(captionLength) excluding emojis and hashtags from the word count. The tone should be \(generatedToneStr != "" ? generatedToneStr : "Casual") \(includeEmojis ? "Make sure to Include emojis in each caption" : "Do not use emojis"). \(includeHashtags ? "Make sure to Include hashtags in each caption" : "Do not use hashtags"). Each caption should be displayed as a numbered list and a title at the very end, each number should be followed by a period such as '1.', '2.', '3.', '4.', '5.', '6.' The caption title should be the sixth item on the list, listed as 6 followed by a period and without the Title word. The user's prompt is: \"\(userInputPrompt == "" ? "Give me a positive daily affirmation" : userInputPrompt)\""
    }

    func generateNewRequestModel(title: String, captions: [GeneratedCaptions]) {
        // At this point, the requestModel should be initialized, now we just add new data
        requestModel.captionLength = captionLengthType
        requestModel.title = title
        requestModel.captions = captions
    }

    func updateMutableCaptionGroup(group: AIRequest) {
        mutableCaptionGroup = group
    }

    func updateMutableCaptionGroupWithNewCaptions(with captions: [GeneratedCaptions], title: String) {
        mutableCaptionGroup?.captions = captions
        mutableCaptionGroup?.title = title
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

        let httpBody: [String: Any] = [
            "prompt": prompt,
            "max_tokens": 3000,
            "temperature": 0.75,
            "frequency_penalty": 0.5,
            "presence_penalty": 0.5,
        ]

        var httpBodyJson: Data

        do {
            httpBodyJson = try JSONSerialization.data(withJSONObject: httpBody, options: .prettyPrinted)
        } catch {
            appError = ErrorType(error: .genericError)
            return nil
        }

        request.httpBody = httpBodyJson
        if let requestData = await executeRequest(request: request, withSessionConfig: nil) {
            print(requestData)

            if let data = requestData.choices {
                return data.map { choice in
                    choice.text
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

            /**
             (?m): Enable multiline mode so that ^ and $ match the start and end of lines in the input string.
             ^: Match the start of a line.
             \s*: Match zero or more whitespace characters (spaces, tabs, and newlines).
             \d+: Match one or more digits.
             [. ]+: Match one or more periods or spaces (to handle cases like "\n1. " or "\n\n1 ").
             (: Start capturing group 1.
             .*: Match any characters (except newline) zero or more times.
             (?:: Start a non-capturing group.
             \n+: Match one or more newline characters.
             (?!\d+[. ]): Use negative lookahead to assert that the next characters are not one or more digits followed by a period or space (i.e. the start of a new numbered caption).
             [^\n]*: Match any characters (except newline) zero or more times.
             )*: End the non-capturing group and make it optional (so that we can match the last caption even if it doesn't have a newline after it)
             ): End capturing group 1.
             */
            let pattern = "(?m)^\\s*\\d+[. ]+(.*(?:\\n+(?!\\d+[. ])[^\\n]*)*)"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(originalString.startIndex..., in: originalString)
                let matches = regex.matches(in: originalString, options: [], range: range)
                var results = matches.map {
                    String(originalString[Range($0.range(at: 1), in: originalString)!])
                }
                // If counts are less than 6, then title is not included
                // This is a fail safe to include a random title to not throw off the parsing
                if !ingoreCaptionGroupSave {
                    if results.count < 6 {
                        results.append("Customize your title.")
                    } else {
                        captionGroupTitle = results.removeLast()
                        captionsGroupParsed = results
                    }

                    return []
                }

                return results
            }
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
        let filteredCaptionLength = captionLengths.first(where: { $0.value == self.requestModel.captionLength })

        var num = 1
        var promptBatch = ""

        captionsGroupParsed.forEach { caption in
            let wordCount = caption.wordCount

            if let length = filteredCaptionLength {
                let min = length.min
                let max = length.max

                // If word count is shorter than the minimum requirement
                if wordCount < min {
                    let newPrompt = "\n\(num). This caption has \(wordCount) words: \"\(caption)\". Add words until it reaches a minimum of \(min) words to a max of \(max) words."
                    promptBatch += newPrompt
                } else {
                    mutableCaptions.append(caption)
                }
            }

            num += 1
        }

        if !promptBatch.isEmpty {
            let response = await processPrompt(apiKey: apiKey, prompt: "Process the below list separately. Each caption should be displayed as a numbered list, each number should be followed by a period such as '1.', '2.', '3.', '4.', '5.'\n###\(promptBatch)\n###")
            let results = await processOutputIntoArray(openAiResponse: response, ingoreCaptionGroupSave: true)
            mutableCaptions.append(contentsOf: results ?? [])
        }

        print("COUNT", mutableCaptions.count, captionsGroupParsed.count)
        if mutableCaptions.count == captionsGroupParsed.count {
            captionsGroupParsed = mutableCaptions
            onComplete()
        }

//        self.captionsGroupParsed.forEach { caption in
//            Task {
//                let wordCount = caption.wordCount
//
//                if let length = filteredCaptionLength {
//                    let min = length.min
//                    let max = length.max
//
//                    // If word count is shorter than the minimum requirement
//                    // Then generate a new prompt and replace
//                    if wordCount < min {
//                        let newPrompt = "This caption has \(wordCount) words: \"\(caption)\". Add words until it reaches a minimum of \(min) words to a max of \(max) words."
//
//                        async let response = self.processPrompt(apiKey: apiKey, prompt: newPrompt)
//
//                        if let newCaption = await response {
//                            mutableCaptions.append(newCaption.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
//                        } else {
//                           mutableCaptions.append(caption)
//                       }
//                    } else {
//                        mutableCaptions.append(caption)
//                    }
//
//                    if mutableCaptions.count == self.captionsGroupParsed.count {
//                        self.captionsGroupParsed = mutableCaptions
//                        onComplete()
//                    }
//
//                }
//
//            }
//        }
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
