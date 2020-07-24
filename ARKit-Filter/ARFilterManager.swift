//
//  ARFilterManager.swift
//  
//
//  Created by xu on 2019/4/18.
//  Copyright © 2019 du. All rights reserved.
//

import UIKit
import GPUImage

class ARFilterManager: NSObject {
    
    public var selectIndex: Int? {
        didSet {
            if selectIndex != oldValue {
                filterChange = true
            }
        }
    }
    
    public static let shared = ARFilterManager()
    
    private var semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
    private var rgbBuffer: CVPixelBuffer?
    
    private var input: GPUImageMovie = GPUImageMovie(asset: nil)
    private var pipeline: GPUImageFilterPipeline!
    
    private let filters = ["GPUImageSobelEdgeDetectionFilter","GPUImageKuwaharaRadius3Filter","GPUImageiOSBlurFilter","GPUImageSketchFilter","GPUImageGrayscaleFilter"]
    
    private var filterChange: Bool = false
    private var _index: Int = 0
        
    @objc open class func sharedInstance() -> ARFilterManager {
        return ARFilterManager.shared
    }
    
    override init() {
        super.init()
        let output = GPUImageFilter()
        
        pipeline = GPUImageFilterPipeline(orderedFilters: [], input: input, output: output)
        
        output.frameProcessingCompletionBlock = { [weak self] (output, time) -> Void  in
            let frameBuffer = output?.framebufferForOutput()
            
            guard let buffer = frameBuffer else {
                return;
            }
            
            glFinish()
            
            self?.rgbBuffer = buffer.getRenderTarget()?.takeUnretainedValue()
            
            self?.semaphore.signal()
        }
    }
    
    @objc
    public func process(pixelBuffer: CVPixelBuffer) -> Void {
        guard pipeline.filters.count > 0 || filterChange else {
            return
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let final_y_buffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)?.assumingMemoryBound(to: uint8.self);
        let final_uv_buffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)?.assumingMemoryBound(to: uint8.self);
        input.processMovieFrame(pixelBuffer, withSampleTime: .zero)
        _ = semaphore.wait(timeout: .distantFuture)
        CVPixelBufferLockBaseAddress(rgbBuffer!, [])
        let width = CVPixelBufferGetWidth(rgbBuffer!)
        let height = CVPixelBufferGetHeight(rgbBuffer!)
        let rgbAddress = CVPixelBufferGetBaseAddress(rgbBuffer!)?.assumingMemoryBound(to: uint8.self)
        ARGBToNV12(rgbAddress, Int32(width*4), final_y_buffer, Int32(width), final_uv_buffer, Int32(width), Int32(width), Int32(height))
        CVPixelBufferUnlockBaseAddress(rgbBuffer!, [])
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        if filterChange {
            switchFilter()
        }
    }
    
    private func switchFilter() -> Void {
        filterChange = false
        if let index = selectIndex {
            if (index >= filters.count) {
                selectIndex = nil
                _index = 0
                return
            }
            pipeline.removeAllFilters()
            if let _filter = filter(name: filters[index]) as? (GPUImageOutput & GPUImageInput) {
                pipeline.addFilter(_filter)
            }
        }else{
            pipeline.removeAllFilters()
        }
    }
    
    func next() {
        selectIndex = _index
        _index += 1
    }
    
    private func filter(name: String) -> GPUImageInput? {
        guard let typeClass = NSClassFromString(name) else {
            return nil
        }
        if let cls = typeClass as? GPUImageFilter.Type {
            return cls.init()
        }else if let cls = typeClass as? GPUImageFilterGroup.Type {
            return cls.init()
        }
        return nil
    }
    
    func process(image: UIImage?,index: Int?) -> UIImage? {
        if let idx = index {
            let _filter = filter(name: filters[idx]) as! GPUImageOutput
            let pic = GPUImagePicture(image: image)
            pic?.addTarget((_filter as! GPUImageInput))
            pic?.processImage()
            _filter.useNextFrameForImageCapture()
            return _filter.imageFromCurrentFramebuffer()
        }else{
            return image
        }
    }
    
}
