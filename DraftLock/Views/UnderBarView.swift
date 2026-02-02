import SwiftUI

struct UnderBarView: View {
    @ObservedObject var vm: UnderBarViewModel

    var body: some View {
        HStack(spacing: 14) {
            Group {
                Text("Now:")
                    .foregroundStyle(.secondary)

                if let tokens = vm.currentInputTokens {
                    Text("in \(tokens) tok")
                } else {
                    Text("in -- tok")
                }

                if let cost = vm.currentEstimatedCost {
                    Text("est \(formatUSD(cost))")
                } else {
                    Text("est --")
                }
            }

            Divider()
                .frame(height: 18)

            Group {
                Text("Total:")
                    .foregroundStyle(.secondary)

                Text("in \(vm.totalInputTokens) tok")
                Text("out \(vm.totalOutputTokens) tok")
                Text("\(formatUSD(vm.totalCost))")
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .font(.callout)
    }

    private func formatUSD(_ value: Double) -> String {
        // MVP: USD固定。将来は通貨切替でNumberFormatterへ。
        return String(format: "$%.6f", value)
    }
}
