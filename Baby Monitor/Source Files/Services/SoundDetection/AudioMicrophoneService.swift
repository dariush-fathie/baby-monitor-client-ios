//
//  AudioMicrophoneService.swift
//  Baby Monitor
//

import Foundation
import AudioKit
import RxSwift
import RxCocoa

protocol ErrorProducable {
    var errorObservable: Observable<Error> { get }
}

protocol AudioMicrophoneServiceProtocol: AudioMicrophoneRecordServiceProtocol, AudioMicrophoneCaptureServiceProtocol {}

final class AudioMicrophoneService: AudioMicrophoneServiceProtocol, ErrorProducable {
   
    enum AudioError: Error {
        case initializationFailure
        case captureFailure
        case recordFailure
        case saveFailure
    }
    
    lazy var errorObservable = errorSubject.asObservable()
    lazy var microphoneBufferReadableObservable = microphoneBufferReadableSubject.asObservable()
    lazy var microphoneAmplitudeObservable = microphoneAmplitudeSubject.asObservable()
    lazy var directoryDocumentsSavableObservable = directoryDocumentsSavableSubject.asObservable()
    
    private(set) var isCapturing = false
    private(set) var isRecording = false
    
    private var microphoneCapturer: MicrophoneCaptureProtocol
    private var microphoneRecorder: MicrophoneRecordProtocol
    private var microphoneTracker: MicrophoneAmplitudeTracker

    private let errorSubject = PublishSubject<Error>()
    private let microphoneBufferReadableSubject = PublishSubject<AVAudioPCMBuffer>()
    private let microphoneAmplitudeSubject = PublishSubject<MicrophoneAmplitudeInfo>()
    private let directoryDocumentsSavableSubject = PublishSubject<DirectoryDocumentsSavable>()
    
    private let disposeBag = DisposeBag()

    init(microphoneFactory: () throws -> AudioKitMicrophoneProtocol?) throws {
        guard let audioKitMicrophone = try microphoneFactory() else {
            throw(AudioMicrophoneService.AudioError.initializationFailure)
        }
        microphoneCapturer = audioKitMicrophone.capture
        microphoneRecorder = audioKitMicrophone.record
        microphoneTracker = audioKitMicrophone.tracker
        rxSetup()
    }
    
    func stopCapturing() {
        guard isCapturing else {
            return
        }
        microphoneCapturer.stop()
        isCapturing = false
    }
    
    func startCapturing() {
        guard !isCapturing else {
            return
        }
        do {
            try microphoneCapturer.start()
        } catch {
            Logger.error("Microphone coudn't start capturing", error: error)
            return
        }
        isCapturing = true
    }
    
    func stopRecording() {
        guard isRecording else {
            return
        }
        microphoneRecorder.stop()
        isRecording = false
        guard let audioFile = microphoneRecorder.audioFile else {
            errorSubject.onNext(AudioError.recordFailure)
            return
        }
        directoryDocumentsSavableSubject.onNext(audioFile)
    }
    
    func startRecording() {
        guard !isRecording else {
            return
        }
        do {
            isRecording = true
            try microphoneRecorder.reset()
            try microphoneRecorder.record()

        } catch {
            isRecording = false
            errorSubject.onNext(AudioError.recordFailure)
            Logger.error("Microphone coudn't start recording", error: AudioError.recordFailure)
        }
    }

    private func rxSetup() {
        microphoneCapturer.bufferReadable
            .subscribe(onNext: { [weak self] bufferReadable in
                guard let self = self else { return }
                let amplitudeInfo = MicrophoneAmplitudeInfo(loudnessFactor: self.microphoneTracker.loudnessFactor, decibels: self.microphoneTracker.decibels)
                self.microphoneAmplitudeSubject.onNext(amplitudeInfo)
                self.microphoneBufferReadableSubject.onNext(bufferReadable)
            }).disposed(by: disposeBag)
    }

}