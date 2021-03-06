//
//  ParentSettingsView.swift
//  Baby Monitor
//

import UIKit
import RxSwift
import RxCocoa

final class ParentSettingsView: BaseSettingsView {

    fileprivate let editBabyPhotoButton = UIButton(type: .custom)

    fileprivate let editBabyPhotoImage: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "edit_baby_photo"))
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    fileprivate let babyNameTextField: UITextField = {
        let textField = UITextField()
        textField.returnKeyType = .done
        textField.attributedPlaceholder = NSAttributedString(
            string: Localizable.Settings.babyNamePlaceholder,
            attributes: [
                .font: UIFont.customFont(withSize: .h2, weight: .medium),
                .foregroundColor: UIColor.babyMonitorPurple.withAlphaComponent(0.5)
            ])
        textField.font = UIFont.customFont(withSize: .h2, weight: .medium)
        textField.textColor = .babyMonitorPurple
        return textField
    }()

    fileprivate lazy var soundDetectionModeControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: soundDetectionModes.map { $0.localizedTitle })
        segmentedControl.tintColor = .white
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.customFont(withSize: .body),
            .foregroundColor: UIColor.babyMonitorPurple
        ]
        segmentedControl.setTitleTextAttributes(attributes, for: .normal)
        return segmentedControl
    }()

    fileprivate lazy var noiseSliderView = NoiseSliderView()

    private let soundDetectionModes: [SoundDetectionMode]

    private let editImageView = UIImageView(image: #imageLiteral(resourceName: "edit"))
    
    private let underline: UIView = {
        let view = UIView()
        view.backgroundColor = .babyMonitorPurple
        return view
    }()

    private let sliderProgressIndicatorView = SliderProgressIndicatorView()

    private var timer: Timer?

    private let disposeBag = DisposeBag()

    /// Initializes settings view
    init(appVersion: String,
         soundDetectionModes: [SoundDetectionMode]) {
        self.soundDetectionModes = soundDetectionModes
        super.init(appVersion: appVersion)
        setupLayout()
        setupBindings()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .babyMonitorDarkPurple
        editBabyPhotoImage.layer.cornerRadius = editBabyPhotoImage.bounds.height / 2
    }

    /// Sets a new value on progress indicator.
    /// - Parameter result: A result that should be reflected on the indicator view.
    func updateProgressIndicator(with result: Result<()>) {
        sliderProgressIndicatorView.update(with: result)
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.sliderProgressIndicatorView.isHidden = true
        }
    }

    /// Sets a new value on a noise slider.
    /// - Parameter result: A value that should be set on the slider.
    func updateSlider(with value: Int) {
        noiseSliderView.update(sliderValue: value)
    }

    /// Sets a new value on sound mode control.
    /// - Parameter result: A index that should be selected on the control.
    func updateSoundMode(with value: Int) {
        soundDetectionModeControl.selectedSegmentIndex = value
        setupNoiseSlider()
    }

    private func setupLayout() {
        [editBabyPhotoImage,
         editBabyPhotoButton,
         babyNameTextField,
         editImageView,
         underline,
         soundDetectionModeControl,
         noiseSliderView,
         sliderProgressIndicatorView].forEach { addSubview($0) }
        setupConstraints()
        sliderProgressIndicatorView.isHidden = true
        setupNoiseSlider()
    }

    private func setupConstraints() {
        editImageView.addConstraints {[
            $0.equalConstant(.width, 16),
            $0.equalConstant(.height, 16)
        ]
        }
        editBabyPhotoImage.addConstraints {[
            $0.equal(.safeAreaTop, constant: 50),
            $0.equal(.centerX),
            $0.equalConstant(.width, 96),
            $0.equalConstant(.height, 96)
        ]
        }
        editImageView.addConstraints {[
            $0.equalTo(babyNameTextField, .centerY, .centerY),
            $0.equalTo(underline, .trailing, .trailing, constant: -3)
        ]
        }
        babyNameTextField.addConstraints {[
            $0.equalTo(editBabyPhotoImage, .top, .bottom, constant: 41),
            $0.equalTo(buttonsStackView, .leading, .leading),
            $0.equalTo(editImageView, .trailing, .leading, constant: -10)
            
        ]
        }
        underline.addConstraints {[
            $0.equalTo(babyNameTextField, .top, .bottom, constant: 12.5),
            $0.equalTo(babyNameTextField, .leading, .leading),
            $0.equal(.centerX),
            $0.equalConstant(.height, 1)
        ]
        }
        soundDetectionModeControl.addConstraints {[
            $0.equalTo(underline, .top, .bottom, constant: 30),
            $0.equalTo(underline, .width, .width),
            $0.equal(.centerX)
        ]
        }
        noiseSliderView.addConstraints {[
            $0.equalTo(soundDetectionModeControl, .top, .bottom, constant: 22),
            $0.equalTo(soundDetectionModeControl, .width, .width),
            $0.equalConstant(.height, 80),
            $0.equal(.centerX)
        ]
        }
        editBabyPhotoButton.addConstraints {[
            $0.equalTo(editBabyPhotoImage, .leading, .leading),
            $0.equalTo(editBabyPhotoImage, .trailing, .trailing),
            $0.equalTo(editBabyPhotoImage, .bottom, .bottom),
            $0.equalTo(editBabyPhotoImage, .top, .top)
        ]
        }
        editBabyPhotoButton.layer.zPosition = 1

        sliderProgressIndicatorView.addConstraints {[
            $0.equalConstant(.width, 50),
            $0.equalConstant(.height, 50),
            $0.equal(.centerX),
            $0.equalTo(noiseSliderView, .bottom, .top, constant: 6)
        ]
        }
    }

    private func setupBindings() {
        rx.voiceModeTap
            .subscribe(onNext: { [weak self] selectedVoiceModeIndex in
                guard let self = self else { return }
                self.sliderProgressIndicatorView.isHidden = false
                self.sliderProgressIndicatorView.startAnimating()
                self.setupNoiseSlider()
            }).disposed(by: disposeBag)

        rx.noiseSliderValue
            .skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] value in
                guard let self = self else { return }
                if self.sliderProgressIndicatorView.isHidden {
                    self.sliderProgressIndicatorView.isHidden = false
                    self.sliderProgressIndicatorView.animateAppearance()
                }
                self.sliderProgressIndicatorView.update(with: String(value))
            }).disposed(by: disposeBag)

        noiseSliderView.rx.noiseSliderValueOnEnded
            .subscribe(onNext: { [weak self] value in
                guard let self = self else { return }
                self.sliderProgressIndicatorView.startAnimating()
            }).disposed(by: disposeBag)
    }

    private func setupNoiseSlider() {
        let animation = CATransition()
        animation.duration = 0.3
        noiseSliderView.layer.add(animation, forKey: nil)
        noiseSliderView.isHidden = soundDetectionModeControl.selectedSegmentIndex != soundDetectionModes.firstIndex(of: .noiseDetection)
    }
}

extension Reactive where Base: ParentSettingsView {

    var babyPhoto: Binder<UIImage?> {
        return Binder<UIImage?>(base.editBabyPhotoImage) { imageView, image in
            imageView.image = image ?? #imageLiteral(resourceName: "edit_baby_photo")
        }
    }
    var babyName: ControlProperty<String> {
        let name = base.babyNameTextField.rx.controlEvent(.editingDidEndOnExit)
            .withLatestFrom(base.babyNameTextField.rx.text)
            .map { $0 ?? "" }
        let binder = Binder<String>(base.babyNameTextField) { textField, name in
            textField.text = name
        }
        return ControlProperty(values: name, valueSink: binder)
    }

    var voiceModeTap: Observable<Int> {
        return base.soundDetectionModeControl.rx.selectedSegmentIndex.skip(1)
            .throttle(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
    }

    var editPhotoTap: Observable<UIButton> {
        return base.editBabyPhotoButton.rx.tap.map { [unowned base] in base.editBabyPhotoButton }
    }

    var noiseSliderValue: Observable<Int> {
        return base.noiseSliderView.rx.noiseSliderValue
    }

    var noiseSliderValueOnEnded: Observable<Int> {
        return base.noiseSliderView.rx.noiseSliderValueOnEnded.debounce(.milliseconds(200), scheduler: MainScheduler.instance)
    }
}
