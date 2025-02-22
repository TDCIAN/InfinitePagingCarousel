//
//  ViewController.swift
//  InfinitePagingCarousel
//
//  Created by 김정민 on 2/19/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
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
    
    private var items: [UIImage] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.carouselCollectionView.reloadData()
            }
        }
    }
    
    private let viewModel = ImagesViewModel()
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setup()
        self.bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    private func setup() {
        self.view.addSubview(self.carouselCollectionView)
        self.view.addSubview(self.pageControl)
        self.view.addSubview(self.indexLabel)
        
        self.carouselCollectionView.snp.makeConstraints {
            $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(Metric.collectionViewHeight)
        }
        
        self.pageControl.snp.makeConstraints {
            $0.top.equalTo(self.carouselCollectionView.snp.bottom).offset(15)
            $0.centerX.equalToSuperview()
        }
        
        self.indexLabel.snp.makeConstraints {
            $0.top.equalTo(self.pageControl.snp.bottom).offset(15)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(100)
            $0.height.equalTo(50)
        }
    }
    
    private func bind() {
        self.viewModel.imagesRelay.asObservable()
            .filter({ !$0.isEmpty })
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { owner, images in
                owner.items = images
                owner.setImages(startIndex: 1)
            })
            .disposed(by: self.disposeBag)
    }
    
    private func setImages(startIndex: Int) {
        self.items.insert(self.items[self.items.count - 1], at: 0)
        self.items.append(self.items[1])
        
        self.pageControl.numberOfPages = self.items.count - 2
        
        if startIndex == 0 {
            self.pageControl.currentPage = 0
            self.indexLabel.text = "1/\(self.items.count - 2)"
        } else {
            self.pageControl.currentPage = startIndex
            self.indexLabel.text = "\(startIndex + 1)/\(self.items.count - 2)"
        }
        
        self.carouselCollectionView.layoutIfNeeded()
        
        if startIndex == 0 {
            self.carouselCollectionView.setContentOffset(
                .init(
                    x: Metric.cellWidth,
                    y: self.carouselCollectionView.contentOffset.y
                ),
                animated: false
            )
        } else {
            self.carouselCollectionView.setContentOffset(
                .init(
                    x: Metric.cellWidth * Double(startIndex + 1),
                    y: self.carouselCollectionView.contentOffset.y
                ),
                animated: false
            )
        }
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
        let image = items[indexPath.item]
        cell.setImage(image)
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
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.indexLabel.text = "\(page + 1)/\(self.items.count - 2)"
        }
        
        let count = self.items.count
        
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
