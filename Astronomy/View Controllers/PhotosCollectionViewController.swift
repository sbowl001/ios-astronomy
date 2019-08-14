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
        
        //        Get the MarsPhotoReference instance for the passed in indexPath from the photoReferences array property.
        //        Get the URL for the associated image using the imageURL property. Use .usingHTTPS (provided in URL+Secure.swift) to make sure the URL is an https URL. By default, the API returns http URLs.
        //        Create and run a data task to load the image data from the imageURL.
        //        In the data task's completion handler, check for an error, and return early if there is one. Otherwise, create a UIImage from the received data.
        //        Important: Check to see if the current index path for cell is the same one you were asked to load. If not, this means that that item has scrolled off screen and the UICollectionViewCell instance has been reused for a different index path. If this happens, abort setting the image.
        //        If the cell hasn't been reused, set its imageView's image to the UIImage you just created.
        //        Make sure you do all UIKit API calls on the main queue.
        // TODO: Implement image loading here
        
        
        let photoReference = photoReferences[indexPath.item]
        
        let imageURL = photoReference.imageURL
        
        guard let url = imageURL.usingHTTPS else { print("error"); return }
        
        if let cachedData = self.cache.value(key: photoReference.id) {
            cell.imageView.image = UIImage(data: cachedData)
            return
        }
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            if let _ = error {
                NSLog("Error creating data task")
                return
            }
            
            DispatchQueue.main.async {
                if let currentIndexPath = self.collectionView.indexPath(for: cell),
                    currentIndexPath != indexPath {
                    return
                }
                if let data = data {
                    cell.imageView.image = UIImage(data: data)
                    self.cache.cache(value: data, for: photoReference.id)
                }
            }
            }.resume()
    }
    
    // Properties
    
    let cache = Cache<Int, Data>()
    private let client = MarsRoverClient()
    
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
