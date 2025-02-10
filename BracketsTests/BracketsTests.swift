//
//  BracketsTests.swift
//  BracketsTests
//
//  Created by Caleb Hearth on 2/4/25.
//

import Testing
import Foundation

struct BracketsTests {

	@Test func example() async throws {
		let taskString = "  - [x] Follow up about contract with Ascent ➕ 2025-02-01 📅 2025-02-03 ✅ 2025-02-03 #house"
		let todoTask = TodoTask(
			scanning: taskString,
			from: .applicationDirectory,
			at: taskString.range(of: taskString)!
		)

		#expect(todoTask.tokens == [
			.whitespace("  "),
			.listMarker("-"),
			.whitespace(" "),
			.checkbox("x"),
			.whitespace(" "),
			.text("Follow up about contract with Ascent "),
			.added("➕", [.whitespace(" "), .date(date(from: "2025-02-01")), .whitespace(" ")]),
			.due("📅", [.whitespace(" "), .date(date(from: "2025-02-03")), .whitespace(" ")]),
			.completed("✅", [.whitespace(" "), .date(date(from: "2025-02-03")), .whitespace(" ")]),
			.tag("house")
		])
		#expect(todoTask.description == taskString)
	}

	func date(from: String) -> Date {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd"
		return dateFormatter.date(from: from)!
	}
}
