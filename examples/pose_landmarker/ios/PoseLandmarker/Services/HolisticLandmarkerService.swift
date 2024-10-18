import UIKit
import MediaPipeTasksVision
import AVFoundation

protocol HolisticLandmarkerServiceLiveStreamDelegate: AnyObject {
    func holisticLandmarkerService(
        _ holisticLandmarkerService: HolisticLandmarkerService,
        didFinishDetection result: ResultBundle?,
        error: Error?)
}

protocol HolisticLandmarkerServiceVideoDelegate: AnyObject {
    func holisticLandmarkerService(
        _ holisticLandmarkerService: HolisticLandmarkerService,
        didFinishDetectionOnVideoFrame index: Int)
    func holisticLandmarkerService(
        _ holisticLandmarkerService: HolisticLandmarkerService,
        willBeginDetection totalframeCount: Int)
}

class HolisticLandmarkerService: NSObject {
    weak var liveStreamDelegate: HolisticLandmarkerServiceLiveStreamDelegate?
    weak var videoDelegate: HolisticLandmarkerServiceVideoDelegate?

    var holisticLandmarker: HolisticLandmarker?
    private(set) var runningMode = RunningMode.image
    private var modelPath: String
    private var minFaceDetectionConfidence: Float
    private var minFaceSuppressionThreshold: Float
    private var minFacePresenceConfidence: Float
    private var minPoseDetectionConfidence: Float
    private var minPoseSuppressionThreshold: Float
    private var minPosePresenceConfidence: Float
    private var minHandLandmarksConfidence: Float
    private var outputFaceBlendshapes: Bool
    private var outputPoseSegmentationMasks: Bool

    private init?(
        modelPath: String?,
        runningMode: RunningMode,
        minFaceDetectionConfidence: Float,
        minFaceSuppressionThreshold: Float,
        minFacePresenceConfidence: Float,
        minPoseDetectionConfidence: Float,
        minPoseSuppressionThreshold: Float,
        minPosePresenceConfidence: Float,
        minHandLandmarksConfidence: Float,
        outputFaceBlendshapes: Bool,
        outputPoseSegmentationMasks: Bool
    ) {
        guard let modelPath = modelPath else { return nil }
        self.modelPath = modelPath
        self.runningMode = runningMode
        self.minFaceDetectionConfidence = minFaceDetectionConfidence
        self.minFaceSuppressionThreshold = minFaceSuppressionThreshold
        self.minFacePresenceConfidence = minFacePresenceConfidence
        self.minPoseDetectionConfidence = minPoseDetectionConfidence
        self.minPoseSuppressionThreshold = minPoseSuppressionThreshold
        self.minPosePresenceConfidence = minPosePresenceConfidence
        self.minHandLandmarksConfidence = minHandLandmarksConfidence
        self.outputFaceBlendshapes = outputFaceBlendshapes
        self.outputPoseSegmentationMasks = outputPoseSegmentationMasks

        super.init()
        createHolisticLandmarker()
    }

    private func createHolisticLandmarker() {
        let holisticLandmarkerOptions = HolisticLandmarkerOptions()
        holisticLandmarkerOptions.runningMode = runningMode
        holisticLandmarkerOptions.minFaceDetectionConfidence = minFaceDetectionConfidence
        holisticLandmarkerOptions.minFaceSuppressionThreshold = minFaceSuppressionThreshold
        holisticLandmarkerOptions.minFacePresenceConfidence = minFacePresenceConfidence
        holisticLandmarkerOptions.minPoseDetectionConfidence = minPoseDetectionConfidence
        holisticLandmarkerOptions.minPoseSuppressionThreshold = minPoseSuppressionThreshold
        holisticLandmarkerOptions.minPosePresenceConfidence = minPosePresenceConfidence
        holisticLandmarkerOptions.minHandLandmarksConfidence = minHandLandmarksConfidence
        holisticLandmarkerOptions.outputFaceBlendshapes = outputFaceBlendshapes
        holisticLandmarkerOptions.outputPoseSegmentationMasks = outputPoseSegmentationMasks
        holisticLandmarkerOptions.baseOptions.modelAssetPath = modelPath

        if runningMode == .liveStream {
            holisticLandmarkerOptions.holisticLandmarkerLiveStreamDelegate = self
        }
        do {
            holisticLandmarker = try HolisticLandmarker(options: holisticLandmarkerOptions)
        } catch {
            print("Error creating HolisticLandmarker: \(error)")
        }
    }

    // MARK: - Static Initializers

    static func videoHolisticLandmarkerService(
        modelPath: String?,
        minFaceDetectionConfidence: Float,
        minFaceSuppressionThreshold: Float,
        minFacePresenceConfidence: Float,
        minPoseDetectionConfidence: Float,
        minPoseSuppressionThreshold: Float,
        minPosePresenceConfidence: Float,
        minHandLandmarksConfidence: Float,
        outputFaceBlendshapes: Bool,
        outputPoseSegmentationMasks: Bool,
        videoDelegate: HolisticLandmarkerServiceVideoDelegate?
    ) -> HolisticLandmarkerService? {
        let service = HolisticLandmarkerService(
            modelPath: modelPath,
            runningMode: .video,
            minFaceDetectionConfidence: minFaceDetectionConfidence,
            minFaceSuppressionThreshold: minFaceSuppressionThreshold,
            minFacePresenceConfidence: minFacePresenceConfidence,
            minPoseDetectionConfidence: minPoseDetectionConfidence,
            minPoseSuppressionThreshold: minPoseSuppressionThreshold,
            minPosePresenceConfidence: minPosePresenceConfidence,
            minHandLandmarksConfidence: minHandLandmarksConfidence,
            outputFaceBlendshapes: outputFaceBlendshapes,
            outputPoseSegmentationMasks: outputPoseSegmentationMasks
        )
        service?.videoDelegate = videoDelegate
        return service
    }

    static func liveStreamHolisticLandmarkerService(
        modelPath: String?,
        minFaceDetectionConfidence: Float,
        minFaceSuppressionThreshold: Float,
        minFacePresenceConfidence: Float,
        minPoseDetectionConfidence: Float,
        minPoseSuppressionThreshold: Float,
        minPosePresenceConfidence: Float,
        minHandLandmarksConfidence: Float,
        outputFaceBlendshapes: Bool,
        outputPoseSegmentationMasks: Bool,
        liveStreamDelegate: HolisticLandmarkerServiceLiveStreamDelegate?
    ) -> HolisticLandmarkerService? {
        let service = HolisticLandmarkerService(
            modelPath: modelPath,
            runningMode: .liveStream,
            minFaceDetectionConfidence: minFaceDetectionConfidence,
            minFaceSuppressionThreshold: minFaceSuppressionThreshold,
            minFacePresenceConfidence: minFacePresenceConfidence,
            minPoseDetectionConfidence: minPoseDetectionConfidence,
            minPoseSuppressionThreshold: minPoseSuppressionThreshold,
            minPosePresenceConfidence: minPosePresenceConfidence,
            minHandLandmarksConfidence: minHandLandmarksConfidence,
            outputFaceBlendshapes: outputFaceBlendshapes,
            outputPoseSegmentationMasks: outputPoseSegmentationMasks
        )
        service?.liveStreamDelegate = liveStreamDelegate
        return service
    }

    static func stillImageHolisticLandmarkerService(
        modelPath: String?,
        minFaceDetectionConfidence: Float,
        minFaceSuppressionThreshold: Float,
        minFacePresenceConfidence: Float,
        minPoseDetectionConfidence: Float,
        minPoseSuppressionThreshold: Float,
        minPosePresenceConfidence: Float,
        minHandLandmarksConfidence: Float,
        outputFaceBlendshapes: Bool,
        outputPoseSegmentationMasks: Bool
    ) -> HolisticLandmarkerService? {
        return HolisticLandmarkerService(
            modelPath: modelPath,
            runningMode: .image,
            minFaceDetectionConfidence: minFaceDetectionConfidence,
            minFaceSuppressionThreshold: minFaceSuppressionThreshold,
            minFacePresenceConfidence: minFacePresenceConfidence,
            minPoseDetectionConfidence: minPoseDetectionConfidence,
            minPoseSuppressionThreshold: minPoseSuppressionThreshold,
            minPosePresenceConfidence: minPosePresenceConfidence,
            minHandLandmarksConfidence: minHandLandmarksConfidence,
            outputFaceBlendshapes: outputFaceBlendshapes,
            outputPoseSegmentationMasks: outputPoseSegmentationMasks
        )
    }

    // MARK: - Detection Methods

    func detect(image: UIImage) -> ResultBundle? {
        guard let mpImage = try? MPImage(uiImage: image) else {
            return nil
        }
        do {
            let startDate = Date()
            let result = try holisticLandmarker?.detect(image: mpImage)
            let inferenceTime = Date().timeIntervalSince(startDate) * 1000
            return ResultBundle(inferenceTime: inferenceTime, holisticLandmarkerResults: [result])
        } catch {
            print("Error detecting holistic landmarks: \(error)")
            return nil
        }
    }

    func detectAsync(
        sampleBuffer: CMSampleBuffer,
        orientation: UIImage.Orientation,
        timeStamps: Int
    ) {
        guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: orientation) else {
            return
        }
        do {
            try holisticLandmarker?.detectAsync(image: image, timestampInMilliseconds: timeStamps)
        } catch {
            print("Error detecting holistic landmarks asynchronously: \(error)")
        }
    }

    func detect(
        videoAsset: AVAsset,
        durationInMilliseconds: Double,
        inferenceIntervalInMilliseconds: Double
    ) async -> ResultBundle? {
        let startDate = Date()
        let assetGenerator = imageGenerator(with: videoAsset)

        let frameCount = Int(durationInMilliseconds / inferenceIntervalInMilliseconds)
        Task { @MainActor in
            videoDelegate?.holisticLandmarkerService(self, willBeginDetection: frameCount)
        }

        let holisticLandmarkerResultTuple = await detectHolisticLandmarksInFramesGenerated(
            by: assetGenerator,
            totalFrameCount: frameCount,
            atIntervalsOf: inferenceIntervalInMilliseconds)

        return ResultBundle(
            inferenceTime: Date().timeIntervalSince(startDate) / Double(frameCount) * 1000,
            holisticLandmarkerResults: holisticLandmarkerResultTuple.holisticLandmarkerResults,
            size: holisticLandmarkerResultTuple.videoSize)
    }

    private func imageGenerator(with videoAsset: AVAsset) -> AVAssetImageGenerator {
        let generator = AVAssetImageGenerator(asset: videoAsset)
        generator.requestedTimeToleranceBefore = CMTimeMake(value: 1, timescale: 25)
        generator.requestedTimeToleranceAfter = CMTimeMake(value: 1, timescale: 25)
        generator.appliesPreferredTrackTransform = true
        return generator
    }

    private func detectHolisticLandmarksInFramesGenerated(
        by assetGenerator: AVAssetImageGenerator,
        totalFrameCount frameCount: Int,
        atIntervalsOf inferenceIntervalMs: Double
    ) async -> (holisticLandmarkerResults: [HolisticLandmarkerResult?], videoSize: CGSize) {
        var holisticLandmarkerResults: [HolisticLandmarkerResult?] = []
        var videoSize = CGSize.zero

        for i in 0..<frameCount {
            let timestampMs = Int(inferenceIntervalMs) * i
            let image: CGImage
            do {
                let time = CMTime(value: Int64(timestampMs), timescale: 1000)
                image = try assetGenerator.copyCGImage(at: time, actualTime: nil)
            } catch {
                print("Error generating frame: \(error)")
                continue
            }

            let uiImage = UIImage(cgImage: image)
            videoSize = uiImage.size

            do {
                let result = try holisticLandmarker?.detect(
                    videoFrame: MPImage(uiImage: uiImage),
                    timestampInMilliseconds: timestampMs)
                holisticLandmarkerResults.append(result)
                Task { @MainActor in
                    videoDelegate?.holisticLandmarkerService(self, didFinishDetectionOnVideoFrame: i)
                }
            } catch {
                print("Error detecting holistic landmarks on video frame: \(error)")
            }
        }

        return (holisticLandmarkerResults, videoSize)
    }
}

extension HolisticLandmarkerService: HolisticLandmarkerLiveStreamDelegate {
    func holisticLandmarker(
        _ holisticLandmarker: HolisticLandmarker,
        didFinishDetection result: HolisticLandmarkerResult?,
        timestampInMilliseconds: Int,
        error: (any Error)?
    ) {
        let resultBundle = ResultBundle(
            inferenceTime: Date().timeIntervalSince1970 * 1000 - Double(timestampInMilliseconds),
            holisticLandmarkerResults: [result])
        liveStreamDelegate?.holisticLandmarkerService(
            self,
            didFinishDetection: resultBundle,
            error: error)
    }
}

struct ResultBundle {
    let inferenceTime: Double
    let holisticLandmarkerResults: [HolisticLandmarkerResult?]
    var size: CGSize = .zero
}
