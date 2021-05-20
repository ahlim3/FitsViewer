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
    var MaxPixel_F = Pixel_F(1.00)
    var MinPixel_F = Pixel_F(0.01)
    

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
        if PixelData[i] > Float(0.9){
            if PixelData[i] > Float(0.95) {
                PixelData[i] = MaximumLimit
            }
        }
    }
    return PixelData
}

}

