//
//  BatchProgressBar.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 13/02/2026.
//


import SwiftUI

struct BatchProgressBar: View {
    let items: [BatchItem]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Spacer()
                ForEach(items) { item in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.mark.color)
                        .frame(width: 18, height: 18)
                        .animation(.easeInOut(duration: 0.25), value: item.mark)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
        }
        .defaultScrollAnchor(.center)
    }
}
