//
//  ClientSetupViewModelTests.swift
//  Baby MonitorTests
//

import XCTest
import RealmSwift
import RxSwift
@testable import BabyMonitor

class ClientSetupViewModelTests: XCTestCase {

    func testShouldStartNetClientDiscoverAfterSelect() {
        // Given
        let netServiceClient = NetServiceClientMock()
        let configuration = URLConfigurationMock()
        let babyRepo = RealmBabiesRepository(realm: try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "test-realm")))
        let webSocketEventMessageService = WebSocketEventMessageServiceMock()
        let errorLogger = ServerErrorLoggerMock()
        let analyticsMock = AnalyticsManager(analyticsTracker: AnalyticsTrackerMock())
        let sut = OnboardingClientSetupViewModel(netServiceClient: netServiceClient,
                                                 urlConfiguration: configuration,
                                                 activityLogEventsRepository: babyRepo,
                                                 webSocketEventMessageService: webSocketEventMessageService,
                                                 serverErrorLogger: errorLogger,
                                                 analytics: analyticsMock)

        // When
        sut.startDiscovering()
        
        // Then
        XCTAssertTrue(netServiceClient.isEnabled.value)
    }
    
    func testShouldCallDidFindDeviceAfterPairingToDevice() {
        // Given
        let exp = expectation(description: "Should find device")
        let name = "name"
        let ip = "ip"
        let port = "port"
        let service = NetServiceDescriptor(name: name, ip: ip, port: port)
        let netServiceClient = NetServiceClientMock()
        let configuration = URLConfigurationMock()
        let babyRepo = RealmBabiesRepository(realm: try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "test-realm")))
        let webSocketEventMessageService = WebSocketEventMessageServiceMock()
        let errorLogger = ServerErrorLoggerMock()
        let analyticsMock = AnalyticsManager(analyticsTracker: AnalyticsTrackerMock())
        let sut = OnboardingClientSetupViewModel(netServiceClient: netServiceClient,
                                                 urlConfiguration: configuration,
                                                 activityLogEventsRepository: babyRepo,
                                                 webSocketEventMessageService: webSocketEventMessageService,
                                                 serverErrorLogger: errorLogger,
                                                 analytics: analyticsMock)
        var serverURL: URL?
        sut.didFinishDeviceSearch = { result in
            if case .success(let url) = result {
                serverURL = url
            }
            exp.fulfill()
        }
        
        // When
        sut.startDiscovering()
        netServiceClient.servicesRelay.accept([service])
        sut.pair(with: service)
        
        // Then
        waitForExpectations(timeout: 0.1) { _ in
            XCTAssertNotNil(serverURL)
            XCTAssertEqual(URL(string: "ws://\(ip):\(port)"), serverURL)
        }
    }
    
    func testShouldCallDidStartFindingDeviceAfterSelect() {
        // Given
        let exp = expectation(description: "Should find device")
        let service = NetServiceDescriptor(name: "Device", ip: "0.0.0.0", port: "0")
        let netServiceClient = NetServiceClientMock()
        let configuration = URLConfigurationMock()
        let babyRepo = RealmBabiesRepository(realm: try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "test-realm")))
        let webSocketEventMessageService = WebSocketEventMessageServiceMock()
        let errorLogger = ServerErrorLoggerMock()
        let analyticsMock = AnalyticsManager(analyticsTracker: AnalyticsTrackerMock())
        let sut = OnboardingClientSetupViewModel(netServiceClient: netServiceClient,
                                                 urlConfiguration: configuration,
                                                 activityLogEventsRepository: babyRepo,
                                                 webSocketEventMessageService: webSocketEventMessageService,
                                                 serverErrorLogger: errorLogger,
                                                 analytics: analyticsMock)
        sut.didFinishDeviceSearch = { _ in exp.fulfill() }
        
        // When
        sut.startDiscovering()
        netServiceClient.servicesRelay.accept([service])
        sut.pair(with: service)
        
        // Then
        waitForExpectations(timeout: 0.1) { _ in
            XCTAssertTrue(true)
        }
    }
    
    func testShouldEndSearchWithFailureAfterGivenTimeWhenNoDevicesFound() {
        // Given
        let exp = expectation(description: "Should find device")
        let netServiceClient = NetServiceClientMock()
        let configuration = URLConfigurationMock()
        let babyRepo = RealmBabiesRepository(realm: try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "test-realm")))
        let webSocketEventMessageService = WebSocketEventMessageServiceMock()
        let errorLogger = ServerErrorLoggerMock()
        let analyticsMock = AnalyticsManager(analyticsTracker: AnalyticsTrackerMock())
        let sut = OnboardingClientSetupViewModel(netServiceClient: netServiceClient,
                                                 urlConfiguration: configuration,
                                                 activityLogEventsRepository: babyRepo,
                                                 webSocketEventMessageService: webSocketEventMessageService,
                                                 serverErrorLogger: errorLogger,
                                                 analytics: analyticsMock)
        sut.didFinishDeviceSearch = { result in
            XCTAssertEqual(result, DeviceSearchResult.failure(.timeout))
            exp.fulfill()
        }
        
        // When
        sut.startDiscovering(withTimeout: 0.1)
        
        // Then
        waitForExpectations(timeout: 0.2) { _ in
            XCTAssertTrue(true)
        }
    }

    func testShouldResumeSearchOnRefresh() {
        // Given
        let refreshButtonTap = PublishSubject<Void>()
        let netServiceClient = NetServiceClientMock()
        let configuration = URLConfigurationMock()
        let babyRepo = RealmBabiesRepository(realm: try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "test-realm")))
        let webSocketEventMessageService = WebSocketEventMessageServiceMock()
        let errorLogger = ServerErrorLoggerMock()
        let analyticsMock = AnalyticsManager(analyticsTracker: AnalyticsTrackerMock())
        let sut = OnboardingClientSetupViewModel(netServiceClient: netServiceClient,
                                                 urlConfiguration: configuration,
                                                 activityLogEventsRepository: babyRepo,
                                                 webSocketEventMessageService: webSocketEventMessageService,
                                                 serverErrorLogger: errorLogger,
                                                 analytics: analyticsMock)
        sut.attachInput(refreshButtonTap: refreshButtonTap)

        // When
        refreshButtonTap.onNext(())

        // Then
        XCTAssertTrue(netServiceClient.isEnabled.value)
    }

    func testShouldEndSearchWithChangingStateAfterGivenTimeWhenSomeDevicesFound() {
        // Given
        let service = NetServiceDescriptor(name: "Device", ip: "0.0.0.0", port: "0")
        let netServiceClient = NetServiceClientMock()
        let configuration = URLConfigurationMock()
        let babyRepo = RealmBabiesRepository(realm: try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "test-realm")))
        let webSocketEventMessageService = WebSocketEventMessageServiceMock()
        let errorLogger = ServerErrorLoggerMock()
        let analyticsMock = AnalyticsManager(analyticsTracker: AnalyticsTrackerMock())
        let sut = OnboardingClientSetupViewModel(netServiceClient: netServiceClient,
                                                 urlConfiguration: configuration,
                                                 activityLogEventsRepository: babyRepo,
                                                 webSocketEventMessageService: webSocketEventMessageService,
                                                 serverErrorLogger: errorLogger,
                                                 analytics: analyticsMock)
        let disposeBag = DisposeBag()
        let exp = expectation(description: "Should change state to timeout after finding devices and no pairing")
        sut.state.skip(2).subscribe(onNext: { state in
            XCTAssertEqual(state, PairingSearchState.timeoutReached)
            exp.fulfill()
        }).disposed(by: disposeBag)

        // When
        sut.startDiscovering(withTimeout: 0.1)
        netServiceClient.servicesRelay.accept([service])

        // Then
        waitForExpectations(timeout: 0.2) { _ in
            XCTAssertFalse(netServiceClient.isEnabled.value)
        }
    }
}
