//
//  File.swift
//  
//
//  Created by Balázs Szamódy on 20/5/2023.
//

import Foundation
import ArgumentParser
import RegexBuilder

enum PreviewShowcaseError: LocalizedError {
	case mainStackNotFound
	var errorDescription: String? {
		String(describing: self)
	}
}

public class PreviewShowcaseUpdater: ParsableCommand {
	public init(inputFilePath: URL,
				changesOnly: Bool = false,
				indentSpaceCount: Int?,
				justGenerate: Bool = false,
				searchPath: String? = nil,
				excludedFolders: [String] = []) {
		self.inputFileUrl = inputFilePath
		self.changesOnly = changesOnly
        if let indentSpaceCount {
            self.indentSpaceCount = indentSpaceCount
            self.isSpaceIndent = true
        }
		self.justGenerate = justGenerate
		self.searchPath = searchPath
		self.excludedFolders = excludedFolders
	}
	
	// Input file path
	@Argument(help: "The path to the Swift file that contains the VStack with previews")
	var inputFileUrl: URL
	
	// Changes only
	@Flag(name: .shortAndLong, help: "Only search in changed files based on git status")
	var changesOnly = false
	
	@Flag(help: "Debug flag, please don't use for code generation")
	var justGenerate = false
	
	@Option(parsing: .next, help: "Number of spaces for space indentation. Defaults to `4`")
    var indentSpaceCount: Int = 0
	
	@Option(help: "Search path when searching for all .swift files")
	var searchPath: String?
	
	@Option(parsing: .upToNextOption, help: "Comma separated list of folders to exclude")
	var excludedFolders: [String] = []
	
	var isSpaceIndent = false
	
	var indent: String {
		isSpaceIndent
			? Array(0..<4)
				.map({ _ in " "})
				.reduce("", +)
			: "\t"
	}
	
	public required init() {}
	
	public func run() throws {
		
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
		let inputFileContent = try getContent(of: inputFileUrl)
		
		// Get main stack indent
		let stackIndent = try getMainVStackIndent(inputFileContent)
		
		isSpaceIndent = !stackIndent.contains("\t")
		
		// Get input content of main stack
		let stackContent = try getStackContent(from: inputFileContent, closingIndent: stackIndent)
		
		// Get existing preview struct names in the input file
		let existingPreviewStructNames = try getExistingPreviewStructNames(from: stackContent)
		
		// Get existing deisabled previews
		// TODO: 👆
		
		// Get all preview provider struct names
		let previewProviderStructNames = try getPreviewProviderStructNames(filesToSearch: filesToSearch)
		
		// Get preview struct names to add
		let previewStructNamesToAdd = Array(previewProviderStructNames).filter { !existingPreviewStructNames.contains($0) }
		
		// Generate new preview struct code
		let newPreviewStructsCode = generateNewPreviewCode(
			existingStructNames: existingPreviewStructNames,
			newStructNames: previewStructNamesToAdd,
			stackIndent: stackIndent)
		
		// Update file content
        let updatedContent = try updatedContent(with: newPreviewStructsCode, in: inputFileContent, stackIndent: stackIndent)
		print(updatedContent)
		guard !justGenerate else {
			print("Success! New Previews generated")
			return
		}
		
		// Update input file
		try updateInputFile(updatedContent)
		
		// Print success message
		print("Success! Updated previews in \(inputFileUrl)")
	}
	
	func getChangedFiles() throws -> [URL] {
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
	
	func getAllSwiftFiles() -> [URL] {
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
	
	func filterExcludedFolders(_ input: [URL]) -> [URL] {
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
	
	func getPreviewProviderStructNames(filesToSearch: [URL]) throws -> Set<String> {
		let matches = try filesToSearch
			.compactMap { fileURL -> [String]? in
				guard fileURL.absoluteString.contains(".swift") else {
					return nil
				}
				
				let content = try String(contentsOf: fileURL)
				
				let matches = getPreviewProviderNames(from: content)
				if !matches.isEmpty {
					print("Found previews in:\n\(fileURL)")
				}
				return matches
			}
			.reduce([], +)
		
		return Set(matches)
	}
	
	func getPreviewProviderNames(from fileContent: String) -> [String] {
		let regex = Regex {
			ZeroOrMore(.whitespace)
			"struct"
			OneOrMore(.whitespace)
			Capture {
				OneOrMore {
					CharacterClass(
						.anyOf("_"),
						.word,
						("0"..."9")
					)
				}
			} transform: {
				String($0)
			}
			ZeroOrMore(.whitespace)
			":"
			ZeroOrMore(.whitespace)
			"PreviewProvider"
		}
			.anchorsMatchLineEndings()
		
		return fileContent.matches(of: regex).map({ $0.output.1 })
	}
	
	func getContent(of fileUrl: URL) throws -> String {
		try String(contentsOfFile: fileUrl.absoluteString)
	}
	
	func getMainVStackIndent(_ inputContent: String) throws -> String {
		let regex = Regex {
			"\n"
			Capture {
				ZeroOrMore(.whitespace)
			} transform: {
				String($0)
			}
			"LazyVStack"
			ZeroOrMore(.whitespace)
			"{"
		}
			.anchorsMatchLineEndings()
		
		guard let result = try regex
			.firstMatch(in: inputContent)?
			.output.1 else {
			throw PreviewShowcaseError.mainStackNotFound
		}
		
		return result
	}
	
	func getStackContent(from inputContent: String, closingIndent: String) throws -> String {
		let regex = Regex {
			OneOrMore(.whitespace)
			"LazyVStack {\n"
			Capture {
				OneOrMore(.any)
				"\n"
			} transform: {
				String($0)
			}
			"\(closingIndent)}\n"
		}
		
		let result = try regex.firstMatch(in: inputContent)?.output.1 ?? ""
		return result
	}
	
	func getExistingPreviewStructNames(from inputStackContent: String) throws -> [String] {
		let regex = Regex {
			OneOrMore(.whitespace)
			Capture {
				OneOrMore(
					CharacterClass(
						.word,
						("0"..."9"),
						.anyOf("_")
					)
				)
			} transform: {
				String($0)
			}
			".previews"
		}
			.anchorsMatchLineEndings()
		
		let result = inputStackContent.matches(of: regex).map({ $0.output.1 })
		
		return result
	}
	
	func generateNewPreviewCode(existingStructNames: [String], newStructNames: [String], stackIndent: String) -> String {
		// TODO: decide if all should be alphabetical order
		let newStructNames = Array(newStructNames).sorted()
		let previews = (existingStructNames + newStructNames).map { $0 + ".previews" }
		let stackContent = toGroups(previews, scopeIndent: stackIndent + self.indent)
		return """
            \(stackIndent)LazyVStack {
            \(stackContent)
            \(stackIndent)}
            """
	}
	
	func toGroups(_ input: [String], scopeIndent: String) -> String {
        let tokens = input.toContentTokens()
        return tokens.toText(with: self.indent, scopeIndent: scopeIndent)
	}
	
    func updatedContent(with newStack: String, in inputContent: String, stackIndent: String) -> String {
        let regex = Regex {
            stackIndent
            "LazyVStack {"
            OneOrMore(.newlineSequence)
            ZeroOrMore(.any)
            stackIndent
            "}"
        }
        
        return inputContent.replacing(regex) { match in
            newStack
        }
	}
	
	private func updateInputFile(_ newContent: String) throws {
		
		// Write the new contents to the file
		try newContent.write(to: inputFileUrl, atomically: true, encoding: .utf8)
		
		// Print success message
		print("Success! Updated file saved at: \(inputFileUrl.absoluteString)")
	}
}

extension Array {
	func chunks(of chunkSize: Int = 10) -> [[Element]] {
		stride(from: 0, to: count, by: chunkSize)
			.map {
				Array(self[$0 ..< Swift.min($0 + chunkSize, count)])
			}
	}
}

indirect enum ContentToken: Equatable {
    case group([ContentToken])
    case line(String)
    
    func toText(with indent: String, scopeIndent: String) -> String {
        switch self {
        case .group(let array):
            return """
            \(scopeIndent)Group {
            \(array.toText(with: indent, scopeIndent: scopeIndent + indent))
            \(scopeIndent)}
            """
        case .line(let string):
            return """
            \(scopeIndent)\(string)
            """
        }
    }
}

extension Array where Element == String {
	func linesJoined(with indent: String) -> String {
		map({ indent + $0 })
			.joined(separator: "\n")
	}
    
    func toContentTokens() -> [ContentToken] {
        guard count > 10 else {
            return map({ .line($0) })
        }
        return chunks() // to groups of max 10 lines
            .map({
                .group($0.map({ .line($0) }))
            })
            .toGroups() // to groups of max 10 groupd
    }
}

extension Array where Element == ContentToken {
    func toGroups() -> [ContentToken] {
        let groups: [ContentToken] = chunks()
            .map({ .group($0) })
        
        switch groups.count {
        case ...1:
            return self
        case ...10:
            return groups
        default:
            return groups.toGroups()
        }
    }
    
    func toText(with indent: String, scopeIndent: String) -> String {
        map { token in
            token.toText(with: indent, scopeIndent: scopeIndent)
        }.joined(separator: "\n")
    }
}

extension URL: ExpressibleByArgument {
	public init?(argument: String) {
		guard let url = URL(string: argument) else {
			return nil
		}
		
		self = url
	}
}

extension String {
    static func indent(to level: Int, base indent: String) -> String {
        Array(repeating: indent, count: level)
            .joined()
    }
}
