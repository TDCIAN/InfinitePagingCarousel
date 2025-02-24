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
        layout.scrollDirection = .horizontal // Set horizontal scroll direction
        layout.minimumLineSpacing = 0 // Set minimum spacing between cells
        layout.minimumInteritemSpacing = 0 // Set minimum spacing between items

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.layer.borderColor = UIColor.red.cgColor
        collectionView.layer.borderWidth = 1
        collectionView.isScrollEnabled = true
        collectionView.isPagingEnabled = true // Enable paging for scrolling
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
        pageControl.isUserInteractionEnabled = false // Disable user interaction
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
    
    // Array of carousel images
    private var carouselImages: [UIImage] = [] {
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
                // Set carousel images and start index to 4
                owner.carouselImages = images
                owner.setImages(startIndex: 4)
            })
            .disposed(by: self.disposeBag)
    }
    
    // Set images and start index
    private func setImages(startIndex: Int) {
        // If carouselImages.count is 1, carouselCollectionView does not need to scroll
        self.carouselCollectionView.isScrollEnabled = self.carouselImages.count > 1
        
        // Move the last item to the first position
        self.carouselImages.insert(self.carouselImages[self.carouselImages.count - 1], at: 0)
        
        // Add the second item to the end
        self.carouselImages.append(self.carouselImages[1])
        
        // Set the number of pages for the page control
        self.pageControl.numberOfPages = self.carouselImages.count - 2
        
        if startIndex == 0 {
            // Set the current page to 0 if the start index is 0
            self.pageControl.currentPage = 0
            self.indexLabel.text = "1/\(self.carouselImages.count - 2)"
        } else {
            // Set the current page if the start index is not 0
            self.pageControl.currentPage = startIndex
            self.indexLabel.text = "\(startIndex + 1)/\(self.carouselImages.count - 2)"
        }
        
        // Apply the layout immediately
        self.carouselCollectionView.layoutIfNeeded()
        
        if startIndex == 0 {
            // Move to the first page if the start index is 0
            self.carouselCollectionView.setContentOffset(
                .init(
                    x: self.carouselCollectionView.frame.width,
                    y: self.carouselCollectionView.contentOffset.y
                ),
                animated: false
            )
        } else {
            // Move to the specified page if the start index is not 0
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
        return self.carouselImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ImageCollectionViewCell.identifier,
            for: indexPath
        ) as? ImageCollectionViewCell else {
            return UICollectionViewCell()
        }
        // Set the image for the cell
        let image = self.carouselImages[indexPath.item]
        cell.setImage(image)
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Calculate the current page
        var page = Int(scrollView.contentOffset.x / scrollView.frame.maxX) - 1
        
        // Move to the first page if the current page is the last
        if page == self.carouselImages.count - 2 {
            page = 0
        }
        
        // Move to the last page if the current page is -1
        if page == -1 {
            page = self.carouselImages.count - 3
        }
        
        // Set the current page for the page control
        self.pageControl.currentPage = page
        
        // Update the index label text
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.indexLabel.text = "\(page + 1)/\(self.carouselImages.count - 2)"
        }
        
        let count = self.carouselImages.count

        // Move to the last page if the current offset is 0
        if scrollView.contentOffset.x == 0 {
            scrollView.setContentOffset(
                .init(
                    x: scrollView.frame.width * Double(count - 2),
                    y: scrollView.contentOffset.y
                ),
                animated: false
            )
        }
        
        // Move to the first page if the current offset is at the end
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
