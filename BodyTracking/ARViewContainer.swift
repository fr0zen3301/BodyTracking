//
//  ARViewContainer.swift
//  Virtual Avatar
//
//  Created by Maratov Khamidullojon on 3/13/24.
//

import SwiftUI
import ARKit
import RealityKit


private var bodySkeleton: BodySkeleton?
private let bodySkeletonAnchor = AnchorEntity()

struct ARViewContainer: UIViewRepresentable {
    typealias UIViewType = ARView
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: true)
        
        arView.setUpForBodyTracking()
        arView.scene.addAnchor(bodySkeletonAnchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
    }
}

extension ARView: ARSessionDelegate {
    func setUpForBodyTracking() {
        let configuration = ARBodyTrackingConfiguration()
        self.session.run(configuration)
        
        self.session.delegate = self
    }
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
                if let skeleton = bodySkeleton {
                    // bodySkeleton already exist, update all joints and bones
                    skeleton.update(with: bodyAnchor)
                } else {
                    // body skeleton doesn't exist yet. This means a body has been detected for the first time
                    // create a bodySkeleton entity and add it to the bodySkeletonAnchor
                    bodySkeleton = BodySkeleton(for: bodyAnchor)
                    bodySkeletonAnchor.addChild(bodySkeleton!)
                }
            }
        }
    }
}

