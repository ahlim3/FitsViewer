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

///extension required for reading FITS file, See seperate instruction for extension addition
extension UTType
    {
      static let fitDocument = UTType(exportedAs: "com.jtIIT.fit")
    }

struct ContentView: View
    {
        @ObservedObject var plotDataModel = PlotDataClass(fromLine: true)
        @ObservedObject private var dataCalculator = CalculatePlotData()
        @EnvironmentObject var fitsHandler: FITSHandler
        @State var called = 0
        @State var isImporting: Bool = false
        @State var isExporting: Bool = false
        @State var rawImage: Image?
        @State var processedImage: Image?
        @State var xpoints = [Double]()
        @State var ypoints = [Double]()
        @State var isEditing = false
        @State var isEditing2 = false
        @State var selectedTab = 0
        // Storing URL in contentView
        @State var dataURL = URL(string: "")
        @State var isHidden = true
        @State var allHidden = false
        @State var target : Image?
        @State var Storedname = "ProcessedImage"


    // Displaying the FITS File for first time
        func display(Data: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat))
        {
            let ImageInfo = fitsHandler.returnInfo(ThreeData: Data)
            rawImage = Image(ImageInfo.1, scale: 2.0, label: Text("Raw"))
            processedImage = Image(ImageInfo.2, scale: 2.0, label: Text("Processed Image"))
            calcHistogram()
            isHidden = false
        }
        
    // Exceuting the function for histogram
        func calcHistogram()
        {
            dataCalculator.plotDataModel = self.plotDataModel
            dataCalculator.plotHistogram(xpoint: fitsHandler.xpoints, ypoint: fitsHandler.ypoints)
        }

    // reading the FITS file from the URL destination
    // This is required due to mutation of original buffer.
        func clear(dataURL : URL)
        {
            let read_data = try! FitsFile.read(contentsOf: dataURL)
            let prime = read_data?.prime
            prime?.v_complete(onError:
                                {_ in
                                    print("CGImage creation error")
                                }
                              )
                                {
                                    result in
                                    fitsHandler.threeData = result
                                    let _ = self.display(Data: fitsHandler.threeData!)
                                }
        }


        var body: some View
        {
            /// Tabview
            TabView(selection: $selectedTab)
            {
                rawImage?
                    .resizable()
                    .scaledToFit()
                    .onTapGesture
                    {
                        self.selectedTab = 1
                    }
                    .tabItem
                    {
                        Image(systemName: "star")
                        Text("Raw Image")
                    }
                    .tag(0)
                processedImage?
                    .resizable()
                    .scaledToFit()
                    .onTapGesture
                    {
                        self.selectedTab = 2
                    }
                    .tabItem
                    {
                        Image(systemName: "star")
                        Text("Processed Image")
                    }
                    .tag(1)
                CorePlot(dataForPlot: $plotDataModel.plotData, changingPlotParameters: $plotDataModel.changingPlotParameters)
                    .setPlotPadding(left: 10)
                    .setPlotPadding(right: 10)
                    .setPlotPadding(top: 10)
                    .setPlotPadding(bottom: 10)
                    .padding()
                    .onTapGesture
                    {
                        self.selectedTab = 3
                    }
                    .tabItem
                    {
                        Image(systemName: "star.fill")
                        Text("Histogram")
                    }
                    .tag(2)

            }
            /// Toggle Key for controller to display image bigger.
            Toggle("Hide Controller", isOn: $allHidden)
            if !allHidden
            {
                HStack
                {
                    HStack
                    {
                        ///Maximum Brightness Control from 0.5 to 1.0
                        Text("Max B")
                        Slider(
                                value: self.$fitsHandler.MaxPixel_F,
                                in: 0.5...1.0,
                                onEditingChanged:
                                    {
                                        editing in
                                        isEditing = editing
                                    }
                                )
                        .frame(width: 300, alignment: .center)
                        Text("\(fitsHandler.MaxPixel_F)")
                            .foregroundColor(isEditing ? .red : .blue)
                            .padding(CGFloat(20))
                        
                        /// Minimum Brightness Control from 0.0 to 0.25
                        Text("Min B")
                        Slider(
                            value: self.$fitsHandler.MinPixel_F,
                            in: 0...0.25,
                            onEditingChanged:
                                {
                                    editing in
                                    isEditing2 = editing
                                }
                            )
                        .frame(width: 300, alignment: .center)
                        Text("\(fitsHandler.MinPixel_F)")
                            .foregroundColor(isEditing2 ? .red : .blue)
                            .padding(CGFloat(20))
                        
                        Button("Load", action:
                                {
                                    isImporting = false
                                    //fix broken picker sheet
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
                                    {
                                        isImporting = true
                                    }
                                }
                               )
                                .fileImporter(
                                    isPresented: $isImporting,
                                    allowedContentTypes: [.fitDocument],
                                    allowsMultipleSelection: false
                                ) {
                                    result in
                                    do
                                        {
                                            guard let selectedFile: URL = try result.get().first else
                                            {
                                                return
                                            }
                                            print("Selected file is", selectedFile)
                                            print(type(of: selectedFile))
                                            dataURL = selectedFile
                                            //trying to get access to url contents
                                            if (CFURLStartAccessingSecurityScopedResource(selectedFile as CFURL))
                                            {
                                                guard let read_data = try! FitsFile.read(contentsOf: selectedFile) else
                                                {
                                                    return
                                                }
                                                let prime = read_data.prime
                                                prime.v_complete(onError:
                                                                    {
                                                                        _ in
                                                                        print("CGImage creation error")
                                                                    })
                                                {
                                                    result in
                                                    fitsHandler.threeData = result
                                                    let _ = self.display(Data: fitsHandler.threeData!)
                                                }
                                            //done accessing the url
                                                CFURLStopAccessingSecurityScopedResource(selectedFile as CFURL)
                                            }
                                            else
                                            {
                                                print("Permission error!")
                                            }
                                    }
                                    catch
                                    {
                                        // Handle failure.
                                        print(error.localizedDescription)
                                    }
                                }
                        // Hiding the Implement Change button before excuting application for first time. If nor appplication error occur.
                        if !isHidden
                        {
                            Button("Implement Change", action:
                                    {
                                        self.clear(dataURL: dataURL!)
                                        
                                    }
                                )
                        }
                    }
                }
                .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/,
                       idealWidth: 100,
                       maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/,
                       minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/,
                       idealHeight: 25,
                       maxHeight: 25,
                       alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            }
        }
    }

extension UnsafeMutableRawPointer
    {
        func toArray<T>(to type: T.Type, capacity count: Int) -> [T]
        {
            let pointer = bindMemory(to: type, capacity: count)
            return Array(UnsafeBufferPointer(start: pointer, count: count))
        }
    }

extension Data
    {

        init<T>(fromArray values: [T])
        {
            self = values.withUnsafeBytes { Data($0) }
        }

        func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral
        {
            var array = Array<T>(repeating: 0, count: self.count/MemoryLayout<T>.stride)
            _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
            return array
        }
    }
