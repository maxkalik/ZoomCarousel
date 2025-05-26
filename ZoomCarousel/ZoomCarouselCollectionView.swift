//
//  ZoomCarouselCollectionView.swift
//  ZoomCarousel
//
//  Created by Max Kalik on 25/05/2025.
//

import UIKit
import SwiftUI

protocol ZoomCarouselCollectionViewDelegate: AnyObject {
    func horizontalWheelWillStartScroll()
    func horizontalWheelDidEndScroll()
}

final class ZoomCarouselCollectionView<Item: Identifiable, Content: View>: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    weak var scrollDelegate: ZoomCarouselCollectionViewDelegate?
    
    let flowLayout = ZoomCarouselFlowLayout()
    
    private let items: [Item]
    private let defaultPosition: Int
    private var content: ((Item) -> Content)
    private var setDefaultPosition = false
    private let cellReuseIdentifier = "HorizontalCarouselCollectionCell"
    
    init(
        items: [Item],
        defaultPosition: Int,
        itemSize: CGSize,
        spacing: CGFloat,
        sideItemScale: CGFloat,
        sideItemShift: CGFloat,
        verticalOffset: CGFloat,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.defaultPosition = defaultPosition
        self.content = content
        
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = itemSize
        flowLayout.spacing = spacing
        flowLayout.sideItemScale = sideItemScale
        flowLayout.sideItemShift = sideItemShift
        flowLayout.verticalOffset = verticalOffset
        
        super.init(frame: .zero, collectionViewLayout: flowLayout)
        
        backgroundColor = .clear
        showsHorizontalScrollIndicator = false
        dataSource = self
        register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !setDefaultPosition {
            setDefaultPosition = true
            scrollToItem(
                at: .init(row: defaultPosition, section: 0),
                at: .centeredHorizontally,
                animated: false
            )
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        guard let viewModel = self.item(at: indexPath.item) else {
            return .init()
        }
        cell.contentConfiguration = UIHostingConfiguration {
            content(viewModel)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        guard let itemAttributes = layout.layoutAttributesForItem(at: indexPath) else { return }
        let finalContentOffsetX = proposedContentOffset(for: itemAttributes, scrollView: collectionView)
        
        // Perform the scrolling to the calculated content offset
        collectionView.setContentOffset(CGPoint(x: finalContentOffsetX, y: 0), animated: true)
    }
    
    func item(at index: Int) -> Item? {
        guard items.indices.contains(index) else { return nil }
        return items[index]
    }
    
    // MARK: - Proposed item and velocity
    
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollDelegate?.horizontalWheelWillStartScroll()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollDelegate?.horizontalWheelDidEndScroll()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let scaledScrollDistance = increaseVelocity(velocity, multiplier: 2)
        let proposedOffsetX = scrollView.contentOffset.x + scaledScrollDistance

        let offset = self.targetContentOffset(proposedOffset: proposedOffsetX, scrollView: scrollView)
        targetContentOffset.pointee = offset
    }
    
    func targetContentOffset(proposedOffset x: CGFloat, scrollView: UIScrollView) -> CGPoint {
        let proposedOffset = CGPoint(
            x: x,
            y: scrollView.contentOffset.y
        )
        
        guard let layoutAttributes = (collectionViewLayout as? ZoomCarouselFlowLayout)?
            .layoutAttributesForElements(
                in: CGRect(
                    x: proposedOffset.x,
                    y: scrollView.contentOffset.y,
                    width: scrollView.bounds.width,
                    height: scrollView.bounds.height
                )
            ) else { return proposedOffset }

        if layoutAttributes.count > 3,
           let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            let closest = layoutAttributes[2]
            
            guard let itemAttributes = layout.layoutAttributesForItem(at: closest.indexPath) else {
                return proposedOffset
            }
            
            let finalContentOffsetX = proposedContentOffset(for: itemAttributes, scrollView: scrollView)
            return .init(x: finalContentOffsetX, y: proposedOffset.y)
        } else if layoutAttributes.count == 3,
            let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            let closest = layoutAttributes[1]
            
            guard let itemAttributes = layout.layoutAttributesForItem(at: closest.indexPath) else {
                return proposedOffset
            }
            
            let finalContentOffsetX = proposedContentOffset(for: itemAttributes, scrollView: scrollView)
            return .init(x: finalContentOffsetX, y: proposedOffset.y)
        } else {
            return proposedOffset
        }
    }
    
    private func increaseVelocity(_ velocity: CGPoint, multiplier: CGFloat) -> CGFloat {
        // Multiply the velocity by the multiplier to increase momentum
        let modifiedVelocity = CGPoint(x: velocity.x * multiplier, y: velocity.y)
        
        // Dynamically calculate the scroll distance based on item size and collection view size
        let itemWidth = (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize.width ?? 0
        return modifiedVelocity.x * itemWidth
    }
}

private func proposedContentOffset(for itemAttributes: UICollectionViewLayoutAttributes, scrollView: UIScrollView) -> CGFloat {
    let scrollViewCenter = scrollView.bounds.size.width / 2
    let itemCenterX = itemAttributes.center.x
    
    // Calculate the offset to center the item
    let targetContentOffsetX = itemCenterX - scrollViewCenter
    // Ensure that the content offset stays within the bounds of the collection view
    let maxOffsetX = scrollView.contentSize.width - scrollView.bounds.width
    let minOffsetX: CGFloat = 0
    return max(minOffsetX, min(targetContentOffsetX, maxOffsetX))
}
