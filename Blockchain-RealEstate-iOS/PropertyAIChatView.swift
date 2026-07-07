//
//  ContentView.swift
//  Blockchain-RealEstate-iOS
//
//  Created by Randall Ridley on 7/7/26.
//

import SwiftUI

struct PropertyAIChatView: View {
    let propertyId: String

    @StateObject private var viewModel = PropertyAIChatViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask about this property")
                .font(.headline)

            HStack(spacing: 10) {
                TextField("e.g., What are the key risks or expected yield?", text: $viewModel.question)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.send)
                    .onSubmit {
                        Task { await viewModel.ask(propertyId: propertyId, token: nil) }
                    }

                Button {
                    Task { await viewModel.ask(propertyId: propertyId, token: nil) }
                } label: {
                    Text(viewModel.isLoading ? "Asking..." : "Ask")
                        .frame(minWidth: 54)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || viewModel.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }

            if !viewModel.answer.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Answer")
                        .font(.subheadline).bold()
                    Text(viewModel.answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if !viewModel.citations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sources")
                        .font(.subheadline).bold()
                    ForEach(viewModel.citations) { c in
                        Text(c.source ?? "reference")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
