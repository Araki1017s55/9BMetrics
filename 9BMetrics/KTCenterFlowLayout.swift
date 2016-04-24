//
//  KTCenterFlowLayout.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 23/4/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//  Based in https://github.com/keighl/KTCenterFlowLayout
//

import UIKit

class KTCenterFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]?{
    
        guard let superAttributes = NSArray(array: super.layoutAttributesForElementsInRect(rect)!, copyItems: true) as?[UICollectionViewLayoutAttributes] else {return nil}
        
        var rowCollections = [Float:[UICollectionViewLayoutAttributes]] ()
        
        guard let flowDelegate = self.collectionView!.delegate as? UICollectionViewDelegateFlowLayout else {return nil}
        
        let delegateSupportsInteritemSpacing = flowDelegate.respondsToSelector(#selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:minimumInteritemSpacingForSectionAtIndex:)))
        
    
        for itemAttributes in superAttributes{
            
            // Normalize the midY to others in the row
            // with variable cell heights the midYs can be ever so slightly
            // different.
            
            let midYRound = roundf(Float(CGRectGetMidY(itemAttributes.frame)))
            let midYPlus = midYRound + 1.0
            let midYMinus = midYRound - 1.0
            
            var key : Float?
            
            if rowCollections[midYPlus] != nil {
                key = midYPlus
            }
            
            if rowCollections[midYMinus] != nil {
                key = midYMinus
            }
                        
            if key == nil {
                key = midYRound
            }
            
            if rowCollections[key!] == nil{
                rowCollections[key!] = [UICollectionViewLayoutAttributes]()
            }
            
            rowCollections[key!]!.append(itemAttributes)
       }
        
        let collectionViewWidth = CGRectGetWidth(self.collectionView!.bounds) - self.collectionView!.contentInset.left - self.collectionView!.contentInset.right
        
        for (_, itemAttributesCollection) in rowCollections {
            let itemsInRow = itemAttributesCollection.count
            
            var interitemSpacing = self.minimumInteritemSpacing
            
            
            if delegateSupportsInteritemSpacing && itemsInRow > 0
            {
                let section : Int = itemAttributesCollection[0].indexPath.section
                interitemSpacing = flowDelegate.collectionView!(self.collectionView!,layout:self,minimumInteritemSpacingForSectionAtIndex:section)
            }
 
                // Sum the width of all elements in the row
            
            let aggregateInteritemSpacing = interitemSpacing * CGFloat(itemsInRow - 1)
            
            var aggregateItemWidths : CGFloat = 0.0
            
            for itemAttributes in itemAttributesCollection{
                aggregateItemWidths += CGRectGetWidth(itemAttributes.frame)
            }
            
            // Build an alignment rect
            // |==|--------|==|
            let alignmentWidth = aggregateItemWidths + aggregateInteritemSpacing
            let alignmentXOffset = (collectionViewWidth - alignmentWidth) / 2.0
           
            // Adjust each item's position to be centered
            var previousFrame = CGRectZero
            
            for itemAttributes in itemAttributesCollection
            {
                var itemFrame = itemAttributes.frame
                
                if CGRectEqualToRect(previousFrame, CGRectZero){
                    itemFrame.origin.x = alignmentXOffset
                    
                }else{
                    itemFrame.origin.x = CGRectGetMaxX(previousFrame) + interitemSpacing
                }
                
                itemAttributes.frame = itemFrame
                previousFrame = itemFrame
            }
        }
        
        return superAttributes;
        
    }



}
