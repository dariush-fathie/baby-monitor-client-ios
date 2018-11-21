//
//  AudioRecordServiceTests.swift
//  Baby MonitorTests
//

import XCTest
import RxSwift
@testable import BabyMonitor

class AudioRecordServiceTests: XCTestCase {
    
    //Given
    let recorderMock = RecorderMock()
    lazy var sut = try! AudioRecordService(recorderFactory: {
        return recorderMock
    })
    
    override func setUp() {
        sut = try! AudioRecordService(recorderFactory: {
            return recorderMock
        })
    }

    func testShouldStartRecording() {
        //When
        sut.startRecording()
        
        //Then
        XCTAssertTrue(recorderMock.isRecordReset)
        XCTAssertTrue(recorderMock.isRecording)
    }
    
    func testShouldStopRecording() {
        //When
        sut.startRecording()
        recorderMock.isRecording = true
        sut.stopRecording()
        
        //Then
        XCTAssertFalse(recorderMock.isRecording)
    }
    
    func testShouldPublishAudioFile() {
        //Given
        let disposeBag = DisposeBag()
        let exp = expectation(description: "Should publish audio file")
        sut.directoryDocumentsSavableObservable.subscribe(onNext: { _ in
            exp.fulfill()
        }).disposed(by: disposeBag)
        recorderMock.shouldReturnNilForAudioFile = false
        
        //When
        sut.startRecording()
        sut.stopRecording()
        
        //Then
        wait(for: [exp], timeout: 2.0)
    }
    
    func testShouldNotPublishAudioFile() {
        //Given
        let disposeBag = DisposeBag()
        let exp = expectation(description: "Should not publish audio file")
        sut.directoryDocumentsSavableObservable.subscribe(onNext: { _ in
            exp.fulfill()
        }).disposed(by: disposeBag)
        recorderMock.shouldReturnNilForAudioFile = true
        
        //When
        sut.stopRecording()
        
        //Then
        let result = XCTWaiter.wait(for: [exp], timeout: 2.0)
        XCTAssertTrue(result == .timedOut)
    }
}