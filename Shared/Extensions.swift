//
//  Extensions.swift
//  FitsViewer
//
//  Created by anthony lim on 4/29/21.
//
import Foundation
import FITS
import FITSKit
import Accelerate
import Accelerate.vImage
import Combine
import CoreGraphics


extension UnsafeMutableRawPointer {
    func toArray<T>(to type: T.Type, capacity count: Int) -> [T]{
        let pointer = bindMemory(to: type, capacity: count)
        return Array(UnsafeBufferPointer(start: pointer, count: count))
    }
}


extension Data {

    init<T>(fromArray values: [T]) {
        self = values.withUnsafeBytes { Data($0) }
    }

    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = Array<T>(repeating: 0, count: self.count/MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
        return array
    }
}
func kArray(width: Int, height: Int, sigmaX: Float, sigmaY: Float, A: Float) -> [Float]
{
    let kernelwidth = width
    let kernelheight = height
    var kernelArray = [Float]()
    //var Volume = 2.0 * Float.pi * A * simgaX * sigmaY
    for i in 0 ..< kernelwidth{
        let xposition = Float(i - kernelwidth / 2)
        for j in 0 ..< kernelheight{
        let yposition = Float(j - kernelheight / 2)
            var xponent = -xposition * xposition / (Float(2.0) * sigmaX * sigmaX)
            var yponent = -yposition * yposition / (Float(2.0) * sigmaY * sigmaY)
            let answer = A * exp (xponent + yponent)
            kernelArray.append(answer)
        }
    }
    var sum = kernelArray.reduce(0, +)
    for i in 0 ..< kernelArray.count{
        kernelArray[i] = kernelArray[i] / sum
    }
    return kernelArray
}

func bendValue(AdjustedData: [Float], lowerPixelLimit: Pixel_F) -> (Float, Float){
    let myMin:Float = 0.0
    var blackLevel:Float = 0.0
    var AdjustedData = AdjustedData
    
    if(AdjustedData.min()! > myMin.ulp  ){
    
        blackLevel = AdjustedData.min()! * 0.75
    }
    else{
        
        blackLevel = 0.1
    }
    
    for i in 0 ..< AdjustedData.count{
        
        AdjustedData[i] = blackLevel
        
    }
    let averagePixelData = AdjustedData.mean
    var bendValue = Float(0.0)
           if averagePixelData * 2.0 > 1.0 {
               bendValue = (1.0 - averagePixelData)/2 + averagePixelData
           }
           else
           {
            bendValue = 1.5 * averagePixelData
           }
    return (bendValue, averagePixelData)
}

func ddpProcessed(OriginalPixelData: [Float], BlurredPixeldata: [Float], Bendvalue : Float, AveragePixel: Float, cutOff: Int, MinPixel : Pixel_F) -> [Float]{
    var OriginalPixelData = OriginalPixelData
    var ddpPixeldata = OriginalPixelData
    let MinPixel = Float(MinPixel)
    if cutOff == 1{
        for i in 0 ..< OriginalPixelData.count{
            if OriginalPixelData[i] < MinPixel{
                OriginalPixelData[i] = MinPixel
            }
            else{
                OriginalPixelData[i] = OriginalPixelData[i]
            }
        }
    }
        for i in 0 ..< OriginalPixelData.count{
        ddpPixeldata[i] = AveragePixel * ((OriginalPixelData[i]/(BlurredPixeldata[i] + Bendvalue)))
        }
    var temp = (ddpPixeldata.max(), ddpPixeldata.min())
    return ddpPixeldata
}
func ddpScaled(ddpPixelData: [Float], MinPixel : Pixel_F) -> [Float]{
    var ddpScaled = ddpPixelData
    var ddpMax = Float(ddpScaled.max()!)
    var ddpMin = Float(ddpScaled.min()!)
    if ddpMin < Float(MinPixel){
        ddpMin = Float(MinPixel)
    }
    for i in 0 ..< ddpScaled.count{
        if ddpScaled[i] < ddpMin{
            ddpScaled[i] = ddpMin
        }
    }
    var adjustable = ddpMax - ddpMin
    for i in 0 ..< ddpScaled.count{
        ddpScaled[i] = (ddpScaled[i] - ddpMin) / adjustable
    }
    print(ddpScaled.max(), ddpScaled.min())
    return ddpScaled
}
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

func returningCGImage(data: [Float], buffer: vImage_Buffer) -> CGImage{
    let pixelDataAsData = Data(fromArray: data)
    let cfdata = NSData(data: pixelDataAsData) as CFData
    
    let provider = CGDataProvider(data: cfdata)!
    
    let width :Int = Int(buffer.width)
    let height: Int = Int(buffer.height)
    let rowBytes :Int = width*4
    
    let bitmapInfo: CGBitmapInfo = [
        .byteOrder32Little,
        .floatComponents]
          
    let pixelCGImage = CGImage(width:  width, height: height, bitsPerComponent: 32, bitsPerPixel: 32, bytesPerRow: rowBytes, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    return pixelCGImage
}
