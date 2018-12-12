//
//  CryingEventsServiceMock.swift
//  Baby MonitorTests
//

@testable import BabyMonitor
import RxSwift

final class CryingEventsServiceMock: CryingEventsServiceProtocol {

    private(set) var isStarted = false
    var cryingEventObservable: Observable<Bool> {
        return cryingEventPublisher
    }
    let cryingEventPublisher = PublishSubject<Bool>()
    private let shouldThrow: Bool

    init(shouldThrow: Bool = false) {
        self.shouldThrow = shouldThrow
    }

    func start() throws {
        if shouldThrow {
            throw CryingEventService.CryingEventServiceError.audioRecordServiceError
        }
        isStarted = true
    }

    func stop() {
        isStarted = false
    }
}
