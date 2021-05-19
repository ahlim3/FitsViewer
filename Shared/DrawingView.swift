//
//  DrawingView.swift
//  FitsViewer
//
//  Created by anthony lim on 5/18/21.
//

import Foundation
import SwiftUI

struct drawingView: View {
    
    @Binding var redLayer : [(xPoint: Double, yPoint: Double)]
    @Binding var blueLayer : [(xPoint: Double, yPoint: Double)]
    
    var body: some View {
    
        
        ZStack{
        
            drawIntegral(drawingPoints: redLayer )
                .fill(Color.black)
            drawIntegral(drawingPoints: blueLayer )
                .stroke(Color.black)
        }
        .background(Color.white)
        .aspectRatio(1, contentMode: .fill)
        
    }
}

struct DrawingView_Previews: PreviewProvider {
    
    @State static var redLayer : [(xPoint: Double, yPoint: Double)] = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
    @State static var blueLayer : [(xPoint: Double, yPoint: Double)] = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
    
    static var previews: some View {
       
        
        drawingView(redLayer: $redLayer, blueLayer: $blueLayer)
            .aspectRatio(1, contentMode: .fill)
           
    }
}



struct drawIntegral: Shape {
    
   
    let smoothness : CGFloat = 1.0
    var drawingPoints: [(xPoint: Double, yPoint: Double)]  ///Array of tuples
    
    func path(in rect: CGRect) -> Path {
        
               
        // draw from the center of our rectangle
        let center = CGPoint(x: 0.0, y: 0.0)
        let scale = rect.width
        

        // Create the Path for the display
        
        var path = Path()
        path.move(to: center)
        
        for item in drawingPoints {
            
            //path.addLine(to: CGPoint(x: item.xPoint, y: item.yPoint))
            path.addRect(CGRect(x: item.xPoint*Double(scale), y: item.yPoint*Double(scale), width: 1.0 , height: 1.0))
            
        }


        return (path)
    }
}
