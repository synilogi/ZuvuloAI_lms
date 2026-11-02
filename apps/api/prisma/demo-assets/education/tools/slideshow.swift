// usage: swift slideshow.swift <out.mp4> <secondsPerSlide> <slide1.png> [slide2.png ...]
import AVFoundation
import AppKit

let args = CommandLine.arguments
let out = URL(fileURLWithPath: args[1]); let secs = Int32(args[2])!; let slides = Array(args[3...])
try? FileManager.default.removeItem(at: out)
let W = 1280, H = 720, fps: Int32 = 2
let writer = try! AVAssetWriter(outputURL: out, fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
  AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: W, AVVideoHeightKey: H,
  AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 250_000, AVVideoMaxKeyFrameIntervalKey: Int(fps) * 4, AVVideoProfileLevelKey: AVVideoProfileLevelH264MainAutoLevel],
])
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
  kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: W, kCVPixelBufferHeightKey as String: H,
])
writer.add(input); writer.startWriting(); writer.startSession(atSourceTime: .zero)

func buffer(_ path: String) -> CVPixelBuffer {
  let image = NSImage(contentsOfFile: path)!
  var cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
  var pb: CVPixelBuffer?
  CVPixelBufferCreate(nil, W, H, kCVPixelFormatType_32ARGB, nil, &pb)
  CVPixelBufferLockBaseAddress(pb!, [])
  let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pb!), width: W, height: H, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pb!),
                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
  ctx.draw(cg, in: CGRect(x: 0, y: 0, width: W, height: H)); _ = cg
  CVPixelBufferUnlockBaseAddress(pb!, [])
  return pb!
}

var frame: Int64 = 0
for slide in slides {
  let pb = buffer(slide)
  for _ in 0..<(secs * fps) {
    while !input.isReadyForMoreMediaData { usleep(1000) }
    adaptor.append(pb, withPresentationTime: CMTime(value: frame, timescale: fps)); frame += 1
  }
}
input.markAsFinished()
let done = DispatchSemaphore(value: 0)
writer.endSession(atSourceTime: CMTime(value: frame, timescale: fps))
writer.finishWriting { done.signal() }
done.wait()
print(writer.status == .completed ? "ok \(out.lastPathComponent) \(frame / Int64(fps))s" : "failed \(String(describing: writer.error))")
