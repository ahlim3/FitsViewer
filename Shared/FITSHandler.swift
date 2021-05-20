//
//  Extension.swift
//  FitsViewer
//
//  Created by anthony lim on 5/18/21.
//

import Foundation
import Accelerate
import Accelerate.vImage
import FITS
import FITSKit


class FITSHandler: ObservableObject{
    var MaxPixel_F = Pixel_F(1.00)
    var MinPixel_F = Pixel_F(0.03)
    var xpoints = [Double]()
    var ypoints = [Double]()
    var threeData: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)?
    var procssedImage: CGImage!

    


func histogram(dataMaxPixel: Pixel_F, dataMinPixel: Pixel_F, buffer : vImage_Buffer, histogramcount: Int) -> [vImagePixelCount]{
    var buffer = buffer
    var histogramBin = [vImagePixelCount](repeating: 0, count: histogramcount)
    let histogramBinPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: histogramBin)
    histogramBin.withUnsafeMutableBufferPointer() { Ptr in
                        let error =
                            vImageHistogramCalculation_PlanarF(&buffer, histogramBinPtr, UInt32(histogramcount), dataMinPixel, dataMaxPixel, vImage_Flags(kvImageNoFlags))
                            guard error == kvImageNoError else {
                            fatalError("Error calculating histogram: \(error)")
                        }
                    }
    return histogramBin
}

func returningCGImage(data: [Float], width: Int, height: Int, rowBytes: Int) -> CGImage{
    let pixelDataAsData = Data(fromArray: data)
    let cfdata = NSData(data: pixelDataAsData) as CFData
    
    let provider = CGDataProvider(data: cfdata)!
    
    let bitmapInfo: CGBitmapInfo = [
        .byteOrder32Little,
        .floatComponents]
          
    let pixelCGImage = CGImage(width:  width, height: height, bitsPerComponent: 32, bitsPerPixel: 32, bytesPerRow: rowBytes, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    return pixelCGImage
}


    func forcingMeanData(PixelData : [Float], MinimumLimit: Float, MaximumLimit:Float) -> [Float]{
    var PixelData = PixelData
    for i in 0 ..< PixelData.count{
        if PixelData[i] < MinimumLimit{
            PixelData[i] = MinimumLimit
        }
    }
    for i in 0 ..< PixelData.count{
            if PixelData[i] > Float(MaximumLimit) {
                PixelData[i] = MaximumLimit
        }
    }
    return PixelData
}
    func returnInfo(ThreeData : ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)) -> ([vImagePixelCount], CGImage, CGImage){
        let threedata = ThreeData
        //target data
        let data = threedata.0
        //Buffer from FITS File
        let buffer = threedata.1
        //Grayscale format from FITS file
        let format = threedata.2
        //destination buffer
        let width :Int = Int(buffer.width)
        let height: Int = Int(buffer.height)
        let rowBytes :Int = width*4
        let histogramcount = 256
        let histogramBin = histogram(dataMaxPixel: Pixel_F(data.max()!), dataMinPixel: Pixel_F(data.min()!), buffer: buffer, histogramcount: histogramcount)
        let histMax = Double(histogramBin.max()!)
        var xpointsinside = [Double]()
        var ypointsinside = [Double]()
        for i in 0 ..< histogramcount{
            xpointsinside.append(Double(i) / Double(histogramcount))
            ypointsinside.append(Double(histogramBin[i])/histMax)
        }
        xpoints = xpointsinside
        ypoints = ypointsinside
        let lowerPixelLimit = MinPixel_F
        let upperPixelLimit = MaxPixel_F
        let histogramOpt = histogram(dataMaxPixel: upperPixelLimit, dataMinPixel: lowerPixelLimit, buffer: buffer, histogramcount: histogramcount)
        print(histogramOpt)
        var OriginalPixelData = (buffer.data.toArray(to: Float.self, capacity: Int(buffer.width*buffer.height)))
        OriginalPixelData = forcingMeanData(PixelData: OriginalPixelData, MinimumLimit: lowerPixelLimit, MaximumLimit: upperPixelLimit)
        let forcedOriginalData = returningCGImage(data: OriginalPixelData, width: width, height: height, rowBytes: rowBytes)
        var forcedbuffer = try! vImage_Buffer(cgImage: forcedOriginalData, format: format)
        var buffer3 = buffer
        var kernelwidth = 9
        var kernelheight = 9
        var A : Float = 1.0
        var simgaX: Float = 0.75
        var sigmaY: Float = 0.75
        
        var kernelArray = kArray(width: kernelwidth, height: kernelheight, sigmaX: simgaX, sigmaY: sigmaY, A: A)
        vImageConvolve_PlanarF(&forcedbuffer, &buffer3, nil, 0, 0, &kernelArray, UInt32(kernelwidth), UInt32(kernelheight), 0, vImage_Flags(kvImageEdgeExtend))

        let BlurredPixelData = (buffer3.data.toArray(to: Float.self, capacity: Int(buffer3.width*buffer3.height)))
        OriginalPixelData = (buffer.data.toArray(to: Float.self, capacity: Int(buffer.width*buffer.height)))
        //Bendvalue of DDP
        
        let bendvalue = bendValue(AdjustedData: BlurredPixelData, lowerPixelLimit: lowerPixelLimit) //return bendvalue as .0, and averagepixeldata as .1

        let ddpPixelData = ddpProcessed(OriginalPixelData: OriginalPixelData, BlurredPixeldata: BlurredPixelData, Bendvalue: bendvalue.0, AveragePixel: bendvalue.1, MinPixel: lowerPixelLimit)
        let DDPScaled = ddpScaled(ddpPixelData: ddpPixelData, MinPixel: lowerPixelLimit)
        let DDPwithScale = returningCGImage(data: DDPScaled, width: width, height: height, rowBytes: rowBytes)
        procssedImage = DDPwithScale
        let originalImage = (try? buffer.createCGImage(format: format))!
        print("called")
        return(histogramBin, originalImage,  DDPwithScale)
        }

}

