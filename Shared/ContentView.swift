//
//  ContentView.swift
//  Shared
//
//  Created by anthony lim on 4/20/21.
//

import SwiftUI
import FITS
import FITSKit
import Accelerate
import Accelerate.vImage
import Combine
import CoreGraphics

struct ContentView: View {

    

    var path = "file:///Users/anthonylim/Downloads/2020-12-03_19;56;17.fits"
    let path1 = "file:///Users/anthonylim/Downloads/2020-12-03_19;56;17.fits"
    let path2 = "file:///Users/anthonylim/Downloads/n5194.fits"
    let path3 = "file:///Users/anthonylim/Downloads/HIP115691-ID14333-OC148763-GR7975-LUM.fit"
    let path4 = "file:///Users/anthonylim/Downloads/JtIMAGE_009.fits"
    let path5 = "file:///Users/anthonylim/Downloads/2020-12-03_19_16_43.fits"
    //Work
    let path6 = "file:///Users/anthonylim/Downloads/moon_BIN_1x1_0.0010s_002.fits"
    
    let path7 = "file:///Users/anthonylim/Downloads/NGC4438-104275-LUM.fit"
    //Does not work with the black point on outside
    let path8 = "file:///Users/anthonylim/Downloads/M66-ID10979-OC144423-GR4135-LUM2.fit"
    // Work
    let path9 = "file:///Users/anthonylim/Downloads/NGC6960-ID14567-OC148925-GR8123-LUM.fit"
    //work
    let path10 = "file:///Users/anthonylim/Downloads/globular.fits"
    let histogramcount = 1024
    @State var called = 0
    
    func read() -> ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat){
        var threeData: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)?
        var path = URL(string: path7)!
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
    func optimizedHist(histogram_in : [vImagePixelCount], histogramcount : Int) -> ([vImagePixelCount], Pixel_F, Pixel_F, Int){
        var optimizedHist = histogram_in
        var MaxPixel = 0
        var MinPixel = 0
        var limit = Int(Double(histogramcount) * 0.015)
        var PixelLimitingCount = Int(Double(optimizedHist.reduce(0,+)) * 0.005)
        var comparableValue = 0
        var minimumCutoff = 0
        for i in 0 ..< limit{
            comparableValue += Int(optimizedHist[i])
        }
        if comparableValue < PixelLimitingCount{
            for i in 0 ..< limit{
                optimizedHist[i] = 0
            }
            minimumCutoff = 1
            }
        else
        {
            minimumCutoff = 0
        }

        for i in 0 ..< histogramcount{
            if optimizedHist[i] < 10 {
                optimizedHist[i] = 0
            }
            else{
                optimizedHist[i] = optimizedHist[i]
                MaxPixel = i
            }
            
        }
        for i in 10 ..< histogramcount{
            if optimizedHist[i] == 0{
                MinPixel = i
            }
            else{
                break
            }
        }
        var MaxPixel_F = Pixel_F(Float(MaxPixel) / Float(histogramcount))
        var MinPixel_F = Pixel_F(Float(MinPixel) / Float(histogramcount))
        return (optimizedHist, MaxPixel_F, MinPixel_F, minimumCutoff)
        
    }

    func display() -> ([vImagePixelCount], CGImage, CGImage, CGImage){
        let threedata = read()
        //target data
        var data = threedata.0
        //Buffer from FITS File
        var buffer = threedata.1
        //Grayscale format from FITS file
        let format = threedata.2
        //destination buffer
        var buffer2 = buffer
        var buffer4 = buffer
        var histogramBin = histogram(data: data, buffer: buffer, histogramcount: histogramcount)
        //Return three data, Histogram(0), Maximum Pixel Value(1), Minimum Pixel Value(2), Cutoff?(3) = 0 no, 1 yes
        var OptimizedHistogramContents = optimizedHist(histogram_in: histogramBin, histogramcount: histogramcount)
        let lowerPixelLimit = OptimizedHistogramContents.2
        let upperPixelLimit = OptimizedHistogramContents.1
        let cutoff = OptimizedHistogramContents.3
        var optimized_histogram = histogramBin
        let optimized_histogramBinPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: optimized_histogram)
        histogramBin.withUnsafeMutableBufferPointer() { Ptr in
                            let error =
                                vImageHistogramCalculation_PlanarF(&buffer, optimized_histogramBinPtr, UInt32(histogramcount), lowerPixelLimit, upperPixelLimit, vImage_Flags(kvImageNoFlags))
                                guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
        print(optimized_histogram)
        /*
        var histogramBin2 = [vImagePixelCount](repeating: 0, count: histogramcount)
        let histogramBinPtr2 = UnsafeMutablePointer<vImagePixelCount>(mutating: histogramBin2)
        histogramBin2.withUnsafeMutableBufferPointer() { Ptr in
                            let error =
                                vImageHistogramCalculation_PlanarF(&buffer4, histogramBinPtr2, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
                                guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
        print(histogramBin2)
 */
        //vImageEndsInContrastStretch_PlanarF(&buffer, &buffer2, nil, 0, 50, histogramcount, 0.0, 0.1, vImage_Flags(kvImageNoFlags))
        vImageHistogramSpecification_PlanarF(&buffer, &buffer2, nil, optimized_histogram, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
        //var buffer3 = buffer2
        //vImageEqualization_PlanarF(&buffer2, &buffer3, nil, histogramcount, lowerPixelLimt, upperPixelLimit, vImage_Flags(kvImageNoFlags))
        //vImageContrastStretch_PlanarF(&buffer2, &buffer3, nil, histogramcount, lowerPixelLimt, upperPixelLimit, vImage_Flags(kvImageNoFlags))
        let gamma: Float = 1.0
        let exponential:[Float] = [1, 0, 0]
    
        var buffer3 = buffer
        vImagePiecewiseGamma_PlanarF(&buffer2, &buffer3, exponential, gamma, [1,0], 0, vImage_Flags(kvImageNoFlags))
        var gammahistogram = [vImagePixelCount](repeating: 0, count: histogramcount)
        let gammahistogramPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: gammahistogram)
        gammahistogram.withUnsafeMutableBufferPointer() { Ptr in
                            let error =
                                vImageHistogramCalculation_PlanarF(&buffer3, gammahistogramPtr, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
                                guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
        print(gammahistogram)
        vImageHistogramSpecification_PlanarF(&buffer, &buffer2, nil, gammahistogram, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
        
        /*for i in 0 ..< kernel2D.count{
            kernel2D[i] = kernel2D[i] / kernel
        }*/
        let kernelwidth = 9
        let kernelheight = 9
        var A : Float = 1.0
        var simgaX: Float = 0.75
        var sigmaY: Float = 0.75
        
        var kernelArray = kArray(width: kernelwidth, height: kernelheight, sigmaX: simgaX, sigmaY: sigmaY, A: A)
        
        print(kernelArray, " " , kernelArray.max())

        vImageConvolve_PlanarF(&buffer, &buffer3, nil, 0, 0, &kernelArray, UInt32(kernelwidth), UInt32(kernelheight), 0, vImage_Flags(kvImageEdgeExtend))
        var histogramBin3 = [vImagePixelCount](repeating: 0, count: histogramcount)
        let histogramBinPtr3 = UnsafeMutablePointer<vImagePixelCount>(mutating: histogramBin3)
        histogramBin3.withUnsafeMutableBufferPointer() { Ptr in
                            let error =
                                vImageHistogramCalculation_PlanarF(&buffer, histogramBinPtr3, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
                                guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
        print(histogramBin3)
        vImageHistogramSpecification_PlanarF(&buffer, &buffer2, nil, histogramBin3, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
    
        var BlurredPixelData = (buffer3.data.toArray(to: Float.self, capacity: Int(buffer3.width*buffer3.height)))
        var OriginalPixelData = (buffer.data.toArray(to: Float.self, capacity: Int(buffer.width*buffer.height)))
        var bendvalue = bendValue(AdjustedData: BlurredPixelData, lowerPixelLimit: lowerPixelLimit) //return bendvalue as .0, and averagepixeldata as .1
        var ddpPixelData = ddpProcessed(OriginalPixelData: OriginalPixelData, BlurredPixeldata: BlurredPixelData, Bendvalue: bendvalue.0, AveragePixel: bendvalue.1, cutOff: cutoff, MinPixel: lowerPixelLimit)
        let ddpScaled = ddpScaled(ddpPixelData: ddpPixelData, MinPixel: lowerPixelLimit)
        
        let DDPwithScale = returningCGImage(data: ddpScaled, buffer: buffer3)
        let originalImage = (try? buffer.createCGImage(format: format))!
        let DDPwithoutScale = returningCGImage(data: ddpPixelData, buffer: buffer3)
        
        print("called")
        
        return(histogramBin, originalImage, DDPwithoutScale, DDPwithScale)
    }

    var body: some View {
        let modified = display()

                    TabView{
                        HStack{
                            Image(decorative: modified.1, scale: 1.0)
                                .resizable()
                                .scaledToFit()
                        }
                        HStack{
                            Image(decorative: modified.2, scale: 1.0)
                                .resizable()
                                .scaledToFit()

                        }
                        HStack{
                            Image(decorative: modified.3, scale: 1.0)
                                .resizable()
                                .scaledToFit()
                        }
                }
}
}
