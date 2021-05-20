//
//  CalculatePlotData.swift
//  SwiftUICorePlotExample
//
//  Created by Jeff Terry on 12/22/20.
//

import Foundation
import SwiftUI
import CorePlot

class CalculatePlotData: ObservableObject {
    
    var plotDataModel: PlotDataClass? = nil
    
    func plotHistogram(xpoint:[Double], ypoint:[Double]){
        //set the Plot Parameters
        plotDataModel!.changingPlotParameters.yMax = 20.0
        plotDataModel!.changingPlotParameters.yMin = -1.0
        plotDataModel!.changingPlotParameters.xMax = 1.1
        plotDataModel!.changingPlotParameters.xMin = -0.1
        plotDataModel!.changingPlotParameters.xLabel = "Brightness"
        plotDataModel!.changingPlotParameters.yLabel = "Log(count)"
        plotDataModel!.changingPlotParameters.lineColor = .red()
        plotDataModel!.changingPlotParameters.title = "Histogram"
        
        plotDataModel!.zeroData()
        var plotData :[plotDataType] =  []
        for i in 0 ..< xpoint.count{
            let dataPoint: plotDataType = [.X: xpoint[i], .Y: ypoint[i]]
            plotData.append(contentsOf: [dataPoint])
        }
        plotDataModel!.appendData(dataPoint: plotData)
        return
    }
    
}



