// MiniMartManager/Utilities/Views/QuantityInputView.swift
import SwiftUI

struct QuantityInputView: View {
    @Binding var quantity: Int
    var range: ClosedRange<Int> = 1...99999
    
    var focusedField: FocusState<POSFocusField?>.Binding
    var focusValue: POSFocusField

    var body: some View {
        HStack(spacing: 0) {
            // SỬA LỖI: Dùng lại Button nhưng với contentShape
            Button {
                if quantity > range.lowerBound {
                    quantity -= 1
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle()) // Đảm bảo vùng bấm lớn và nhạy

            TextField("", value: $quantity, formatter: numberFormatter)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(minWidth: 40, maxWidth: 60)
                .padding(.vertical, 4)
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(8)
                .focused(focusedField, equals: focusValue)

            // SỬA LỖI: Dùng lại Button nhưng với contentShape
            Button {
                if quantity < range.upperBound {
                    quantity += 1
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .contentShape(Rectangle()) // Đảm bảo vùng bấm lớn và nhạy
        }
        .font(.headline)
    }
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }
}
