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

    private lazy var carouselCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

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

    private func setup() {
        self.view.addSubview(self.carouselCollectionView)
        self.view.addSubview(self.pageControl)
        self.view.addSubview(self.indexLabel)
        
        self.carouselCollectionView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(350)
        }
        
        self.pageControl.snp.makeConstraints { make in
            make.top.equalTo(self.carouselCollectionView.snp.bottom).offset(15)
            make.centerX.equalToSuperview()
        }
        
        self.indexLabel.snp.makeConstraints { make in
            make.top.equalTo(self.pageControl.snp.bottom).offset(15)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(50)
        }
    }
    
    private func bind() {
        self.viewModel.imagesRelay.asObservable()
            .filter({ !$0.isEmpty })
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { owner, images in
                owner.items = images
                owner.setImages(startIndex: 4)
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
                    x: self.carouselCollectionView.frame.width,
                    y: self.carouselCollectionView.contentOffset.y
                ),
                animated: false
            )
        } else {
            self.carouselCollectionView.setContentOffset(
                .init(
                    x: self.carouselCollectionView.frame.width * Double(startIndex + 1),
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
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}
