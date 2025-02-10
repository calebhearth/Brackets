//
//  Directory.swift
//  Brackets
//
//  Created by Caleb Hearth on 2/4/25.
//

import Foundation

struct Directory {
	let root: URL
	var files: [File] {
		guard root.startAccessingSecurityScopedResource() else { return [] }
//		defer { root.stopAccessingSecurityScopedResource() }
		let resourceKeys: Set<URLResourceKey> = [.fileContentIdentifierKey, .isReadableKey, .isWritableKey]
		let directoryEnumerator = FileManager.default
			.enumerator(
				at: root,
				includingPropertiesForKeys: Array(resourceKeys),
				options: [.skipsHiddenFiles]
			)
		guard let directoryEnumerator else { return [] }

		var urls: [URL] = []
		for case let url as URL in directoryEnumerator {
			guard !url.hasDirectoryPath else { continue }
//			guard let resourceValues = try? url.resourceValues(forKeys: resourceKeys),
//						let contentIdentifier = resourceValues.fileContentIdentifier,
//						let isReadable = resourceValues.isReadable,
//						let isWritable = resourceValues.isWritable
//			else {
//				continue
//			}

			guard let fileContents = try? String(contentsOf: url, encoding: .utf8) else { continue }
			if fileContents
				.split(omittingEmptySubsequences: true, whereSeparator: \.isNewline)
				.contains(where: { $0.contains(File.taskRegex)} ) {
				urls.append(url)
			}
		}
		return urls.map(File.init)
	}
}

struct File: Identifiable, Hashable {
	public static let taskRegex = /^(?<indentation>[ \t>]*)(?<listMarker>(?:[-*+]|[0-9]+\.) +)\[(?<status>.)\](?<text>.*)/.anchorsMatchLineEndings()
	let url: URL
	var id: URL { url }

	var fileContents: String? {
//		guard url.startAccessingSecurityScopedResource() else { return nil }
//		defer { url.stopAccessingSecurityScopedResource() }
		return try? String(contentsOf: url, encoding: .utf8)
	}

	var hasTasks: Bool {
		!tasks.isEmpty
	}

	var tasks: [TodoTask] {
		guard let fileContents else { return [] }
		return fileContents
			.matches(of: File.taskRegex)
			.map { match in
				TodoTask(scanning: String(match.output.0), from: url, at: match.range)
			}
	}

//	var tasks: LazySequence<[TodoTask]> {
//		guard let fileContents else { return [].lazy }
//		return fileContents
//			.split(omittingEmptySubsequences: true, whereSeparator: \.isNewline)
//			.lazy
//			.compactMap { line in
////				guard let match = File.taskRegex.wholeMatch(in: line) else { return nil }
//				return TodoTask(fileURL: url)
//			}
//	}
}

struct TodoTask: CustomStringConvertible, Hashable {
	let fileURL: URL
	let range: Range<String.Index>
	let tokens: [TaskToken]

	init(scanning task: String, from fileURL: URL, at range: Range<String.Index>) {
		let scanner = Scanner(string: task)
		var taskTokens: [TaskToken] = []
		scanner.charactersToBeSkipped = .none

		if let indentation = scanner.scanCharacters(from: .whitespaces) {
			taskTokens.append(.whitespace(indentation))
		}
		if let listMarker = scanner.scanCharacters(from: ["-", "*", "+"]) {
			taskTokens.append(.listMarker(listMarker))
		}
		if let space = scanner.scanCharacters(from: .whitespaces) {
			taskTokens.append(.whitespace(space))
		}
		if let whatIsThis = scanner.scanUpToString("[") {
			taskTokens.append(.text(whatIsThis))
		}
		_ = scanner.scanString("[")
		let status = scanner.scanUpToString("]")
		taskTokens.append(.checkbox(status ?? ""))
		_ = scanner.scanString("]")
		if let space = scanner.scanCharacters(from: .whitespaces) {
			taskTokens.append(.whitespace(space))
		}

		while !scanner.isAtEnd {
			if let symbol = scanner.scanCharacters(from: .init(["🛫", "➕", "⏳", "📅", "✅", "❌"])) {
				var children: [TaskToken] = []
				if let space = scanner.scanCharacters(from: .whitespaces) {
					children.append(.whitespace(space))
				}
				if let dateString = scanner.scanCharacters(from: .decimalDigits.union(.init(charactersIn: "-"))) {
					let dateFormatter = DateFormatter()
					dateFormatter.dateFormat = "yyyy-MM-dd"
					if let date = dateFormatter.date(from: String(dateString)) {
						children.append(.date(date))
					}
				}
				if let space = scanner.scanCharacters(from: .whitespaces) {
					children.append(.whitespace(space))
				}
				switch symbol {
				case "➕": taskTokens.append(.added(symbol, children))
				case "📅": taskTokens.append(.due(symbol, children))
				case "✅": taskTokens.append(.completed(symbol, children))
				default:
					taskTokens.append(.text(symbol))
					children.forEach { taskTokens.append($0) }
				}
				continue
			}
			if scanner.scanString("#") != nil {
				if let tagName = scanner.scanUpToCharacters(from: .whitespaces) {
					taskTokens.append(.tag(tagName))
				} else {
					taskTokens.append(.text("#"))
				}
				continue
			}
			if let space = scanner.scanCharacters(from: .whitespaces) {
				taskTokens.append(.whitespace(space))
				continue
			}
			if let text = scanner.scanCharacters(from: .alphanumerics.union(.whitespaces).union(.punctuationCharacters)) {
				taskTokens.append(.text(text))
				continue
			}
			break
		}
		var rest = ""
		while !scanner.isAtEnd {
			rest.append(scanner.scanCharacter() ?? Character(""))
		}
		if !rest.isEmpty {
			taskTokens.append(.text(rest))
		}

		self.tokens = taskTokens
		self.fileURL = fileURL
		self.range = range
	}

	var description: String {
		return tokens.map(\.description).joined()
	}
}

enum TaskToken: Equatable, Hashable {
	case whitespace(String)
	case listMarker(String)
	case checkbox(String)
	case text(String)
	case added(String, [TaskToken])
	case due(String, [TaskToken])
	case completed(String, [TaskToken])
	case date(Date)
	case tag(String)

	var description: String {
		switch self {
		case .whitespace(let s), .listMarker(let s), .text(let s):
			return s
		case .checkbox(let s):
			return "[\(s)]"
		case .added(let s, let children), .due(let s, let children), .completed(let s, let children):
			return s + children.map(\.description).joined()
		case .date(let date):
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "yyyy-MM-dd"
			return dateFormatter.string(from: date)
		case .tag(let s):
			return "#\(s)"
		}
	}
}
