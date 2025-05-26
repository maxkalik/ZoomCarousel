//
//  ContentView.swift
//  ZoomCarousel
//
//  Created by Max Kalik on 25/05/2025.
//

import SwiftUI

struct ItemViewModel: Identifiable {
    let id: String
}

struct ContentView: View {
    @State var selectedIndex: Int = 3
    @State var items: [ItemViewModel] = [
        .init(id: "0"),
        .init(id: "1"),
        .init(id: "2"),
        .init(id: "3"),
        .init(id: "4"),
        .init(id: "5"),
        .init(id: "6"),
        .init(id: "7"),
        .init(id: "8"),
        .init(id: "9")
    ]
    
    var body: some View {
        ZStack {
            ZoomCarouselView(
                selectedIndex: $selectedIndex,
                items: items,
                itemSize: .init(width: 120, height: 120),
                spacing: 0,
                sideItemScale: 0.8,
                content: { item in
                    ZStack {
                        Text(item.id)
                    }
                    .frame(width: 120, height: 120)
                    .background(Color.random())
                    .cornerRadius(10)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: 120)
//            .onChange(of: selectedIndex) { _ in }
            .onAppear {
                DispatchQueue.main.async {
                    self.selectedIndex = 6
                }
            }
        }
    }
}

extension Color {
    static func random() -> Color {
        return Color(hue: .random(in: 0.0...1.0),
                       saturation: .random(in: 0.5...1.0),
                       brightness: .random(in: 0.5...1.0))
    }
}


#Preview {
    ContentView()
}
