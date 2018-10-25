//
//  ButtonView.swift
//  Baby Monitor
//

import UIKit
import RxCocoa
import RxSwift

final class DashboardButtonView: UIView {
    
    fileprivate let button: UIButton = UIButton()
    enum Role {
        case liveCamera, talk, playLullaby
        
        var text: String {
            switch self {
            case .liveCamera:
                return Localizable.Dashboard.liveCamera
            case .playLullaby:
                return Localizable.Dashboard.playLullaby
            case .talk:
                return Localizable.Dashboard.talk
            }
        }
        
        var image: UIImage {
            switch self {
            case .liveCamera:
                return #imageLiteral(resourceName: "videoCamera")
            case .playLullaby:
                return #imageLiteral(resourceName: "microphone")
            case .talk:
                return #imageLiteral(resourceName: "musicNote")
            }
        }
    }
    
    private enum Constants {
        static let imageViewHeightWidth: CGFloat = 50
    }
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        //TODO: remove color once assets are available, ticket: https://netguru.atlassian.net/browse/BM-65
        imageView.backgroundColor = .blue
        imageView.layer.cornerRadius = Constants.imageViewHeightWidth / 2
        return imageView
    }()
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .blue
        label.font = label.font.withSize(15)
        return label
    }()
    
    init(role: Role) {
        super.init(frame: .zero)
        setup(role: role)
    }
    
    @available(*, unavailable, message: "Use init(image:text:) instead")
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private functions
    private func setup(role: Role) {
        
        imageView.image = role.image
        textLabel.text = role.text
        
        [button, imageView, textLabel].forEach {
            addSubview($0)
        }
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        button.addConstraints {
            $0.equalEdges()
        }
        
        imageView.addConstraints {[
            $0.equalConstant(.height, Constants.imageViewHeightWidth),
            $0.equalConstant(.width, Constants.imageViewHeightWidth),
            $0.equal(.centerX),
            $0.equal(.top),
            $0.equalTo(textLabel, .bottom, .top, constant: -5)
        ]
        }
        
        textLabel.addConstraints {[
            $0.equal(.bottom),
            $0.equal(.leading),
            $0.equal(.trailing),
            $0.greaterThanOrEqualTo(imageView, .width, .width)
        ]
        }
    }
}

extension Reactive where Base: DashboardButtonView {
    
    var tap: ControlEvent<Void> {
        return base.button.rx.tap
    }
}
