import BrewCheck
import SwiftUI

/// Formulae first, then casks. Scrolls from about 12 rows on.
struct PackageListView: View {
    let packages: [OutdatedPackage]

    private static let rowHeight: CGFloat = 22
    private static let maxRows = 12

    private var formulae: [OutdatedPackage] { packages.filter { $0.kind == .formula } }
    private var casks: [OutdatedPackage] { packages.filter { $0.kind == .cask } }

    private var rowCount: Int {
        var count = packages.count
        if !formulae.isEmpty { count += 1 }
        if !casks.isEmpty { count += 1 }
        return count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                section("Formulae", formulae)
                section("Casks", casks)
            }
        }
        .frame(height: CGFloat(min(rowCount, Self.maxRows)) * Self.rowHeight)
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [OutdatedPackage]) -> some View {
        if !items.isEmpty {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(height: Self.rowHeight, alignment: .leading)
            ForEach(items, id: \.key) { package in
                PackageRow(package: package)
                    .frame(height: Self.rowHeight)
            }
        }
    }
}

private struct PackageRow: View {
    let package: OutdatedPackage

    var body: some View {
        HStack(spacing: 6) {
            if package.pinned {
                Image(systemName: "pin")
            }
            Text(package.name)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text("\(package.installedVersions.joined(separator: ", ")) → \(package.currentVersion)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .foregroundStyle(package.pinned ? .secondary : .primary)
    }
}