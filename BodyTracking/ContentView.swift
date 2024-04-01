//
//  ContentView.swift
//  Virtual Avatar
//
//  Created by Maratov Khamidullojon on 3/13/24.
//

import SwiftUI

struct ContentView : View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all) //removing everything
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

