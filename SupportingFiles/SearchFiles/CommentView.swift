//
//  CommentView.swift
//  SmartLoadCell
//
//  Created by Balázs Szamódy on 30/1/2023.
//

import SwiftUI
import Combine

struct CommentView: View {
	@Environment(\.dismiss)
	private var dismiss

	@ObservedObject
	var viewModel: CommentViewModel

	@FocusState
	private var isCommentFocused: Bool

    var body: some View {
		NavigationView {
			VStack(spacing: 16) {
				TextField(Strings.comment, text: $viewModel.comment)
					.textFieldStyle(.roundedBorder)
					.focused($isCommentFocused)
				HStack(spacing: 0) {
					Toggle(isOn: $viewModel.isRememberOn) {
						Text("Remember")
					}
					.fixedSize(horizontal: true, vertical: false)
					Spacer()
					Toggle(isOn: $viewModel.isAutoIndexingOn) {
						Text("Auto indexing")
							.foregroundColor(viewModel.isRememberOn ? .primary : .primary.opacity(0.5))
					}
					.disabled(!viewModel.isRememberOn)
					.fixedSize(horizontal: true, vertical: false)
				}
				Spacer()
			}
			.padding(.horizontal)
			.navigationTitle(Strings.comment)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button {
						dismiss()
					} label: {
						Text(Strings.ok)
							.fontWeight(.bold)
					}
					.buttonBorderShape(.capsule)
					.buttonStyle(.bordered)
					.tint(.primary)
				}
			}
			.ignoresSafeArea(edges: .bottom)
		}
		.onAppear {
			isCommentFocused = true
		}
    }
}

struct CommentView_Previews: PreviewProvider {
    static var previews: some View {
		CommentView(viewModel: CommentViewModel(.init("My Comment"), isRememberOn: true, isAutoIndexOn: false))
		CommentView(viewModel: CommentViewModel(.init(nil), isRememberOn: true, isAutoIndexOn: false))
    }
}
