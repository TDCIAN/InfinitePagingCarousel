//
//  ImagesViewModel.swift
//  InfinitePagingCarousel
//
//  Created by 김정민 on 2/22/25.
//

import UIKit
import RxSwift
import RxCocoa

final class ImagesViewModel {
    
    let imagesRelay = BehaviorRelay<[UIImage]>(value: [])
    
    init() {
        self.fetchImages()
    }
    
    private func fetchImages() {
        let images: [UIImage] = [
            ._1,
            ._2,
            ._3,
            ._4,
            ._5
        ]
        self.imagesRelay.accept(images)
    }
}
