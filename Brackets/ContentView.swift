//
//  ContentView.swift
//  Brackets
//
//  Created by Caleb Hearth on 2/4/25.
//

import SwiftUI

struct ContentView: View {
	@State private var rootDirectoryURL: URL? //= .init(string: "/Users/caleb/code/tasks")
	@State private var isPresented = false
	var body: some View {
		List {
			if let rootDirectoryURL {
				ForEach(Directory(root: rootDirectoryURL).files, id: \.self) { file in
						Section(file.url.lastPathComponent) {
							ForEach(file.tasks, id: \.self) { task in
//								let description: LocalizedStringKey = task.description
								Text(task.description)
//								Label("\(task.description)", systemImage: "checkmark.circle")
							}
						}
				}
			}
		}
		.overlay {
			if rootDirectoryURL == nil {
				ContentUnavailableView {
					Label("Select a Directory to Begin", systemImage: "folder.badge.plus")
				} description: {
					Text("Select the directory with files containing your task list.")
				} actions: {
					Button("Select Directory") {
						isPresented = true
					}
				}
			}
		}
		.fileImporter(isPresented: $isPresented, allowedContentTypes: [.directory, .symbolicLink]) {
			if case let .success(url) = $0 {
				rootDirectoryURL = url
			}
		}
	}
}

#Preview {
	ContentView()
}
