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

struct ContentView: View {
    
    @EnvironmentObject var FITSHandler: FITSDatahandler
    @State var called = 0
    @State var isImporting: Bool = false
    @State var rawImage: Image?
    @State var processedImage: Image?
    @State var threeData: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)?
    func display() {
        let ImageInfo = FITSHandler.returnInfo(ThreeData: threeData!)
        rawImage = Image(ImageInfo.1, scale: 1.0, label: Text("Raw"))
        processedImage = Image(ImageInfo.2, scale: 1.0, label: Text("Processed Image"))
        
    }


    var body: some View {
        VStack {
            ScrollView([.horizontal, .vertical]){
               /* HSplitView{
                    Image(decorative: displayRaw().0, scale: 1.0)
                    //.resizable()
                    //.scaledToFit()
                    .padding()
                }*/
                rawImage
                
                
            }
            //.padding()
            ScrollView([.horizontal, .vertical]){
                /*HSplitView{
                    Image(decorative: display().0, scale: 1.0)
                    //.resizable()
                    //.scaledToFit()
                    .padding()
                }*/
                processedImage
            }
            //.padding()
            VStack{
                //Spacer()
                Divider()
                
                Button("Load", action: {
                    isImporting = false
                    
                    //fix broken picker sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isImporting = true
                    }
                })
                    .padding()

                /*Button("Invert", action: {histogram().self})
                Button("Zero", action: {histogram().self})
                Button("Reset", action: {histogram().self})*/
            }
        }
       // .padding()
        .fileImporter(
            isPresented: $isImporting,
            //allowedContentTypes: [UTType.plainText],
            allowedContentTypes: [.fitDocument],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile: URL = try result.get().first else { return }
                
                print("Selected file is", selectedFile)
                
                //trying to get access to url contents
                if (CFURLStartAccessingSecurityScopedResource(selectedFile as CFURL)) {
                    
                    //guard let message = String(data: try Data(contentsOf: selectedFile), encoding: .utf8) else { return }
                    
                    
                    
                    
                    guard let read_data = try! FitsFile.read(contentsOf: selectedFile) else { return }
                    let prime = read_data.prime
                    
                    prime.v_complete(onError: {_ in
                        print("CGImage creation error")
                    }) { result in
                        
                        threeData = result
                        let _ = self.display()
                       
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



