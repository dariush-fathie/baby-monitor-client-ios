//
//  OnboardingCoordinator.swift
//  Baby Monitor
//

import UIKit

final class OnboardingCoordinator: Coordinator {

    var appDependencies: AppDependencies
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    var onEnding: (() -> Void)?
    
    private weak var pairingCoordinator: OnboardingPairingCoordinator?
    private weak var connectingCoordinator: OnboardingConnectingCoordinator?
    
    init(_ navigationController: UINavigationController, appDependencies: AppDependencies) {
        self.navigationController = navigationController
        self.appDependencies = appDependencies
        setup()
    }
    
    func start() {
        navigationController.setNavigationBarHidden(true, animated: false)
        switch UserDefaults.appMode {
        case .none:
            if UserDefaults.didShowOnboarding {
                appDependencies.analytics.setUserProperty(.appState(.undefined))
                showSpecifyDeviceInfoView()
            } else {
                appDependencies.analytics.setUserProperty(.appState(.firstOpen))
                childCoordinators.first?.start()
            }
        case .baby, .parent:
            break
        }
    }
    
    private func setup() {
        let introCoordinator = IntroCoordinator(navigationController, appDependencies: appDependencies)
        childCoordinators.append(introCoordinator)
        introCoordinator.onEnding = { [weak self] in
            self?.showSpecifyDeviceInfoView()
            UserDefaults.didShowOnboarding = true
        }
        let pairingCoordinator = OnboardingPairingCoordinator(navigationController, appDependencies: appDependencies)
        pairingCoordinator.onEnding = { [weak self] in
            UserDefaults.appMode = .parent
            self?.onEnding?()
        }
        childCoordinators.append(pairingCoordinator)
        self.pairingCoordinator = pairingCoordinator
        let connectingCoordinator = OnboardingConnectingCoordinator(navigationController, appDependencies: appDependencies)
        connectingCoordinator.onEnding = { [weak self] in
            UserDefaults.appMode = .baby
            self?.onEnding?()
        }
        childCoordinators.append(connectingCoordinator)
        self.connectingCoordinator = connectingCoordinator
    }

    private func showInitialSetup() {
        let viewModel = SpecifyDeviceOnboardingViewModel(analytics: appDependencies.analytics)
        viewModel.didSelectBaby = { [weak self] in
            self?.appDependencies.analytics.setUserProperty(.appState(.server))
            self?.showAllowSendingRecordingsView()
        }
        viewModel.didSelectParent = { [weak self] in
            self?.appDependencies.analytics.setUserProperty(.appState(.client))
            self?.pairingCoordinator?.start()
        }
        let viewController = SpecifyDeviceOnboardingViewController(viewModel: viewModel)
        viewController.rx.viewDidLoad.subscribe(onNext: { [weak self] in
            self?.connect(to: viewModel)
        })
        .disposed(by: viewModel.bag)
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showSpecifyDeviceInfoView() {
        let viewModel = SpecifyDeviceInfoOnboardingViewModel(analytics: appDependencies.analytics)
        let viewController = SpecifyDeviceInfoOnboardingViewController(viewModel: viewModel)
        viewController.rx.viewDidLoad.subscribe(onNext: { [weak self] in
            self?.connect(to: viewModel)
        })
        .disposed(by: viewModel.bag)
        navigationController.setViewControllers([viewController], animated: true)
    }
    private func showAllowSendingRecordingsView() {
        let viewModel = RecordingsIntroFeatureViewModel(analytics: appDependencies.analytics)
        let viewController = RecordingsIntroFeatureViewController(viewModel: viewModel)
        viewController.rx.viewDidLoad.subscribe(onNext: { [weak self] in
            self?.connect(to: viewModel)
        })
        .disposed(by: viewModel.bag)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func connect(to viewModel: SpecifyDeviceInfoOnboardingViewModel) {
        viewModel.specifyDeviceTap?.subscribe(onNext: { [unowned self] in
            self.showInitialSetup()
        })
        .disposed(by: viewModel.bag)
    }
    
    private func connect(to viewModel: SpecifyDeviceOnboardingViewModel) {
        viewModel.cancelTap?.subscribe(onNext: { [unowned self] in
            self.navigationController.popViewController(animated: true)
        })
        .disposed(by: viewModel.bag)
    }
        
    private func connect(to viewModel: RecordingsIntroFeatureViewModel) {
        viewModel.startButtonTap?.subscribe(onNext: { [weak self] in
            self?.connectingCoordinator?.start()
        })
        .disposed(by: viewModel.bag)
        viewModel.cancelButtonTap?.subscribe(onNext: { [weak self] in
            self?.navigationController.popViewController(animated: true)
        })
        .disposed(by: viewModel.bag)
    }
}
