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

private extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}

private enum ScoreElement: String {
    case title, guid
}

struct ScoreResult {
    let currentMatch: Match!
    let matches: [Match]
}

class ScoreAPI: NSObject {

    enum ParsingError: Error {
        case RuntimeError(String)
    }
    
    private let liveScoresUrl =
        URL(string: "http://static.espncricinfo.com/rss/livescores.xml")!
    
    private var allMatchScores = [Match]()
    private var currentScoreElement: ScoreElement?
    private var selectedMatch: Match?
    private var currentTitle = ""
    private var currentLink = ""
    
    func fetchScore(currentMatch: Match!, completion: @escaping ((ScoreResult) -> Void)) {
        let result = ScoreResult(currentMatch: nil, matches: [])
        guard let xmlParser = XMLParser(contentsOf: liveScoresUrl)
            else {
                return completion(result)
        }
        
        print("Loading matches...")
        allMatchScores.removeAll();
        
        xmlParser.delegate = self
        xmlParser.parse()
        
        selectedMatch = allMatchScores.first{(match: Match) -> Bool in
            if currentMatch == nil {
                return true
            } else {
                return match.link == currentMatch.link
            }
        }
        if selectedMatch == nil && allMatchScores.count > 0 {
            selectedMatch = allMatchScores[0]
        }
        if allMatchScores.count > 0 {
            guard let matchUrl = URL(string: selectedMatch!.link) else { return completion(result) }
            URLSession.shared.dataTask(with: URLRequest(url: matchUrl))
            { data, response, error in
                if error != nil {
                    print("Error while fetching html for match page")
                    return
                }
                guard let data = data,
                    let html = String(data: data, encoding: .utf8)
                    else { return }
                
                guard let parsedMatch = ScoreAPI.parseScoreFromPage(
                    page: html as String, title: self.selectedMatch!.title, link: self.selectedMatch!.link)
                    else {
                        print("An error occurred while parsing score")
                        return
                }
                completion(ScoreResult(currentMatch: parsedMatch, matches: self.allMatchScores))
            }.resume()
        } else {
            completion(result)
        }
    }
    
    class func parseScoreFromPage(page: String, title: String, link: String) -> Match? {
        let strFrom = "<title>"
        let strTo = "</title>"
        
        guard let pageTitle = page.components(separatedBy: strFrom)[safe: 1]?
            .components(separatedBy: strTo)[safe: 0] else { return nil }
    
        var formattedScore = ""
        if pageTitle.contains("|") {
            formattedScore = pageTitle.components(separatedBy: "|")[0]
        } else {
            formattedScore = pageTitle
        }
        var overs = ""
        let summary = formattedScore
        var status = ""
        var matchStarted = true
        let liveScore = formattedScore.components(separatedBy: "(")[safe: 0]?.trim()
        let summaryPart = formattedScore.components(separatedBy: "(")[safe: 1]?.components(separatedBy: ")")[safe: 0]
        if summaryPart?.contains("ov") ?? false {
            overs = summaryPart?.components(separatedBy: "ov")[0].trim() ?? ""
//            summary = summaryPart?.components(separatedBy: "ov,")[1].trim() ?? ""
            let parsedStatus = formattedScore.components(separatedBy: ") -")[safe: 1]?.components(separatedBy: "-")[safe: 0]
            status = parsedStatus?.trim().uppercased() ?? ""
        }
        let teams = title.replaceAll(of: #"(\d)|(\/)|(&)"#, with: "").components(separatedBy: " v ").map { $0.trim() }
        let scores = title.components(separatedBy: " v ").map { $0.replaceAll(of: #"((?!\d|\/|&).)*"#, with: "").trim() }
        if (scores.filter { !$0.isEmpty }).count == 0 {
            matchStarted = false
        }
        var teamArray = [Team]()
        for (index, score) in scores.enumerated() {
            let battingTeam = teams[index].contains("*")
            let teamScores = score.components(separatedBy: "&")
            var scoreArray = [Score]()
            for (scoreIndex, teamScore) in teamScores.enumerated() {
                // Overs info is only available for currently batting team
                if (battingTeam && scoreIndex == teamScores.count - 1 && !overs.isEmpty) {
                    scoreArray.append(Score(score: teamScore, overs: "(" + overs + " ov)"))
                } else {
                    scoreArray.append(Score(score: teamScore, overs: ""))
                }
            }
            teamArray.append(Team(name: teams[index].replacingOccurrences(of: "*", with: "").trim(), scores: scoreArray, batting: battingTeam))
        }
        
        if !overs.isEmpty {
            formattedScore = (liveScore ?? "") + " (\(overs) ov)"
        } else {
            formattedScore = title.trimmingCharacters(
                in: .whitespacesAndNewlines)
        }
        
        // Add space around &
        formattedScore = formattedScore.replacingOccurrences(
            of: "&", with: " & ")
        return Match(title: title, link: link, status: status, summary: summary, teams: teamArray, shortScore: formattedScore, fromPage: true, matchStarted: matchStarted)
    }
    
    private func isScoreItem(_ elementName: String) -> Bool {
        return elementName == "item"
    }
}

extension ScoreAPI: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String]) {
        currentScoreElement = ScoreElement(rawValue: elementName)
        
        if isScoreItem(elementName) {
            currentTitle = ""
            currentLink = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let element = currentScoreElement {
            switch element {
            case .title:
                currentTitle.append(
                    string.trimmingCharacters(in: .whitespacesAndNewlines))
            case .guid:
                currentLink.append(
                    string.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "cricinfo", with: "espncricinfo"))
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if isScoreItem(elementName) {
            if currentTitle.isEmpty || currentLink.isEmpty { return }
            allMatchScores.append(
                Match(title: currentTitle, link: currentLink, status: "", summary: "", teams: [], shortScore: currentTitle, fromPage: false, matchStarted: true))
        }
    }
}
