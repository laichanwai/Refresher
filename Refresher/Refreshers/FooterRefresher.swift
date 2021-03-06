//
//  FooterRefresher.swift
//  Refresher
//
//  Created by laizw on 2019/1/24.
//  Copyright © 2019 buzzvideo. All rights reserved.
//

import UIKit

final class FooterRefresher: Refresher {
    
    var scrollView: UIScrollView?
    
    var scrollViewInset: UIEdgeInsets = .zero
    
    var state: RefreshState = .idle {
        didSet {
            guard oldValue != state else { return }
            updateContentInset()
            updateFooterTop()
            animator.update(state: state)
        }
    }
    
    let animator: RefreshAnimatable
    
    init(animator: RefreshAnimatable) {
        self.animator = animator
        super.init(frame: .zero)
        animator.update(state: .idle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        refresherWillMoveToSuperView(newSuperview)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        refresherDidMoveToSuperView()
        
        DispatchQueue.main.async { [weak self] in
            self?.updateContentInset()
            self?.updateFooterTop()
        }
    }
}

extension FooterRefresher {
    func scrollView(_ scrollView: UIScrollView, didChangeOffset: NSKeyValueObservedChange<CGPoint>) {
        guard !isHidden, !isRefreshing, state != .noMoreData else { return }
        
        // 滑动距离
        var triggerDistance = scrollView.contentOffset.y
        if #available(iOS 11.0, *) {
            triggerDistance += scrollView.adjustedContentInset.top
        } else {
            triggerDistance += scrollView.contentInset.top
        }
        // 内容超出屏幕
        if scrollView.contentSize.height + scrollView.contentInset.top > scrollView.bounds.height {
            triggerDistance = triggerDistance + scrollView.bounds.height - scrollView.contentSize.height
        }
        // 滑动距离超出阈值
        let distance = bounds.height + animator.triggerDistance
        if triggerDistance >= distance {
            beginRefreshing()
        }
        
        animator.update(progress: min(1, max(0, triggerDistance / distance)))
    }
    
    func scrollView(_ scrollView: UIScrollView, didChangeContentSize: NSKeyValueObservedChange<CGSize>) {
        updateFooterTop()
    }
    
    func startAnimating(completion: @escaping () -> ()) {
        guard scrollView != nil else { return }
        animator.startAnimating()
        completion()
    }
    
    func stopAnimating(completion: @escaping () -> ()) {
        guard let view = scrollView else { return }
        animator.stopAnimating()
        completion()
        
        if view.isDecelerating {
            var offset = view.contentOffset
            offset.y = min(offset.y, view.contentSize.height - view.bounds.height)
            if offset.y < 0 {
                offset.y = 0
                UIView.animate(withDuration: 0.1) {
                    view.setContentOffset(offset, animated: false)
                }
            } else {
                view.setContentOffset(offset, animated: false)
            }
        }
    }
}

extension FooterRefresher {
    private func updateContentInset() {
        if isHidden {
            scrollView?.contentInset.bottom = scrollViewInset.bottom
        } else {
            scrollView?.contentInset.bottom = scrollViewInset.bottom + bounds.height
        }
    }
    
    private func updateFooterTop() {
        let top = scrollView?.contentSize.height ?? 0
        if frame.origin.y != top {
            frame.origin.y = top
        }
    }
}
