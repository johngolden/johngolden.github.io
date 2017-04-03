//
//  main.swift
//  NewPost
//
//  Created by Evan Dekhayser on 1/14/17.
//  Copyright © 2017 Xappox, LLC. All rights reserved.
//

import Foundation

let title = CommandLine.arguments[1]
let hyphenSeparatedTitle = title.replacingOccurrences(of: " ", with: "-", options: .literal, range: nil)
let characterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
let filteredTitle = String(hyphenSeparatedTitle.characters.filter{ String($0).rangeOfCharacter(from: characterSet) != nil} )
let year = CommandLine.arguments[2]
let month = CommandLine.arguments[3]
let day = CommandLine.arguments[4]

var monthStrings = [1:"Jan", 2:"Feb", 3:"Mar", 4:"Apr", 5:"May", 6:"Jun", 7:"Jul", 8:"Aug", 9:"Sep", 10:"Oct", 11:"Nov", 12:"Dec"]

var fileText = "---\ntitle: \"\(title)\"\ndate: \(year)-\(month)-\(day)\n---\n\n"
fileText += "<h2><a href=\"http://evandekhayser.com/\(year)/\(month)/\(day)/\(filteredTitle)\" class=\"title\">\(title)</a></h2>\n<h5>\(day) \(monthStrings[Int(month)!]!) \(year)</h5>\n\n"
let currentPath = FileManager.default.currentDirectoryPath
print(currentPath)
let path = URL.init(fileURLWithPath: currentPath + "/\(year)-\(month)-\(day)-\(filteredTitle).md")
try! fileText.write(to: path , atomically: false, encoding: .utf8)
