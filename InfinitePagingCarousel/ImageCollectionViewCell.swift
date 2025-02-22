//
//  ImageCollectionViewCell.swift
//  InfinitePagingCarousel
//
//  Created by 김정민 on 2/22/25.
//

import UIKit
import SnapKit

final class ImageCollectionViewCell: UICollectionViewCell {
    static let identifier = "ImageCollectionViewCell"
    
    private lazy var cellImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        contentView.addSubview(self.cellImageView)
        self.cellImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.cellImageView.image = nil
    }
    
    func setImage(_ image: UIImage) {
        self.cellImageView.image = image
    }
}
