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
        static let cellWidth = UIScreen.main.bounds.width
    }
    
    private lazy var carouselCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: Metric.cellWidth, height: Metric.collectionViewHeight)
        
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
    
    var timer: Timer?
    
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

        self.activateTimer()
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
    
    private func invalidateTimer() {
        self.timer?.invalidate()
    }
    
    private func activateTimer() {
        self.timer = Timer.scheduledTimer(
            timeInterval: 2,
            target: self,
            selector: #selector(self.timerCallBack),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc private func timerCallBack() {
        let visibleItem = self.carouselCollectionView.indexPathsForVisibleItems[0].item
        let nextItem = visibleItem + 1
        let initialItemCounts = self.items.count - 2
        
        self.carouselCollectionView.scrollToItem(
            at: IndexPath(item: nextItem, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
        
        if visibleItem == initialItemCounts {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self else { return }
                self.carouselCollectionView.scrollToItem(
                    at: IndexPath(item: 1, section: 0),
                    at: .centeredHorizontally,
                    animated: false
                )
            }
        }
        
        self.pageControl.currentPage = visibleItem % initialItemCounts
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

        self.invalidateTimer()
        
        self.activateTimer()
        
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

//extension ViewController: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return collectionView.frame.size
//    }
//}
