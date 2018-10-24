//
//  SettingsCoordinator.swift
//  Baby Monitor
//

import UIKit

final class SettingsCoordinator: Coordinator, BabiesViewShowable {
    
    var appDependencies: AppDependencies
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    var switchBabyViewController: BabyMonitorGeneralViewController?
    var onEnding: (() -> Void)?
    
    private weak var settingsViewController: SettingsViewController?
    
    init(_ navigationController: UINavigationController, appDependencies: AppDependencies) {
        self.appDependencies = appDependencies
        self.navigationController = navigationController
    }
    
    func start() {
        showSettings()
    }
    
    // MARK: - private functions
    private func showSettings() {
        let viewModel = SettingsViewModel(babyRepo: appDependencies.babyRepo)
        viewModel.didSelectShowBabiesView = { [weak self] in
            guard let self = self, let settingsViewController = self.settingsViewController else {
                return
            }
            self.toggleSwitchBabiesView(on: settingsViewController, babyRepo: self.appDependencies.babyRepo)
        }
        viewModel.didSelectChangeServer = { [weak self] in
            self?.showClientSetup()
        }

        let settingsViewController = SettingsViewController(viewModel: viewModel)
        self.settingsViewController = settingsViewController
        navigationController.pushViewController(settingsViewController, animated: false)
    }
    
    private func showClientSetup() {
        let clientSetupViewModel = ClientSetupOnboardingViewModel(
            netServiceClient: appDependencies.netServiceClient,
            rtspConfiguration: appDependencies.rtspConfiguration,
            babyRepo: appDependencies.babyRepo)
        
        let clientSetupViewController = GeneralOnboardingViewController(viewModel: clientSetupViewModel, role: .clientSetup)
        clientSetupViewModel.didFinishDeviceSearch = { [weak self] result in
            switch result {
            case .success:
                _ = self?.navigationController.popViewController(animated: true)
            case .failure:
                //TODO: add error handling
                break
            }
        }
        navigationController.pushViewController(clientSetupViewController, animated: true)
    }
}
