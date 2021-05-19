//
//  Extension.swift
//  FitsViewer
//
//  Created by anthony lim on 5/18/21.
//

import Foundation
import Accelerate
import Accelerate.vImage


class FITSHandler: ObservableObject{
    var accuracyLow = 0.03
    var accuracyHigh = 0.001
    
    func OptValue(histogram_in : [vImagePixelCount], histogramcount : Int) -> (Pixel_F, Pixel_F, Int){
        var MaxPixel = 0
        var MinPixel = 0
        let PixelLimitingCount = Int(Double(histogram_in.reduce(0,+)) * accuracyLow)
        let PixelLimitingCountHigh = Int(Double(histogram_in.reduce(0,+)) * accuracyHigh)
        var minimumCutoff = 1
        for i in 0 ..< histogramcount {
            if histogram_in[i] > PixelLimitingCount{
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
            if histogram_in[i] > PixelLimitingCountHigh{
                MaxPixel = i
            }
            
        }
        //let difference = MaxPixel - MinPixel
        //if difference < 30 {
        //    MaxPixel = MinPixel + Int(Double(histogramcount) * 0.1)
        //}
        let MaxPixel_F = Pixel_F(Float(MaxPixel) / Float(histogramcount))
        let MinPixel_F = Pixel_F(Float(MinPixel) / Float(histogramcount))
        return (MaxPixel_F, MinPixel_F, minimumCutoff)
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


func forcingMeanData(PixelData : [Float], MinimumLimit: Float) -> [Float]{
    var PixelData = PixelData
    for i in 0 ..< PixelData.count{
        if PixelData[i] < MinimumLimit{
            PixelData[i] = MinimumLimit
        }
    }
    return PixelData
}

}

