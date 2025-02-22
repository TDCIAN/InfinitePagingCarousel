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
    
    private var startIndex: Int = 1
    
    var items: [UIImage] = [
        ._1,
        ._2,
        ._3,
        ._4,
        ._5
    ]
    
    enum Metric {
        static let collectionViewHeight = 350.0
        static let cellWidth = UIScreen.main.bounds.width
    }
    
    private lazy var carouselCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: Metric.cellWidth, height: Metric.collectionViewHeight)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.layer.borderColor = UIColor.red.cgColor
        collectionView.layer.borderWidth = 1
        collectionView.isScrollEnabled = true
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
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
        pageControl.isUserInteractionEnabled = false
        return pageControl
    }()

    private lazy var indexLabel: UILabel = {
        let label = UILabel()
        label.layer.borderColor = UIColor.blue.cgColor
        label.layer.borderWidth = 1
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(carouselCollectionView)
        view.addSubview(pageControl)
        view.addSubview(indexLabel)
        
        carouselCollectionView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(Metric.collectionViewHeight)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(carouselCollectionView.snp.bottom).offset(15)
            $0.centerX.equalToSuperview()
        }
        
        indexLabel.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(15)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(100)
            $0.height.equalTo(50)
        }

        items.insert(items[items.count - 1], at: 0)
        items.append(items[1])
        
        pageControl.numberOfPages = self.items.count - 2
        
        if startIndex == 0 {
            pageControl.currentPage = 0
            indexLabel.text = "1/\(self.items.count - 2)"
        } else {
            pageControl.currentPage = startIndex
            indexLabel.text = "\(startIndex + 1)/\(self.items.count - 2)"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if startIndex == 0 {
            carouselCollectionView.setContentOffset(
                .init(
                    x: Metric.cellWidth,
                    y: carouselCollectionView.contentOffset.y
                ),
                animated: false
            )
        } else {
            carouselCollectionView.setContentOffset(
                .init(
                    x: Metric.cellWidth * Double(startIndex + 1),
                    y: carouselCollectionView.contentOffset.y
                ),
                animated: false
            )
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ImageCollectionViewCell.identifier,
            for: indexPath
        ) as? ImageCollectionViewCell else {
            return UICollectionViewCell()
        }
        let image = items[indexPath.item]
        cell.setImage(image)
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        var page = Int(scrollView.contentOffset.x / scrollView.frame.maxX) - 1
        
        if page == items.count - 2 {
            page = 0
        }
        
        if page == -1 {
            page = items.count - 3
        }
        
        pageControl.currentPage = page
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.indexLabel.text = "\(page + 1)/\(self.items.count - 2)"
        }
        
        let count = items.count
        
        print("### 페이지: \(page), 페이지 + 1: \(page + 1)")

        if scrollView.contentOffset.x == 0 {
            scrollView.setContentOffset(
                .init(
                    x: Metric.cellWidth * Double(count - 2),
                    y: scrollView.contentOffset.y
                ),
                animated: false
            )
        }
        if scrollView.contentOffset.x == Double(count - 1) * Metric.cellWidth {
            scrollView.setContentOffset(
                .init(
                    x: Metric.cellWidth,
                    y: scrollView.contentOffset.y
                ),
                animated: false
            )
        }
    }
}
