//
//  LxGridViewFlowLayout.swift
//  LxGridViewDemo
//

import UIKit

let PRESS_TO_MOVE_MIN_DURATION = 0.1
let MIN_PRESS_TO_BEGIN_EDITING_DURATION = 0.6
let LxGridView_DELETE_RADIUS: CGFloat = 15
let ICON_CORNER_RADIUS: CGFloat = 15

let kVibrateAnimation = "kVibrateAnimation"
let VIBRATE_DURATION: CGFloat = 0.1

@objc

protocol LxGridViewDataSource : UICollectionViewDataSource {

    @objc optional func collectionView(collectionView: UICollectionView, itemAtIndexPath sourceIndexPath: IndexPath, willMoveToIndexPath destinationIndexPath: IndexPath)
    @objc optional func collectionView(collectionView: UICollectionView, itemAtIndexPath sourceIndexPath: IndexPath, didMoveToIndexPath destinationIndexPath: IndexPath)
    
    @objc optional func collectionView(collectionView: UICollectionView, canMoveItemAtIndexPath indexPath: IndexPath) -> Bool
    @objc optional func collectionView(collectionView: UICollectionView, itemAtIndexPath sourceIndexPath: IndexPath, canMoveToIndexPath destinationIndexPath: IndexPath) -> Bool
}

@objc

protocol LxGridViewDelegateFlowLayout : UICollectionViewDelegateFlowLayout {

    @objc optional func collectionView(collectionView: UICollectionView, layout gridViewLayout: LxGridViewFlowLayout, willBeginDraggingItemAtIndexPath indexPath: IndexPath)
    @objc optional func collectionView(collectionView: UICollectionView, layout gridViewLayout: LxGridViewFlowLayout, didBeginDraggingItemAtIndexPath indexPath: IndexPath)
    @objc optional func collectionView(collectionView: UICollectionView, layout gridViewLayout: LxGridViewFlowLayout, willEndDraggingItemAtIndexPath indexPath: IndexPath)
    @objc optional func collectionView(collectionView: UICollectionView, layout gridViewLayout: LxGridViewFlowLayout, didEndDraggingItemAtIndexPath indexPath: IndexPath)
}

class LxGridViewFlowLayout: UICollectionViewFlowLayout, UIGestureRecognizerDelegate {
    
    var panGestureRecognizerEnable: Bool {
        
        get {
            return _panGestureRecognizer.isEnabled
        }
        set {
            _panGestureRecognizer.isEnabled = newValue
        }
    }
   
    var _panGestureRecognizer = UIPanGestureRecognizer()
    
    var _longPressGestureRecognizer = UILongPressGestureRecognizer()
    var _movingItemIndexPath: IndexPath?
    var _beingMovedPromptView: UIView?
    var _sourceItemCollectionViewCellCenter = CGPoint.zero
    
    var _displayLink: CADisplayLink?
    var _remainSecondsToBeginEditing = MIN_PRESS_TO_BEGIN_EDITING_DURATION
    
    
//  MARK:- setup
    deinit {
    
        _displayLink?.invalidate()
        
        removeGestureRecognizers()
        removeObserver(self, forKeyPath: "collectionView")
    }
    
    override init () {
        
        super.init()
        setup()
    }

    required init(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)!
        setup()
    }
    
    func setup() {
    
        self.addObserver(self, forKeyPath: "collectionView", options: .new, context: nil)
    }
    
    func addGestureRecognizers() {
    
        collectionView?.isUserInteractionEnabled = true
        
        _longPressGestureRecognizer.addTarget(self, action: #selector(longPressGestureRecognizerTriggerd(longPress:)))
        _longPressGestureRecognizer.cancelsTouchesInView = false
        _longPressGestureRecognizer.minimumPressDuration = PRESS_TO_MOVE_MIN_DURATION
        _longPressGestureRecognizer.delegate = self
        
        if let cV = collectionView {
        
            for gestureRecognizer in cV.gestureRecognizers! {
                
                if gestureRecognizer is UILongPressGestureRecognizer {
                    
                    gestureRecognizer.require(toFail: _longPressGestureRecognizer)
                }
            }
        }
        
        collectionView?.addGestureRecognizer(_longPressGestureRecognizer)
        
        _panGestureRecognizer.addTarget(self, action:#selector(panGestureRecognizerTriggerd(pan:)))
        _panGestureRecognizer.delegate = self
        collectionView?.addGestureRecognizer(_panGestureRecognizer)

        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(notificaiton:)), name: UIApplication.willResignActiveNotification, object: nil)

    }
    
    func removeGestureRecognizers() {
    
        _longPressGestureRecognizer.view?.removeGestureRecognizer(_longPressGestureRecognizer)
        _longPressGestureRecognizer.delegate = nil
        
        _panGestureRecognizer.view?.removeGestureRecognizer(_panGestureRecognizer)
        _panGestureRecognizer.delegate = nil

        NotificationCenter.default.removeObserver(self, forKeyPath: UIApplication.willResignActiveNotification.rawValue)

    }
    
//  MARK:- getter and setter implementation
    var dataSource: LxGridViewDataSource? {
        
        return collectionView?.dataSource as? LxGridViewDataSource
    }
    
    var delegate: LxGridViewDelegateFlowLayout? {
    
        return collectionView?.delegate as? LxGridViewDelegateFlowLayout
    }

//  MARK:- override UICollectionViewLayout methods
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        let layoutAttributesForElementsInRect = super.layoutAttributesForElements(in: rect)

        if let lxfeir = layoutAttributesForElementsInRect {
            for layoutAttributes in lxfeir {
                if layoutAttributes.representedElementCategory == .cell {
                    layoutAttributes.isHidden = layoutAttributes.indexPath == _movingItemIndexPath
                }
            }
        }
        return layoutAttributesForElementsInRect
    }
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {

        let layoutAttributes = super.layoutAttributesForItem(at: indexPath)

        if layoutAttributes?.representedElementCategory == .cell {

            layoutAttributes?.isHidden = layoutAttributes?.indexPath == _movingItemIndexPath
        }

        return layoutAttributes
    }

//  MARK:- gesture
    @objc func longPressGestureRecognizerTriggerd(longPress:UILongPressGestureRecognizer) {


        guard let movingItemIndexPath = collectionView?.indexPathForItem(at: longPress.location(in: collectionView)) else {
            return
        }

        switch longPress.state {
        
        case .began:
            if _displayLink == nil {
                _displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTriggered(displayLink:)))
                _displayLink?.frameInterval = 6
                _displayLink?.add(to: RunLoop.current, forMode: .default)
            
                _remainSecondsToBeginEditing = MIN_PRESS_TO_BEGIN_EDITING_DURATION
            }

            _movingItemIndexPath = movingItemIndexPath

            if (dataSource?.responds(to: #selector(dataSource?.collectionView(collectionView:canMoveItemAtIndexPath:))))! {
                if !(dataSource?.collectionView!(collectionView: collectionView!, canMoveItemAtIndexPath: movingItemIndexPath))! {
                    _movingItemIndexPath = nil
                    return
                }
            }

            if (delegate?.responds(to: #selector(delegate?.collectionView(collectionView:layout:willBeginDraggingItemAtIndexPath:))))! {
                delegate?.collectionView!(collectionView: collectionView!, layout: self, willBeginDraggingItemAtIndexPath: movingItemIndexPath)
            }

            guard let sourceCollectionViewCell = collectionView?.cellForItem(at: _movingItemIndexPath!) as? TZTestCell else {
                debugPrint("LxGridViewFlowLayout: Must use LxGridViewCell as your collectionViewCell class!")
                return
            }


            _beingMovedPromptView = UIView(frame: sourceCollectionViewCell.frame.offsetBy(dx: LxGridView_DELETE_RADIUS, dy: -LxGridView_DELETE_RADIUS))

            sourceCollectionViewCell.isHighlighted = true
            let highlightedSnapshotView = sourceCollectionViewCell.snapshotView()
            highlightedSnapshotView.frame = sourceCollectionViewCell.bounds
            highlightedSnapshotView.alpha = 1
            
            sourceCollectionViewCell.isHighlighted = false
            let snapshotView = sourceCollectionViewCell.snapshotView()
            snapshotView.frame = sourceCollectionViewCell.bounds
            snapshotView.alpha = 0
            
            _beingMovedPromptView?.addSubview(snapshotView)
            _beingMovedPromptView?.addSubview(highlightedSnapshotView)
            collectionView?.addSubview(_beingMovedPromptView!)
            
            let kVibrateAnimation = "kVibrateAnimation"
            let VIBRATE_DURATION: CGFloat = 0.1
            let VIBRATE_RADIAN = CGFloat(Double.pi / 96)
            
            let vibrateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            vibrateAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            vibrateAnimation.fromValue = -VIBRATE_RADIAN
            vibrateAnimation.toValue = VIBRATE_RADIAN
            vibrateAnimation.autoreverses = true
            vibrateAnimation.duration = CFTimeInterval(VIBRATE_DURATION)
            vibrateAnimation.repeatCount = Float(CGFloat.greatestFiniteMagnitude)
            _beingMovedPromptView?.layer.add(vibrateAnimation, forKey: kVibrateAnimation)
            
            _sourceItemCollectionViewCellCenter = sourceCollectionViewCell.center
            
            UIView.animate(withDuration: 0, delay: 0, options: .beginFromCurrentState, animations: { () -> Void in
                
                highlightedSnapshotView.alpha = 0
                snapshotView.alpha = 1
                
            }, completion: { [unowned self] (finished) -> Void in
                
                highlightedSnapshotView.removeFromSuperview()

                if (self.delegate?.responds(to: #selector(self.delegate?.collectionView(collectionView:layout:didBeginDraggingItemAtIndexPath:))))! {
                    self.delegate?.collectionView!(collectionView: self.collectionView!, layout: self, didBeginDraggingItemAtIndexPath: self._movingItemIndexPath!)
                }
            })
            
            invalidateLayout()
            
        case .ended:
            fallthrough
        case .cancelled:
            _displayLink?.invalidate()
            _displayLink = nil
            
            if let movingItemIndexPath = _movingItemIndexPath {

                if (delegate?.responds(to: #selector(delegate?.collectionView(collectionView:layout:willEndDraggingItemAtIndexPath:))))! {
                    delegate?.collectionView!(collectionView: collectionView!, layout: self, willEndDraggingItemAtIndexPath: movingItemIndexPath)
                }
                
                _movingItemIndexPath = nil
                _sourceItemCollectionViewCellCenter = CGPoint.zero
                
                let movingItemCollectionViewLayoutAttributes = layoutAttributesForItem(at: movingItemIndexPath)
                
                _longPressGestureRecognizer.isEnabled = false
                
                UIView.animate(withDuration: 0, delay: 0, options: .beginFromCurrentState, animations: { [unowned self] () -> Void in
                    
                    self._beingMovedPromptView!.center = (movingItemCollectionViewLayoutAttributes?.center)!
                }, completion: { [unowned self] (finished) -> Void in
                    
                    self._longPressGestureRecognizer.isEnabled = true
                    self._beingMovedPromptView?.removeFromSuperview()
                    self._beingMovedPromptView = nil
                    self.invalidateLayout()

                    if (self.delegate?.responds(to: #selector(self.delegate?.collectionView(collectionView:layout:didEndDraggingItemAtIndexPath:))))! {
                        self.delegate?.collectionView!(collectionView: self.collectionView!, layout: self, didEndDraggingItemAtIndexPath: movingItemIndexPath)
                    }
                })
            }
        default:
            break
        }
    }
    
    @objc func panGestureRecognizerTriggerd(pan: UIPanGestureRecognizer) {
    
        switch pan.state {
        
        case .began:
            fallthrough
        case .changed:
            let panTranslation = pan.translation(in: collectionView!)
            _beingMovedPromptView?.center = _sourceItemCollectionViewCellCenter + panTranslation


            guard let sourceIndexPath = _movingItemIndexPath, let destinationIndexPath = collectionView?.indexPathForItem(at: (_beingMovedPromptView?.center)!) else {
                return
            }
            if destinationIndexPath == sourceIndexPath {
                return
            }
            if (self.dataSource?.responds(to: #selector(self.dataSource?.collectionView(collectionView:itemAtIndexPath:canMoveToIndexPath:))))! {
                if !(self.dataSource?.collectionView!(collectionView: collectionView!, itemAtIndexPath: sourceIndexPath, canMoveToIndexPath: destinationIndexPath))! {
                    return
                }
            }
            if (self.dataSource?.responds(to: #selector(self.dataSource?.collectionView(collectionView:itemAtIndexPath:willMoveToIndexPath:))))! {
                self.dataSource?.collectionView!(collectionView: collectionView!, itemAtIndexPath: sourceIndexPath, willMoveToIndexPath: destinationIndexPath)
            }

            _movingItemIndexPath = destinationIndexPath
            collectionView?.performBatchUpdates({ [unowned self] () -> Void in
                self.collectionView?.deleteItems(at: [sourceIndexPath])
                self.collectionView?.insertItems(at: [destinationIndexPath])
            }, completion: { [unowned self] (finished) -> Void in

                if (self.dataSource?.responds(to: #selector(self.dataSource?.collectionView(collectionView:itemAtIndexPath:didMoveToIndexPath:))))! {
                    self.dataSource?.collectionView!(collectionView: self.collectionView!, itemAtIndexPath: sourceIndexPath, didMoveToIndexPath: destinationIndexPath)
                }
            })
            
        default:
            break
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if _panGestureRecognizer == gestureRecognizer {
            
            return _movingItemIndexPath != nil
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if _longPressGestureRecognizer == gestureRecognizer {
            return _panGestureRecognizer == otherGestureRecognizer
        }
        if _panGestureRecognizer == gestureRecognizer {
            return _longPressGestureRecognizer == otherGestureRecognizer
        }
        return false
    }
    
//  MARK:- displayLink
    
    @objc func displayLinkTriggered(displayLink: CADisplayLink) {
    
        if _remainSecondsToBeginEditing <= 0 {
            _displayLink?.invalidate()
            _displayLink = nil
        }
        
        _remainSecondsToBeginEditing = _remainSecondsToBeginEditing - 0.1
    }
    
//  MARK:- KVO and notification

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        if keyPath == "collectionView" {

            if collectionView != nil {

                addGestureRecognizers()
            }
            else {

                removeGestureRecognizers()
            }
        }
    }

    @objc func applicationWillResignActive(notificaiton: NSNotification) {
    
        _panGestureRecognizer.isEnabled = false
        _panGestureRecognizer.isEnabled = true
    }
}

private func == (left: NSIndexPath, right: NSIndexPath) -> Bool {

    return left.section == right.section && left.item == right.item
}

func + (point: CGPoint, offset: CGPoint) -> CGPoint {
    
    return CGPoint(x: point.x + offset.x, y: point.y + offset.y)
}
