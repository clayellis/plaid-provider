import Foundation

// This code is  slightly modified from the original (see link) for converting strings from camel case into snake case while allowing
// for a certain set of words to be considered as whole words.
// https://github.com/apple/swift/blob/fc99de452d7457026a863f5a77f84d72fb45e8c7/stdlib/public/SDK/Foundation/JSONEncoder.swift#L112
func convertToSnakeCase(_ stringKey: String, keepingWholeWords wholeWords: Set<String>) -> String {
    guard !stringKey.isEmpty else { return stringKey }

    var words : [Range<String.Index>] = []
    // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
    //
    // myProperty -> my_property
    // myURLProperty -> my_url_property
    //
    // We assume, per Swift naming conventions, that the first character of the key is lowercase.
    var wordStart = stringKey.startIndex
    var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex

    // Find next uppercase character
    while let upperCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
        let untilUpperCase = wordStart..<upperCaseRange.lowerBound
        words.append(untilUpperCase)

        // Find next lowercase character
        searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
        guard let lowerCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
            // There are no more lower case letters. Just end here.
            wordStart = searchRange.lowerBound
            break
        }

        var newSearchRangeLowerBound = lowerCaseRange.upperBound

        // Is the next lowercase letter more than 1 after the uppercase? If so, we encountered a group of uppercase letters that we should treat as its own word
        let nextCharacterAfterCapital = stringKey.index(after: upperCaseRange.lowerBound)
        if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
            // The next character after capital is a lower case character and therefore not a word boundary.
            // Continue searching for the next upper case for the boundary.
            wordStart = upperCaseRange.lowerBound
        } else {
            // There was a range of >1 capital letters.

            // Check to see if the captial letter plus the lowercase letters are in the whole word set
            let wordRange = upperCaseRange.lowerBound..<lowerCaseRange.upperBound
            let word = String(stringKey[wordRange])
            if wholeWords.contains(word) {
                // Turn special word into a word, stopping at after the lower case character
                let afterLowerIndex = stringKey.index(after: lowerCaseRange.lowerBound)
                words.append(upperCaseRange.lowerBound..<afterLowerIndex)

                // Next word starts after the lower case charcter
                wordStart = afterLowerIndex
                if let afterWordStart = stringKey.index(wordStart, offsetBy: 1, limitedBy: stringKey.endIndex) {
                    newSearchRangeLowerBound = afterWordStart
                }

            } else {
                // Turn those into a word, stopping at the capital before the lower case character.
                let beforeLowerIndex = stringKey.index(before: lowerCaseRange.lowerBound)
                words.append(upperCaseRange.lowerBound..<beforeLowerIndex)

                // Next word starts at the capital before the lowercase we just found
                wordStart = beforeLowerIndex
            }

        }
        searchRange = newSearchRangeLowerBound..<searchRange.upperBound
    }
    let finalRange = wordStart..<searchRange.upperBound
    if !finalRange.isEmpty {
        words.append(finalRange)
    }
    let result = words.map({ (range) in
        return stringKey[range].lowercased()
    }).joined(separator: "_")
    return result
}
