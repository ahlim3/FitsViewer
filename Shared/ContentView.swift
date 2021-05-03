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
    let path11 = "file:///Users/anthonylim/Downloads/C2019Y4-ID10934-OC144374-GR4095-LUM2.fit"
    let histogramcount = 1024
    @State var called = 0
    
    func read() -> ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat){
        var threeData: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)?
        var path = URL(string: path6)!
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
        
        print(optimizedHist)
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
        vImageHistogramSpecification_PlanarF(&buffer, &buffer2, nil, histogramOpt, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
        var buffer3 = buffer
        let kernelwidth = 9
        let kernelheight = 9
        var A : Float = 1.0
        var simgaX: Float = 0.20
        var sigmaY: Float = 0.20
        
        var kernelArray = kArray(width: kernelwidth, height: kernelheight, sigmaX: simgaX, sigmaY: sigmaY, A: A)
        
        print(kernelArray, " " , kernelArray.max())


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
