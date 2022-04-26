// Copyright © 2022 Rangeproof Pty Ltd. All rights reserved.
import WebRTC
import Foundation

#if arch(arm64)
// Note: 'RTCMTLVideoView' requires arm64 (so won't work on the simulator which
// we need to build for x86_64 due to WebRTC not supporting arm64 simulator builds)
typealias TargetView = RTCMTLVideoView
#else
typealias TargetView = RTCEAGLVideoView
#endif

// MARK: RemoteVideoView

class RemoteVideoView: TargetView {
    
    override func renderFrame(_ frame: RTCVideoFrame?) {
        super.renderFrame(frame)
        guard let frame = frame else { return }
        DispatchMainThreadSafe {
            let frameRatio = Double(frame.height) / Double(frame.width)
            let frameRotation = frame.rotation
            let deviceRotation = UIDevice.current.orientation
            var rotationOverride: RTCVideoRotation? = nil
            switch deviceRotation {
            case .portrait, .portraitUpsideDown:
                // We don't have to do anything, the renderer will automatically make sure it's right-side-up.
                break
            case .landscapeLeft:
                switch frameRotation {
                case RTCVideoRotation._0: rotationOverride = RTCVideoRotation._90 // Landscape left
                case RTCVideoRotation._90: rotationOverride = RTCVideoRotation._180 // Portrait
                case RTCVideoRotation._180: rotationOverride = RTCVideoRotation._270 // Landscape right
                case RTCVideoRotation._270: rotationOverride = RTCVideoRotation._0 // Portrait upside-down
                default: break
                }
            case .landscapeRight:
                switch frameRotation {
                case RTCVideoRotation._0: rotationOverride = RTCVideoRotation._270 // Landscape left
                case RTCVideoRotation._90: rotationOverride = RTCVideoRotation._0 // Portrait
                case RTCVideoRotation._180: rotationOverride = RTCVideoRotation._90 // Landscape right
                case RTCVideoRotation._270: rotationOverride = RTCVideoRotation._180 // Portrait upside-down
                default: break
                }
            default:
                // Do nothing if we're face down, up, etc.
                // Assume we're already setup for the correct orientation.
                break
            }
            
#if arch(arm64)
            if let rotationOverride = rotationOverride {
                self.rotationOverride = NSNumber(value: rotationOverride.rawValue)
                if [ RTCVideoRotation._0, RTCVideoRotation._180 ].contains(rotationOverride) {
                    self.videoContentMode = .scaleAspectFill
                } else {
                    self.videoContentMode = .scaleAspectFit
                }
            } else {
                self.rotationOverride = nil
                if [ RTCVideoRotation._0, RTCVideoRotation._180 ].contains(frameRotation) {
                    self.videoContentMode = .scaleAspectFill
                } else {
                    self.videoContentMode = .scaleAspectFit
                }
            }
            // if not a mobile ratio, always use .scaleAspectFit
            if frameRatio < 1.5 {
                self.videoContentMode = .scaleAspectFit
            }
#endif
        }
    }
}

// MARK: LocalVideoView

class LocalVideoView: TargetView {
    
    static let width: CGFloat = 80
    static let height: CGFloat = 173
    
    override func renderFrame(_ frame: RTCVideoFrame?) {
        super.renderFrame(frame)
        DispatchMainThreadSafe {
            // This is a workaround for a weird issue that
            // sometimes the rotationOverride is not working
            // if it is only set once on initialization
            self.rotationOverride = NSNumber(value: RTCVideoRotation._0.rawValue)
#if arch(arm64)
            self.videoContentMode = .scaleAspectFill
#endif
        }
    }
}
