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

struct DestinationPageView: View {
    let path = "file:///Users/anthonylim/Downloads/M42-ID10211-OC141775-GR1840-LUM.fit"
    var body: some View {
        let modified = display(Path: path)
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
    }
}
}
struct DestinationPageView1: View {
     let path1 = "file:///Users/anthonylim/Downloads/2020-12-03_19;56;17.fits"
    var body: some View {
        let modified = display(Path: path1)
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
    }
}
}
struct DestinationPageView2: View {
    let path2 = "file:///Users/anthonylim/Downloads/n5194.fits"
    var body: some View {
        let modified = display(Path: path2)
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
    }
}
}
struct DestinationPageView3: View {
    let path10 = "file:///Users/anthonylim/Downloads/globular.fits"
    var body: some View {
        let modified = display(Path: path10)
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
    }
}
}
struct DestinationPageView4: View {
     let path4 = "file:///Users/anthonylim/Downloads/UGC3697-104341-LUM.fit"
    var body: some View {
        let modified = display(Path: path4)
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
    }
}
}
struct DestinationPageView5: View {
     let path5 = "file:///Users/anthonylim/Downloads/BGO-2-KIC8462852-ID06656-OC126425-GR7646-SG.fit"
    var body: some View {
        let modified = display(Path: path5)
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
    }
}
}
struct DestinationPageView6: View {
     let path6 = "file:///Users/anthonylim/Downloads/moon_BIN_1x1_0.0010s_002.fits"
    var body: some View {
        let modified = display(Path: path6)
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
    }
}
}
struct DestinationPageView7: View {
     let path7 = "file:///Users/anthonylim/Downloads/NGC4438-104275-LUM.fit"
    var body: some View {
        let modified = display(Path: path7)
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
    }
}
}
struct DestinationPageView8: View {
     let path8 = "file:///Users/anthonylim/Downloads/M66-ID10979-OC144423-GR4135-LUM2.fit"
     // Work
    var body: some View {
        let modified = display(Path: path8)
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
    }
}
}
struct DestinationPageView9: View {
     let path9 = "file:///Users/anthonylim/Downloads/NGC6960-ID14567-OC148925-GR8123-LUM.fit"
    var body: some View {
        let modified = display(Path: path9)
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
    }
}
}
struct ContentView: View {
    var body: some View {
                NavigationView {
                    List {
                        NavigationLink(
                            destination: DestinationPageView()
                        ) {
                            Text("Image 1, Edge Fixed")
                        }
                        NavigationLink(
                            destination: DestinationPageView1()
                        ) {
                            Text("Image 2, Edge Fixed")
                        }
                        NavigationLink(
                            destination: DestinationPageView2()
                        ) {
                            Text("Image 3 Fast")
                        }
                        NavigationLink(
                            destination: DestinationPageView3()
                        ) {
                            Text("Image 4 Fast, Representable")
                        }
                        NavigationLink(
                            destination: DestinationPageView4()
                        ) {
                            Text("Image 5, RGBImage as Mono")
                        }
                        NavigationLink(
                            destination: DestinationPageView5()
                        ) {
                            Text("Image 6 Edge Fixed")
                        }
                        NavigationLink(
                            destination: DestinationPageView6()
                        ) {
                            Text("Image 7 Moon, Representable, Slow")
                        }
                        NavigationLink(
                            destination: DestinationPageView7()
                        ) {
                            Text("Image 8 Edge Fixed")
                        }
                        NavigationLink(
                            destination: DestinationPageView8()
                        ) {
                            Text("Image 9 Edge Problem, Edge is too big")
                        }
                        NavigationLink(
                            destination: DestinationPageView9()
                        ) {
                            Text("Image 10 Edge Fixed")
                        }
                        
                    }
                    Text("Select a Image page from the links.")
                }
            }
        }

