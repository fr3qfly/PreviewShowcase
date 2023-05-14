// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ArgumentParser
import RegexBuilder

enum PreviewShowcaseError: LocalizedError {
    case mainStackNotFound
    var errorDescription: String? {
        String(describing: self)
    }
}

class UpdatePreviewProvider: ParsableCommand {
    
    // Command configuration
    static let configuration = CommandConfiguration(
        commandName: "update-previews",
        abstract: "Update SwiftUI previews",
        discussion: """
        This script updates the VStack with all SwiftUI previews in the project that haven't been added yet.
        It reads a Swift file and adds previews at the end of the VStack.
        """,
        version: "1.0.0",
        shouldDisplay: true,
        subcommands: [],
        defaultSubcommand: nil,
        helpNames: .shortAndLong
    )
    
    // Input file path
    @Argument(help: "The path to the Swift file that contains the VStack with previews.")
    var inputFilePath: String
    
    // Changes only
    @Flag(name: .shortAndLong, help: "Only search in changed files according to git.")
    var changesOnly = false
    
    @Flag(help: "")
    var justGenerate = false
    
    @Option(help: "Search path when searching for all .swift files")
    var searchPath: String?
    
    @Option(parsing: .upToNextOption, help: "")
    var excludedFolders: [String] = []
    
    required init() {}
    
//    // Regex pattern for struct names that conform to PreviewProvider protocol
//    private let previewProviderRegexPattern = #"struct\s+([A-Za-z_0-9]+)\s*:\s*PreviewProvider"#
//
//    // Regex pattern for struct names that are already in the VStack
//    private let existingPreviewsRegexPattern = #"^\s*[A-Za-z_0-9]+\.[A-Za-z_0-9]+\.previews\s*\("#
    
    func run() throws {
        
        // Get all files to search
        var filesToSearch: [URL]
        if changesOnly {
            filesToSearch = try getChangedFiles()
        } else {
            filesToSearch = getAllSwiftFiles()
        }
        
        // Filter excluded folders
        filesToSearch = filterExcludedFolders(filesToSearch)
        
        // Get input file content
        let inputFileContent = try getInputFileContent(inputFilePath)
        
        // Get all preview provider struct names
        let previewProviderStructNames = try getPreviewProviderStructNames(filesToSearch: filesToSearch)
        
        let stackIndent = try getMainVStackIndent(inputFileContent)
        
        // Get existing preview struct names in the input file
        let existingPreviewStructNames = try getExistingPreviewStructNames(from: inputFileContent)
        
        // Get preview struct names to add
        let previewStructNamesToAdd = Array(previewProviderStructNames).filter { !existingPreviewStructNames.contains($0) }
        
        // Generate new preview struct code
        let newPreviewStructsCode = generateNewPreviewStructsCode(existingStructNames: existingPreviewStructNames, newStructNames: previewStructNamesToAdd)
        
        // Update file content
        let updatedContent = try updatedContent(inputFileContent, with: newPreviewStructsCode)
        print(updatedContent)
        guard !justGenerate else {
            print("Success! New Previews generated")
            return
        }
        
        // Update input file
        try updateInputFile(updatedContent)
        
        // Print success message
        print("Success! Updated previews in \(inputFilePath)")
    }
    
    private func getChangedFiles() throws -> [URL] {
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = "/usr/bin/env"
        process.arguments = ["git", "diff", "--name-only", "--cached"]
        
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let changedFiles = output?.components(separatedBy: .newlines).filter { $0.hasSuffix(".swift") } ?? []
        
        let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        return try changedFiles.map {
            let fileURL = currentDirectoryURL.appendingPathComponent($0)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: [NSFilePathErrorKey: fileURL.path])
            }
            return fileURL.standardizedFileURL
        }
    }
    
    private func getAllSwiftFiles() -> [URL] {
        do {
            // Find all the Swift files in the current directory and its subdirectories
            let findProcess = Process()
            findProcess.launchPath = "/usr/bin/find"
            findProcess.arguments = [ searchPath ?? "./", "-name", "*.swift", "-type", "f"]
            
            let findPipe = Pipe()
            findProcess.standardOutput = findPipe
            
            try findProcess.run()
            
            let data = findPipe.fileHandleForReading.readDataToEndOfFile()
            let string = String(data: data, encoding: .utf8)
            
            // Split the output into an array of URLs
            let urls = string?
                .components(separatedBy: .newlines)
                .compactMap { URL(fileURLWithPath: $0) }
            
            return urls ?? []
        } catch {
            print("Error while getting Swift files: \(error.localizedDescription)")
            return []
        }
    }
    
    private func filterExcludedFolders(_ input: [URL]) -> [URL] {
        input
            .filter { url in
                guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    return false
                }
                
                let pathComponents = urlComponents.path
                    .components(separatedBy: "/")
                    .filter({ !$0.isEmpty })
                
                return !pathComponents.contains { pathComponent in
                    excludedFolders.contains(pathComponent)
                }
            }
    }
    
    private func getPreviewProviderStructNames(filesToSearch: [URL]) throws -> Set<String> {
        let previewProviderPattern = Regex {
            Capture {
                OneOrMore {
                    ("A"..."Z")
                    OneOrMore(.reluctant) {
                        CharacterClass(
                            .anyOf("_"),
                            ("A"..."Z"),
                            ("a"..."z"),
                            ("0"..."9")
                        )
                    }
                    Regex {
                        ZeroOrMore(.whitespace)
                        ":"
                        ZeroOrMore(.whitespace)
                        "PreviewProvider"
                    }
                }
            }
        }
        let matches = try filesToSearch
            .compactMap { fileURL -> [String]? in
                guard fileURL.absoluteString.contains(".swift") else {
                    return nil
                }
                
                let content = try String(contentsOf: fileURL)
                let matches = content
                    .matches(of: previewProviderPattern)
                    .map { match in
                        String(match.output.1)
                    }
                if !matches.isEmpty {
                    print("Found previews in:\n\(fileURL)")
                }
                return matches
            }
            .reduce([], +)
        
//        var previewProviderStructNames = Set<String>()
//
//        let previewProviderRegex = try! NSRegularExpression(pattern: "[A-Z][A-Za-z0-9_]+?(?=\\s*:\\s*PreviewProvider)", options: [.dotMatchesLineSeparators])
//
//        for fileURL in filesToSearch {
//            guard fileURL.absoluteString.contains(".swift") else {
//                continue
//            }
//            do {
//                let content = try String(contentsOf: fileURL)
//                let matches = previewProviderRegex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
//                if !matches.isEmpty {
//                    print("Found previews in:\n\(fileURL)")
//                }
//                let results = text(in: content, matches: matches)
//
//                previewProviderStructNames = previewProviderStructNames.union(results)
//            } catch {
//                print("Error reading file \(fileURL.path): \(error)")
//            }
//        }
        
        return Set(matches)
    }
    
    private func getInputFileContent(_ inputFilePath: String) throws -> String {
        try String(contentsOfFile: inputFilePath)
    }
    
    private func getMainVStackIndent(_ inputContent: String) throws -> String {
        let mainVStackPattern = Regex {
            Anchor.startOfLine
            Capture {
                OneOrMore(.anyOf(" \\u{9}"))
                "LazyVStack {"
            }
            Anchor.endOfLine
        }
        guard let result = try mainVStackPattern.wholeMatch(in: inputContent)?.output.1 else {
            throw PreviewShowcaseError.mainStackNotFound
        }
        let mainStackLine = String(result)
        
        return mainStackLine.components(separatedBy: "LazyVStack {")[0]
    }
    
    private func getExistingPreviewStructNames(from inputContent: String) throws -> [String] {
        // TODO: Use Swift regex instead
//        Regex {
//          Anchor.wordBoundary
//          ("A"..."Z")
//          ZeroOrMore {
//            CharacterClass(
//              ("a"..."z"),
//              ("A"..."Z"),
//              ("0"..."9")
//            )
//          }
//          "_Previews"
//          Lookahead {
//            ".previews"
//          }
//        }
//        .anchorsMatchLineEndings()
        // #"LazyVStack\s*\(\s*alignment:\s*(\w+)?\s*,?\s*spacing:\s*(\S+)?\s*\)\s*\{([^{}]*+(?:(?R)[^{}]*)*+)\}"#
        do {
//            let regex = try NSRegularExpression(pattern: "\\b[A-Z][a-zA-Z0-9]*_Previews(?=\\.previews)", options: [])
            let regex = try NSRegularExpression(pattern: "LazyVStack\\s*\\(\\s*alignment:\\s*(\\w+)?\\s*,?\\s*spacing:\\s*(\\S+)?\\s*\\)\\s*\\{([^{}]*+(?:(?R)[^{}]*)*+)\\}")
            let results = regex.matches(in: inputContent, options: [], range: NSRange(location: 0, length: inputContent.utf16.count))
            return text(in: inputContent, matches: results)
        } catch {
            print("Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func text(in input: String, matches: [NSTextCheckingResult]) -> [String] {
        matches
            .compactMap { match in
                guard let matchRange = Range(match.range, in: input) else {
                    return nil
                }
                return String(input[matchRange])
            }
    }
    
    private func generateNewPreviewStructsCode(existingStructNames: [String], newStructNames: [String]) -> String {
        // TODO: decide if all should be alphabetical order
        let newStructNames = Array(newStructNames).sorted()
        let previews = (existingStructNames + newStructNames).map { $0 + ".previews" }
        
        // TODO: prefix with correct indent
        
        let groups = toGroups(previews)
        
        let newCode = "VStack {\n\(groups)\n}\n"
        
        return newCode
    }
    
    private func toGroups(_ input: [String]) -> String {
        guard input.count > 10 else {
            return input.joined(separator: "\n")
        }
        
        let chunks = input
            .chunks()
            .map { chunk in
                "Group {\n\(chunk.joined(separator: "\n"))\n}"
            }
        
        if chunks.count > 10 {
            return toGroups(chunks)
        } else {
            return chunks.joined(separator: "\n")
        }
    }
    
    private func updatedContent(_ inputContent: String, with newContent: String) throws -> String {
        let pattern = "VStack \\{([^\\}]*)\\}"
        
        let regex = try NSRegularExpression(pattern: pattern, options: [])

        let range = NSRange(location: 0, length: inputContent.utf16.count)

        return regex.stringByReplacingMatches(in: inputContent, options: [], range: range, withTemplate: newContent)
    }
    
    private func updateInputFile(_ newContent: String) throws {
        let fileUrl = URL(fileURLWithPath: inputFilePath)
        
        // Write the new contents to the file
        try newContent.write(to: fileUrl, atomically: true, encoding: .utf8)
        
        // Print success message
        print("Success! Updated file saved at: \(fileUrl.absoluteString)")
    }
}

UpdatePreviewProvider.main()

extension Array {
    func chunks(of chunkSize: Int = 10) -> [[Element]] {
        stride(from: 0, to: count, by: chunkSize)
            .map {
                Array(self[$0 ..< Swift.min($0 + chunkSize, count)])
            }
    }
}
