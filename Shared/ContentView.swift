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
import UniformTypeIdentifiers
import CorePlot

typealias plotDataType = [CPTScatterPlotField : Double]

extension UTType {
  static let fitDocument = UTType(
    exportedAs: "com.jtIIT.fit")
}

struct ContentView: View {
    @ObservedObject var plotDataModel = PlotDataClass(fromLine: true)
    @ObservedObject private var dataCalculator = CalculatePlotData()
    @EnvironmentObject var fitsHandler: FITSHandler
    @State var called = 0
    @State var isImporting: Bool = false
    @State var isExporting: Bool = false
    @State var rawImage: Image?
    @State var processedImage: Image?
    @State var convolvedIamge: Image?
    @State var Val: Bool = false
    @State var displayImage: Image?
    @State var ImageString = "Process Image"
    @State var lowerPixelLimit = Pixel_F(0.0)
    @State var threeData: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)?
    @State var xpoints = [Double]()
    @State var ypoints = [Double]()
    func display(Data: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)) {
        let ImageInfo = returnInfo(ThreeData: threeData!)
        rawImage = Image(ImageInfo.1, scale: 2.0, label: Text("Raw"))
        processedImage = Image(ImageInfo.2, scale: 2.0, label: Text("Processed Image"))
        convolvedIamge = Image(ImageInfo.3, scale: 2.0, label: Text("Convolved Image"))
        
    }

    func displaySwitch(switchVal: Bool) -> Bool {
        var Val = switchVal
        if Val == false
        {
            ImageString = "Process Image"
            displayImage = processedImage
            Val = true
        }
        if Val == true
        {
            ImageString = "Back to Raw Image"
            displayImage = rawImage
            Val = false
        }
        return Val
    }
    


func returnInfo(ThreeData : ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)) -> ([vImagePixelCount], CGImage, CGImage, CGImage){
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
    let histogramBin = fitsHandler.histogram(dataMaxPixel: Pixel_F(data.max()!), dataMinPixel: Pixel_F(data.min()!), buffer: buffer, histogramcount: histogramcount)
    let histMax = Double(histogramBin.max()!)
    var xpointsinside = [Double]()
    var ypointsinside = [Double]()
    for i in 0 ..< histogramcount{
        xpointsinside.append(Double(i) / Double(histogramcount))
        ypointsinside.append(Double(histogramBin[i])/histMax)
    }
    xpoints = xpointsinside
    ypoints = ypointsinside
    //Return three data, Histogram(0), Maximum Pixel Value(1), Minimum Pixel Value(2), Cutoff?(3) = 0 no, 1 yes
    let OptimizedHistogramContents = fitsHandler.OptValue(histogram_in: histogramBin, histogramcount: histogramcount)
    lowerPixelLimit = OptimizedHistogramContents.1
    let upperPixelLimit = OptimizedHistogramContents.0
    let cutoff = OptimizedHistogramContents.2
    let histogramOpt = fitsHandler.histogram(dataMaxPixel: upperPixelLimit, dataMinPixel: lowerPixelLimit, buffer: buffer, histogramcount: histogramcount)
    print(histogramOpt)
    var OriginalPixelData = (buffer.data.toArray(to: Float.self, capacity: Int(buffer.width*buffer.height)))
    OriginalPixelData = fitsHandler.forcingMeanData(PixelData: OriginalPixelData, MinimumLimit: lowerPixelLimit)
    let forcedOriginalData = fitsHandler.returningCGImage(data: OriginalPixelData, width: width, height: height, rowBytes: rowBytes)
    var forcedbuffer = try! vImage_Buffer(cgImage: forcedOriginalData, format: format)
    var buffer3 = buffer
    var kernelwidth = 9
    var kernelheight = 9
    var A : Float = 1.0
    var simgaX: Float = 0.75
    var sigmaY: Float = 0.75
    
    var kernelArray = fitsHandler.kArray(width: kernelwidth, height: kernelheight, sigmaX: simgaX, sigmaY: sigmaY, A: A)
    vImageConvolve_PlanarF(&forcedbuffer, &buffer3, nil, 0, 0, &kernelArray, UInt32(kernelwidth), UInt32(kernelheight), 0, vImage_Flags(kvImageEdgeExtend))

    let BlurredPixelData = (buffer3.data.toArray(to: Float.self, capacity: Int(buffer3.width*buffer3.height)))
    OriginalPixelData = (buffer.data.toArray(to: Float.self, capacity: Int(buffer.width*buffer.height)))
    //Bendvalue of DDP
    
    let bendvalue = fitsHandler.bendValue(AdjustedData: BlurredPixelData, lowerPixelLimit: lowerPixelLimit) //return bendvalue as .0, and averagepixeldata as .1

    let ddpPixelData = fitsHandler.ddpProcessed(OriginalPixelData: OriginalPixelData, BlurredPixeldata: BlurredPixelData, Bendvalue: bendvalue.0, AveragePixel: bendvalue.1, cutOff: cutoff, MinPixel: lowerPixelLimit)
    let DDPScaled = fitsHandler.ddpScaled(ddpPixelData: ddpPixelData, MinPixel: lowerPixelLimit)
    let ConvolveImage = fitsHandler.returningCGImage(data: BlurredPixelData, width: width, height: height, rowBytes: rowBytes)
    let DDPwithScale = fitsHandler.returningCGImage(data: DDPScaled, width: width, height: height, rowBytes: rowBytes)
    let originalImage = (try? buffer.createCGImage(format: format))!
    calcHistogram()
    print("called")
    return(histogramBin, originalImage,  DDPwithScale, ConvolveImage)
    }
    func calcHistogram(){
        dataCalculator.plotDataModel = self.plotDataModel
        dataCalculator.plotHistogram(xpoint: xpoints, ypoint: ypoints)
    }


    var body: some View {
        TabView{
        HStack{
            processedImage?.resizable().scaledToFit()
        }
        HStack{
            CorePlot(dataForPlot: $plotDataModel.plotData, changingPlotParameters: $plotDataModel.changingPlotParameters)
                .setPlotPadding(left: 10)
                .setPlotPadding(right: 10)
                .setPlotPadding(top: 10)
                .setPlotPadding(bottom: 10)
                .padding()
        }
        }
            VStack{
                Button("Load", action: {
                    isImporting = false
                    //fix broken picker sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isImporting = true
                    }
                })
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [.fitDocument],
                    allowsMultipleSelection: false
                ) { result in
                    do {
                        guard let selectedFile: URL = try result.get().first else { return }
                        
                        print("Selected file is", selectedFile)
                        
                        //trying to get access to url contents
                        if (CFURLStartAccessingSecurityScopedResource(selectedFile as CFURL)) {
                                                
                            
                            guard let read_data = try! FitsFile.read(contentsOf: selectedFile) else { return }
                            let prime = read_data.prime
                            print(prime)
                            prime.v_complete(onError: {_ in
                                print("CGImage creation error")
                            }) { result in
                                threeData = result
                                let _ = self.display(Data: threeData!)
                            }
                            //done accessing the url
                            CFURLStopAccessingSecurityScopedResource(selectedFile as CFURL)
                        }
                        else {
                            print("Permission error!")
                        }
                    } catch {
                        // Handle failure.
                        print(error.localizedDescription)
                    }
                }

        }
    }



    }


    

    


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



