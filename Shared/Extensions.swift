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
        for i in 0 ..< OriginalPixelData.count{
        ddpPixeldata[i] = AveragePixel * ((OriginalPixelData[i]/(BlurredPixeldata[i] + Bendvalue)))
        }
    var temp = (ddpPixeldata.max(), ddpPixeldata.min())
    print(temp)
    return ddpPixeldata
}
func ddpScaled(ddpPixelData: [Float], MinPixel : Pixel_F) -> [Float]{
    var ddpScaled = ddpPixelData
    var ddpMax = Float(ddpScaled.max()!)
    var ddpMin = Float(ddpScaled.min()!)
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

func optimizedHist(histogram_in : [vImagePixelCount], histogramcount : Int) -> ([vImagePixelCount], Pixel_F, Pixel_F, Int){
    var optimizedHist = histogram_in
    var MaxPixel = 0
    var MinPixel = 0
    var limit = Int(Double(histogramcount) * 0.015)
    var PixelLimitingCount = Int(Double(optimizedHist.reduce(0,+)) * 0.005)
    var PixelLimitingCountUpper = Int(Double(PixelLimitingCount) * 0.01)
    var comparableValue = 0
    var minimumCutoff = 1
    for i in 0 ..< histogramcount {
        if optimizedHist[i] > PixelLimitingCount{
            MinPixel = i
            break
        }
    }
    if MinPixel > 20 {
        MinPixel = MinPixel - 10
    }
    if MinPixel < 5 {
        MinPixel = 1
        minimumCutoff = 0
    }
    
    for i in 0 ..< histogramcount{
        if optimizedHist[i] > 10{
            MaxPixel = i
        }
        
    }
    let difference = MaxPixel - MinPixel
    if difference < 30 {
        MaxPixel = MinPixel + Int(Double(histogramcount) * 0.1)
    }
    var MaxPixel_F = Pixel_F(Float(MaxPixel) / Float(histogramcount))
    var MinPixel_F = Pixel_F(Float(MinPixel) / Float(histogramcount))
    return (optimizedHist, MaxPixel_F, MinPixel_F, minimumCutoff)
}
func forcingMeanData(PixelData : [Float], MinimumLimit: Float) -> [Float]{
    var PixelData = PixelData
    for i in 0 ..< PixelData.count{
        if PixelData[i] < MinimumLimit{
            PixelData[i] = MinimumLimit
        }
    }
    return PixelData
}
func read(Path: String) -> ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat){
    var threeData: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)?
    var path = URL(string: Path)!
    var read_data = try! FitsFile.read(contentsOf: path)
    let prime = read_data?.prime
    print(prime)
    prime?.v_complete(onError: {_ in
        print("CGImage creation error")
    }) { result in
        threeData = result
    }
    return threeData!
}


func display(Path: String) -> ([vImagePixelCount], CGImage, CGImage){
    let threedata = read(Path: Path)
    //target data
    var data = threedata.0
    //Buffer from FITS File
    var buffer = threedata.1
    //Grayscale format from FITS file
    let format = threedata.2
    //destination buffer
    var buffer2 = buffer
    var buffer4 = buffer
    let histogramcount = 1024
    let dataMaxPixel = Pixel_F(data.max()!)
    let dataMinPixel = Pixel_F(data.min()!)
    var histogramBin = histogram(dataMaxPixel: dataMaxPixel, dataMinPixel: dataMinPixel, buffer: buffer, histogramcount: histogramcount)
    //Return three data, Histogram(0), Maximum Pixel Value(1), Minimum Pixel Value(2), Cutoff?(3) = 0 no, 1 yes
    var OptimizedHistogramContents = optimizedHist(histogram_in: histogramBin, histogramcount: histogramcount)
    let lowerPixelLimit = OptimizedHistogramContents.2
    let upperPixelLimit = OptimizedHistogramContents.1
    let cutoff = OptimizedHistogramContents.3
    var histogramOpt = histogram(dataMaxPixel: upperPixelLimit, dataMinPixel: lowerPixelLimit, buffer: buffer, histogramcount: histogramcount)
    print(histogramOpt)
    var buffer3 = buffer
    let kernelwidth = 7
    let kernelheight = 7
    var A : Float = 1.0
    var simgaX: Float = 0.75
    var sigmaY: Float = 0.75
    
    var kernelArray = kArray(width: kernelwidth, height: kernelheight, sigmaX: simgaX, sigmaY: sigmaY, A: A)
    
    print(kernelArray, " " , kernelArray.max())
    vImageConvolve_PlanarF(&buffer, &buffer3, nil, 0, 0, &kernelArray, UInt32(kernelwidth), UInt32(kernelheight), 0, vImage_Flags(kvImageEdgeExtend))

    var BlurredPixelData = (buffer3.data.toArray(to: Float.self, capacity: Int(buffer3.width*buffer3.height)))
    var bendvalue = bendValue(AdjustedData: BlurredPixelData, lowerPixelLimit: lowerPixelLimit) //return bendvalue as .0, and averagepixeldata as .1
    var OriginalPixelData = (buffer.data.toArray(to: Float.self, capacity: Int(buffer.width*buffer.height)))
    //OriginalPixelData = forcingMeanData(PixelData: OriginalPixelData, MinimumLimit: lowerPixelLimit)
    var ddpPixelData = ddpProcessed(OriginalPixelData: OriginalPixelData, BlurredPixeldata: BlurredPixelData, Bendvalue: bendvalue.0, AveragePixel: bendvalue.1, cutOff: cutoff, MinPixel: lowerPixelLimit)
    let ddpScaled = ddpScaled(ddpPixelData: ddpPixelData, MinPixel: lowerPixelLimit)
    
    let DDPwithScale = returningCGImage(data: ddpScaled, buffer: buffer3)
    let originalImage = (try? buffer.createCGImage(format: format))!
    let DDPwithoutScale = returningCGImage(data: ddpPixelData, buffer: buffer3)
    
    print("called")
    
    return(histogramBin, originalImage,  DDPwithScale)
}
