#!/bin/bash
# Copyright 2023 The MediaPipe Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Download holistic_landmarker.task from the internet if it's not exist.
TASK_FILE=./PoseLandmarker/holistic_landmarker.task
if test -f "$TASK_FILE"; then
    echo "INFO: holistic_landmarker.task existed. Skip downloading and use the local model."
else
    curl -o ${TASK_FILE} https://storage.googleapis.com/mediapipe-models/holistic_landmarker/holistic_landmarker/float16/latest/holistic_landmarker.task
    echo "INFO: Downloaded holistic_landmarker.task to $TASK_FILE ."
fi
