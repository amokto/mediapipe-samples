//
//  HolisticOverlay.swift
//  PoseLandmarker
//
//  Created by Atle Mæland on 18/10/2024.
//

import UIKit
import MediaPipeTasksVision

/// A straight line.
struct Line {
    let from: CGPoint
    let to: CGPoint
}

/**
 This structure holds the display parameters for the overlay to be drawn on a holistic landmarker object.
 */
struct HolisticOverlay {
    let poseDots: [CGPoint]
    let poseLines: [Line]
    // TODO: Add face and hand overlay properties
}

/// Custom view to visualize the holistic landmarks result on top of the input image.
class HolisticOverlayView: UIView {

    var holisticOverlays: [HolisticOverlay] = []

    private var contentImageSize: CGSize = .zero
    var imageContentMode: UIView.ContentMode = .scaleAspectFit
    private var orientation = UIDeviceOrientation.portrait

    private var edgeOffset: CGFloat = 0.0

    // MARK: Public Functions
    func draw(
        holisticOverlays: [HolisticOverlay],
        inBoundsOfContentImageOfSize imageSize: CGSize,
        edgeOffset: CGFloat = 0.0,
        imageContentMode: UIView.ContentMode) {

        self.clear()
        contentImageSize = imageSize
        self.edgeOffset = edgeOffset
        self.holisticOverlays = holisticOverlays
        self.imageContentMode = imageContentMode
        orientation = UIDevice.current.orientation
        self.setNeedsDisplay()
    }

    func redrawHolisticOverlays(forNewDeviceOrientation deviceOrientation: UIDeviceOrientation) {
        orientation = deviceOrientation

        switch orientation {
        case .portrait, .landscapeLeft, .landscapeRight:
            self.setNeedsDisplay()
        default:
            return
        }
    }

    func clear() {
        holisticOverlays = []
        contentImageSize = .zero
        imageContentMode = .scaleAspectFit
        orientation = UIDevice.current.orientation
        edgeOffset = 0.0
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        for holisticOverlay in holisticOverlays {
            drawLines(holisticOverlay.poseLines)
            drawDots(holisticOverlay.poseDots)
            // TODO: Add drawing for face and hand overlays
        }
    }

    // MARK: Private Functions
    private func drawDots(_ dots: [CGPoint]) {
        for dot in dots {
            let dotRect = CGRect(
                x: CGFloat(dot.x) - DefaultConstants.pointRadius / 2,
                y: CGFloat(dot.y) - DefaultConstants.pointRadius / 2,
                width: DefaultConstants.pointRadius,
                height: DefaultConstants.pointRadius)
            let path = UIBezierPath(ovalIn: dotRect)
            DefaultConstants.pointFillColor.setFill()
            DefaultConstants.pointColor.setStroke()
            path.stroke()
            path.fill()
        }
    }

    private func drawLines(_ lines: [Line]) {
        let path = UIBezierPath()
        for line in lines {
            path.move(to: line.from)
            path.addLine(to: line.to)
        }
        path.lineWidth = DefaultConstants.lineWidth
        DefaultConstants.lineColor.setStroke()
        path.stroke()
    }

    // MARK: Helper Functions
    static func offsetsAndScaleFactor(
        forImageOfSize imageSize: CGSize,
        tobeDrawnInViewOfSize viewSize: CGSize,
        withContentMode contentMode: UIView.ContentMode)
    -> (xOffset: CGFloat, yOffset: CGFloat, scaleFactor: Double) {

        let widthScale = viewSize.width / imageSize.width
        let heightScale = viewSize.height / imageSize.height

        let scaleFactor: Double

        switch contentMode {
        case .scaleAspectFill:
            scaleFactor = max(widthScale, heightScale)
        case .scaleAspectFit:
            scaleFactor = min(widthScale, heightScale)
        default:
            scaleFactor = 1.0
        }

        let scaledSize = CGSize(
            width: imageSize.width * scaleFactor,
            height: imageSize.height * scaleFactor)
        let xOffset = (viewSize.width - scaledSize.width) / 2
        let yOffset = (viewSize.height - scaledSize.height) / 2

        return (xOffset, yOffset, scaleFactor)
    }

    // Helper to get object overlays from detections.
  static func holisticOverlay(
    fromHolisticResult result: HolisticLandmarkerResult?,
    inferredOnImageOfSize originalImageSize: CGSize,
    overlayViewSize: CGSize,
    imageContentMode: UIView.ContentMode,
    andOrientation orientation: UIImage.Orientation) -> HolisticOverlay? {

    guard let result = result,
          !result.poseLandmarks.isEmpty else {
        return nil
    }

    let poseLandmarks = result.poseLandmarks
    debugPrintWorldLandmarks(result.poseWorldLandmarks)
    debugPrintJawOpenScore(result.faceBlendshapes)
    

    let offsetsAndScaleFactor = HolisticOverlayView.offsetsAndScaleFactor(
        forImageOfSize: originalImageSize,
        tobeDrawnInViewOfSize: overlayViewSize,
        withContentMode: imageContentMode)

    let transformedPoseLandmarks: [CGPoint]
    switch orientation {
    case .left:
        transformedPoseLandmarks = poseLandmarks.map { CGPoint(x: CGFloat($0.y), y: 1 - CGFloat($0.x)) }
    case .right:
        transformedPoseLandmarks = poseLandmarks.map { CGPoint(x: 1 - CGFloat($0.y), y: CGFloat($0.x)) }
    default:
        transformedPoseLandmarks = poseLandmarks.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
    }

    let dots: [CGPoint] = transformedPoseLandmarks.map { CGPoint(
        x: $0.x * originalImageSize.width * offsetsAndScaleFactor.scaleFactor + offsetsAndScaleFactor.xOffset,
        y: $0.y * originalImageSize.height * offsetsAndScaleFactor.scaleFactor + offsetsAndScaleFactor.yOffset
    ) }
    
    // Get MPPConnection for pose from the PoseLandmarker
    let lines: [Line] = PoseLandmarker.poseLandmarks.map { connection in
        let start = dots[Int(connection.start)]
        let end = dots[Int(connection.end)]
        return Line(from: start, to: end)
    }

    return HolisticOverlay(poseDots: dots, poseLines: lines)
  }
  
  private static func debugPrintWorldLandmarks(_ poseWorldLandmarks: [Landmark]) {
          if poseWorldLandmarks.isEmpty {
              print("World landmarks are empty")
          } else {
              print("World Landmarks detected:")
              for (index, landmark) in poseWorldLandmarks.enumerated() {
                  print("Landmark \(index): x: \(landmark.x), y: \(landmark.y), z: \(landmark.z), visibility: \(String(describing: landmark.visibility))")
              }
          }
      }
  
  private static func debugPrintJawOpenScore(_ faceBlendshapes: Classifications?) {
          if let faceBlendshapes = faceBlendshapes {
              let categories = faceBlendshapes.categories
              if categories.count > 25 {
                  let jawOpenScore = categories[25].score
                  print("Jaw Open Score: \(jawOpenScore)")
              } else {
                  print("Jaw open data not available (not enough categories)")
              }
          } else {
              print("Face blendshapes not available")
          }
      }
}
