// Copyright 2023 The MediaPipe Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import UIKit
import MediaPipeTasksVision

// MARK: Define default constants
struct DefaultConstants {

  static let lineWidth: CGFloat = 2
  static let pointRadius: CGFloat = 2
  static let pointColor = UIColor.yellow
  static let pointFillColor = UIColor.red

  static let lineColor = UIColor(red: 0, green: 127/255.0, blue: 139/255.0, alpha: 1)

  static var minFaceDetectionConfidence: Float = 0.5
  static var minFaceSuppressionThreshold: Float = 0.3
  static var minFacePresenceConfidence: Float = 0.5
  static var minPoseDetectionConfidence: Float = 0.5
  static var minPoseSuppressionThreshold: Float = 0.3
  static var minPosePresenceConfidence: Float = 0.5
  static var minHandLandmarksConfidence: Float = 0.5
  static let outputFaceBlendshapes: Bool = true
  static let outputPoseSegmentationMasks: Bool = false
  static let delegate: HolisticLandmarkerDelegate = .CPU
  static let model: Model = .holisticLandmarker
}

// MARK: Model
enum Model: Int, CaseIterable {
  case holisticLandmarker

  var name: String {
    return "Holistic Landmarker"
  }

  var modelPath: String? {
    return Bundle.main.path(forResource: "holistic_landmarker", ofType: "task")
  }

  init?(name: String) {
    if name == "Holistic Landmarker" {
      self = .holisticLandmarker
    } else {
      return nil
    }
  }
}

// MARK: PoseLandmarkerDelegate
enum HolisticLandmarkerDelegate: CaseIterable {
  case GPU
  case CPU

  var name: String {
    switch self {
    case .GPU:
      return "GPU"
    case .CPU:
      return "CPU"
    }
  }

  var delegate: Delegate {
    switch self {
    case .GPU:
      return .GPU
    case .CPU:
      return .CPU
    }
  }

  init?(name: String) {
    switch name {
    case HolisticLandmarkerDelegate.CPU.name:
      self = HolisticLandmarkerDelegate.CPU
    case HolisticLandmarkerDelegate.GPU.name:
      self = HolisticLandmarkerDelegate.GPU
    default:
      return nil
    }
  }
}
