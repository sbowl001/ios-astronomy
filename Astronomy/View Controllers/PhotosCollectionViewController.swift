//
//  PhotosCollectionViewController.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.fetchMarsRover(named: "curiosity") { (rover, error) in
            if let error = error {
                NSLog("Error fetching info for curiosity: \(error)")
                return
            }
            
            self.roverInfo = rover
        }
    }
    
    // UICollectionViewDataSource/Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoReferences.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCollectionViewCell ?? ImageCollectionViewCell()
        
        loadImage(forCell: cell, forItemAt: indexPath)
        
        return cell
    }
    
    // Make collection view cells fill as much available width as possible
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        var totalUsableWidth = collectionView.frame.width
        let inset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: indexPath.section)
        totalUsableWidth -= inset.left + inset.right
        
        let minWidth: CGFloat = 150.0
        let numberOfItemsInOneRow = Int(totalUsableWidth / minWidth)
        totalUsableWidth -= CGFloat(numberOfItemsInOneRow - 1) * flowLayout.minimumInteritemSpacing
        let width = totalUsableWidth / CGFloat(numberOfItemsInOneRow)
        return CGSize(width: width, height: width)
    }
    
    // Add margins to the left and right side
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10.0, bottom: 0, right: 10.0)
    }
    
    // MARK: - Private
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photoReference = self.photoReferences[indexPath.item]
        guard let fetchOperation = self.operations[photoReference.id] else { NSLog("error cancelling photo request"); return}
        fetchOperation.cancel()
    }
    
    private func loadImage(forCell cell: ImageCollectionViewCell, forItemAt indexPath: IndexPath) {
        
        //Supposed to be part 1
        //         let photoReference = photoReferences[indexPath.item]
        //
        //       let imageURL = photoReference.imageURL
        //
        //        guard let url = imageURL.usingHTTPS else { print("error"); return }
        //
        //        URLSession.shared.dataTask(with: url) { (data, _, error) in
        //            if let _ = error {
        //                NSLog("Error creating data task")
        //                return
        //            }
        //
        //            DispatchQueue.main.async {
        //                if let currentIndexPath = self.collectionView.indexPath(for: cell),
        //                    currentIndexPath != indexPath {
        //                    return
        //                }
        //                if let data = data {
        //                    cell.imageView.image = UIImage(data: data)
        //                }
        //            }
        //        }.resume()
        
        let photoReference = photoReferences[indexPath.item]
        

        
        if let cachedData = self.cache.value(key: photoReference.id) {
            cell.imageView.image = UIImage(data: cachedData)
            return
        }
        let fetchPhotoOperation = FetchPhotoOperation(marsPhotoReference: photoReference)
        
        let storeCacheOperation = BlockOperation {
            if let data = fetchPhotoOperation.imageData {
                    self.cache.cache(value: data, for: photoReference.id)
                }
        }
            let checkReuseOperation = BlockOperation {
                if let currentIndexPath = self.collectionView.indexPath(for: cell),
                    currentIndexPath != indexPath {
                    return
                }
                if let imageData = fetchPhotoOperation.imageData {
                    cell.imageView.image = UIImage(data: imageData)
                }
            }
        storeCacheOperation.addDependency(fetchPhotoOperation)
        checkReuseOperation.addDependency(fetchPhotoOperation)  // Don't really get the adding dependency things
        photoFetchedQueue.addOperation(fetchPhotoOperation)
        photoFetchedQueue.addOperation(storeCacheOperation)
      OperationQueue.main.addOperation(checkReuseOperation)
        self.operations[photoReference.id] = fetchPhotoOperation
     
    }
    
    // Properties
    
    let cache = Cache<Int, Data>()
    private var operations = [Int: Operation]()
    private let client = MarsRoverClient()
    private let photoFetchedQueue = OperationQueue()
    
    private var roverInfo: MarsRover? {
        didSet {
            solDescription = roverInfo?.solDescriptions[3]
        }
    }
    private var solDescription: SolDescription? {
        didSet {
            if let rover = roverInfo,
                let sol = solDescription?.sol {
                client.fetchPhotos(from: rover, onSol: sol) { (photoRefs, error) in
                    if let e = error { NSLog("Error fetching photos for \(rover.name) on sol \(sol): \(e)"); return }
                    self.photoReferences = photoRefs ?? []
                }
            }
        }
    }
    private var photoReferences = [MarsPhotoReference]() {
        didSet {
            DispatchQueue.main.async { self.collectionView?.reloadData() }
        }
    }
    
    @IBOutlet var collectionView: UICollectionView!
}
