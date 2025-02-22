//
//  ViewController.swift
//  InfinitePagingCarousel
//
//  Created by 김정민 on 2/19/25.
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

class ViewController: UIViewController {
    
    var items: [UIImage] = [
        ._1,
        ._2,
        ._3,
        ._4,
    ]

    enum Metric {
        static let collectionViewHeight = 350.0
    }
    
    private lazy var carouselCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.isScrollEnabled = true
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.layer.borderColor = UIColor.blue.cgColor
        collectionView.layer.borderWidth = 1
        collectionView.register(
            ImageCollectionViewCell.self,
            forCellWithReuseIdentifier: ImageCollectionViewCell.identifier
        )
        return collectionView
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl(frame: .zero)
        pageControl.currentPageIndicatorTintColor = .systemGreen
        pageControl.pageIndicatorTintColor = .red
        pageControl.backgroundStyle = .minimal
        pageControl.numberOfPages = 4
        pageControl.isUserInteractionEnabled = false
        return pageControl
    }()
    
    private let indexLabel: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.red.cgColor
        label.layer.borderWidth = 1
        label.textColor = .label
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.items.insert(self.items[items.count - 1], at: 0)
        self.items.append(self.items[1])
        
        self.view.addSubview(self.carouselCollectionView)
        self.view.addSubview(self.pageControl)
        
        self.carouselCollectionView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(Metric.collectionViewHeight)
        }
        
        self.pageControl.snp.makeConstraints { make in
            make.bottom.equalTo(self.carouselCollectionView.snp.bottom).offset(-10)
            make.centerX.equalToSuperview()
        }

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.carouselCollectionView.setContentOffset(
            .init(
                x: self.carouselCollectionView.frame.width,
                y: self.carouselCollectionView.contentOffset.y
            ),
            animated: false
        )
    }
}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ImageCollectionViewCell.identifier,
            for: indexPath
        ) as? ImageCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let item = self.items[indexPath.item]
        cell.setImage(item)
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        var page = Int(scrollView.contentOffset.x / scrollView.frame.maxX) - 1
        
        if page == self.items.count - 2 {
            page = 0
        }
        
        if page == -1 {
            page = self.items.count - 3
        }
        
        self.pageControl.currentPage = page
        
        let count = self.items.count
        
        if scrollView.contentOffset.x == 0 {
            scrollView.setContentOffset(
                .init(
                    x: scrollView.frame.width * Double(count - 2),
                    y: scrollView.contentOffset.y
                ),
                animated: false
            )
        }
        
        if scrollView.contentOffset.x == Double(count - 1) * scrollView.frame.width {
            scrollView.setContentOffset(
                .init(
                    x: scrollView.frame.width,
                    y: scrollView.contentOffset.y
                ),
                animated: false
            )
        }
        
        print("### 페이지: \(page), 카운트: \(count)")
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}
