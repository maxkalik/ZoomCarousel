//
//  ZoomCarouselFlowLayout.swift
//  ZoomCarousel
//
//  Created by Max Kalik on 25/05/2025.
//

import UIKit

protocol ZoomCarouselFlowLayoutDelegate: AnyObject {
    func carouselFlowLayout(_ carouselFlowLayout: UICollectionViewFlowLayout, collectionView: UICollectionView, currentIndexPath indexPath: IndexPath)
}

class ZoomCarouselFlowLayout: UICollectionViewFlowLayout {
    
    weak var delegate: ZoomCarouselFlowLayoutDelegate?
    
    fileprivate struct LayoutState {
        var size: CGSize
        
        func isEqual(_ otherState: LayoutState) -> Bool {
            size.equalTo(otherState.size)
        }
    }
    
    var sideItemScale: CGFloat = 1
    var sideItemShift: CGFloat = 0
    var verticalOffset: CGFloat = 0 // change for horizontal layout
    var spacing: CGFloat = 10
    
    private var currentIndex: Int?
    
    private var state = LayoutState(size: CGSize.zero)
    
    override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        
        let currentState = LayoutState(
            size: collectionView.bounds.size
        )
        
        if !state.isEqual(currentState) {
            setupCollectionView()
            updateLayout()
            state = currentState
        }
    }
    
    private func setupCollectionView() {
        guard let collectionView else { return }
        if collectionView.decelerationRate != UIScrollView.DecelerationRate.fast {
            collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        }
    }
    
    private func updateLayout() {
        guard let collectionView else { return }
        
        let collectionSize = collectionView.bounds.size
        let xInset = (collectionSize.width - itemSize.width) / 2
        let yInset = (collectionSize.height - itemSize.height) / 2
        self.sectionInset = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
        
        let itemWidth = itemSize.width
        let scaledItemOffset = (itemWidth - itemWidth * sideItemScale) / 2
        minimumLineSpacing = spacing - scaledItemOffset
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superAttributes = super.layoutAttributesForElements(in: rect),
              let attributes = NSArray(array: superAttributes, copyItems: true) as? [UICollectionViewLayoutAttributes]
        else { return nil }

        return attributes.map { self.transformLayoutAttributes($0) }
    }
    
    fileprivate func transformLayoutAttributes(_ attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let collectionView else { return attributes }

        let collectionCenter = collectionView.frame.size.width / 2
        let offset = collectionView.contentOffset.x
        let normalizedCenter = attributes.center.x - offset
        let maxDistance = itemSize.width + minimumLineSpacing
        let distanceFromCenter = abs(collectionCenter - normalizedCenter)
        let ratio = (maxDistance - distanceFromCenter) / maxDistance
        let scale = ratio * (1 - sideItemScale) + sideItemScale
        let yOffset = (1 - ratio) * sideItemShift
        
        attributes.transform3D = CATransform3DScale(CATransform3DIdentity, scale, scale, 1)
        attributes.zIndex = Int(ratio * 10)
        attributes.center.y += verticalOffset + yOffset
        
        let xOffset = pow(1 - ratio, 2) * 20
        let preciseXOffset = Double(round(1000 * xOffset) / 1000)
        
        if normalizedCenter < collectionCenter {
            attributes.center.x += preciseXOffset
        } else {
            attributes.center.x -= preciseXOffset
        }
        
        // A tweek to hide the bottom layer of the items
        attributes.isHidden = ratio < -2
        
        // Notify the delegate if the current item is in the center
        if roundRatio(ratio) == 1, currentIndex != attributes.indexPath.row {
            delegate?.carouselFlowLayout(self, collectionView: collectionView, currentIndexPath: attributes.indexPath)
            currentIndex = attributes.indexPath.row
        }

        return attributes
    }
}

private func roundRatio(_ ratio: Double) -> Int {
    return ratio < 0.5 ? 0 : 1
}
