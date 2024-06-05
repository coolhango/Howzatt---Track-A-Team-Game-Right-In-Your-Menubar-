// Last Updated: 2 June 2024, 3:42PM.
// Copyright © 2024 Gedeon Koh All rights reserved.
// No part of this publication may be reproduced, distributed, or transmitted in any form or by any means, including photocopying, recording, or other electronic or mechanical methods, without the prior written permission of the publisher, except in the case of brief quotations embodied in reviews and certain other non-commercial uses permitted by copyright law.
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR OR COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Use of this program for pranks or any malicious activities is strictly prohibited. Any unauthorized use or dissemination of the results produced by this program is unethical and may result in legal consequences.
// This code have been tested throughly. Please inform the operator or author if there is any mistake or error in the code.
// Any damage, disciplinary actions or death from this material is not the publisher's or owner's fault.
// Run and use this program this AT YOUR OWN RISK.
// Version 0.1

// This Space is for you to experiment your codes
// Start Typing Below :) ↓↓↓

import Foundation

extension NSRegularExpression {
    convenience init(substrings: [String], options: NSRegularExpression.Options) throws {
        let escapedSubstrings: [String] = substrings.map(NSRegularExpression.escapedTemplate)
        let pattern: String = escapedSubstrings.joined(separator: "|")
        try self.init(pattern: pattern, options: options)
    }

    convenience init?(with pattern: String, options: NSRegularExpression.Options = []) {
        do {
            try self.init(pattern: pattern, options: options)
        } catch {
            return nil
        }
    }

    func match(in input: String) -> Bool {
        return numberOfMatches(in: input, options: [], range: input.range) > 0
    }
    
    func split(_ str: String) -> [String] {
        let range = NSRange(location: 0, length: str.count)
        
        //get locations of matches
        var matchingRanges: [NSRange] = []
        let matches: [NSTextCheckingResult] = self.matches(in: str, options: [], range: range)
        for match: NSTextCheckingResult in matches {
            matchingRanges.append(match.range)
        }
        
        
        var pieceRanges: [NSRange] = []
        
        
        pieceRanges.append(NSRange(location: 0, length: (matchingRanges.count == 0 ? str.count : matchingRanges[0].location)))
        
       
        for i in 0..<matchingRanges.count {
            let isLast = i + 1 == matchingRanges.count
            
            let location = matchingRanges[i].location
            let length = matchingRanges[i].length
            
            let startLoc = location + length
            let endLoc = isLast ? str.count : matchingRanges[i + 1].location
            pieceRanges.append(NSRange(location: startLoc, length: endLoc - startLoc))
        }
        
        var pieces: [String] = []
        for range: NSRange in pieceRanges {
            let piece = (str as NSString).substring(with: range)
            pieces.append(piece)
        }
        
        return pieces
    }

}
