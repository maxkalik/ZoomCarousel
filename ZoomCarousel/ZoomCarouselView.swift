//
//  ZoomCarouselView.swift
//  ZoomCarousel
//
//  Created by Max Kalik on 25/05/2025.
//

import UIKit
import SwiftUI
import Combine

struct ZoomCarouselView<Item: Identifiable, Content: View>: UIViewRepresentable {
    
    @Binding var selectedIndex: Int
    private let collectionView: ZoomCarouselCollectionView<Item, Content>
    private var content: ((Item) -> Content)
    
    init(
        selectedIndex: Binding<Int>,
        items: [Item],
        itemSize: CGSize,
        spacing: CGFloat = 10,
        sideItemScale: CGFloat = 1,
        sideItemShift: CGFloat = 0,
        verticalOffset: CGFloat = 0,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        _selectedIndex = selectedIndex
        self.collectionView = ZoomCarouselCollectionView(
            items: items,
            defaultPosition: selectedIndex.wrappedValue,
            itemSize: itemSize,
            spacing: spacing,
            sideItemScale: sideItemScale,
            sideItemShift: sideItemShift,
            verticalOffset: verticalOffset,
            content: content
        )
        self.content = content
        self.collectionView.delegate = collectionView
    }
    
    func makeUIView(context: Context) -> ZoomCarouselCollectionView<Item, Content> {
        
        collectionView.flowLayout.delegate = context.coordinator
        collectionView.scrollDelegate = context.coordinator
        return collectionView
    }
    
    func updateUIView(_ collectionView: ZoomCarouselCollectionView<Item, Content>, context: Context) {
        collectionView.collectionView(collectionView, didSelectItemAt: .init(row: selectedIndex, section: 0))
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ZoomCarouselFlowLayoutDelegate, ZoomCarouselCollectionViewDelegate {
        
        private(set) var lastUpdatedIndexPath: IndexPath?
        
        var parent: ZoomCarouselView
        
        init(_ parent: ZoomCarouselView) {
            self.parent = parent
            super.init()
        }

        func carouselFlowLayout(_ carouselFlowLayout: UICollectionViewFlowLayout, collectionView: UICollectionView, currentIndexPath indexPath: IndexPath) {
            lastUpdatedIndexPath = indexPath
        }
        
        func horizontalWheelWillStartScroll() {
            print("*************** will start scroll")
        }
        
        func horizontalWheelDidEndScroll() {
            print("*************** did end scroll")
        }
    }
}

