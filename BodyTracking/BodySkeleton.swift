//
//  BodySkeleton.swift
//  Virtual Avatar
//
//  Created by Maratov Khamidullojon on 3/13/24.
//

import Foundation
import RealityKit
import ARKit

// Creating entities

class BodySkeleton: Entity {
    // Create joints and bones to keep tracking joints and bones in our scene
    // We update their properties any time when updated body anchor
    var joints: [String: Entity] = [:]
    var bones: [String: Entity] = [:]
    
    required init(for bodyAnchor: ARBodyAnchor) {
        super.init()
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            var jointRadius: Float = 0.05
            var jointColor: UIColor = .green
            
            // Set color and size based on a specific joint name
            // NOTE: Green joints are actively tracked by ARKit, however white ones are not. They just follow the motion of the closest green parent
            
            switch jointName {
            case "neck_1_joint", "neck_2_joint", "neck_3_joint", "neck_4_joint", "head_joint",
                "left_shoulder_1_joint", "right_shoulder_1_joint":
                jointRadius *= 0.5
            
            case "jaw_joint", "chin_joint", "left_eye_joint", "left_eyeLowerLid_joint", "left_eyeUpperLid_joint", "left_eyeball_joint", "nose_joint", "right_eye_joint", "right_eyeLowerLid_joint", "right_eyeUpperLid_joint", "right_eyeball_joint":
                jointRadius *= 0.2
                jointColor = .white
            case _ where jointName.hasPrefix("spine_"):
                jointRadius *= 0.75
            case "left_hand_joint", "right_hand_join":
                jointRadius *= 1
                jointColor = .green
            case _ where jointName.hasPrefix("left_hand") || jointName.hasPrefix("right_hand"):
                jointRadius *= 0.25
                jointColor = .white
            case _ where jointName.hasPrefix("left_toes") || jointName.hasPrefix("right_toes"):
                jointRadius *= 0.5
                jointColor = .white
            default:
                jointRadius = 0.05
                jointColor = .green
                
            }
            
            // Creating for the joint, add to joints directory, and add it to the parent entity(bodySkeleton)
            let jointEntity = createJoint(radius: jointRadius, color: jointColor)
            joints[jointName] = jointEntity
            self.addChild(jointEntity)
        }
        
        for bone in Bones.allCases {
            guard let SkeletonBone = createSkeletoneBone(bone: bone, bodyAnchor: bodyAnchor)
            else { continue }
            
            // create an entity for the bone, add to bones directory, and add it to the parent entity(bodySkeleton)
            let boneEntity = createBoneEntity(for: SkeletonBone)
            bones[bone.name] = boneEntity
            self.addChild(boneEntity)
        }
    }
    
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
    
    func update(with bodyAnchor: ARBodyAnchor) {
        let rootPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            if let jointEntity = joints[jointName],
               let jointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName)) {
                
                let jointEntityOffsetFromRoot = simd_make_float3(jointEntityTransform.columns.3) // relative to root
                jointEntity.position = jointEntityOffsetFromRoot + rootPosition // relative to world reference frame
                jointEntity.orientation = Transform(matrix: jointEntityTransform).rotation
            }
        }
        
        for bone in Bones.allCases {
            let boneName = bone.name
            
            guard let entity = bones[boneName],
                  let skeletonBone = createSkeletoneBone(bone: bone, bodyAnchor: bodyAnchor)
            else { continue }
            
            entity.position = skeletonBone.centerPosition
            entity.look(at: skeletonBone.toJoint.position, from: skeletonBone.centerPosition, relativeTo: nil) // set orientation for bone
        }
    }
    
    // Helper method to construct joint and body entities
    private func createJoint(radius: Float, color: UIColor = .white) -> Entity {
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: color, roughness: 0.8, isMetallic: false) // method creates a sphere for every single joint in our skeleton
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        return entity
    }
    
    // method to construct a skeletone bone
    private func createSkeletoneBone(bone: Bones, bodyAnchor: ARBodyAnchor) -> SkeletonBone? {
        guard let fromJointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: bone.jointFromName)),
              let toJointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: bone.jointToName))
        else { return nil }
        
        let rootPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        
        let jointFromEntityOffsetFromRoot = simd_make_float3(fromJointEntityTransform.columns.3) // relative to root
        let jointFromEntityPosition = jointFromEntityOffsetFromRoot + rootPosition // relative to world reference frame
        let jointToEntityOffsetFromRoot = simd_make_float3(toJointEntityTransform.columns.3) // relative to root
        let jointToEntityPosition = jointToEntityOffsetFromRoot + rootPosition // relative to world
        
        let fromJoint = SkeletonJoint(name: bone.jointFromName, position: jointFromEntityPosition)
        let toJoint = SkeletonJoint(name: bone.jointToName, position: jointToEntityPosition)
        return SkeletonBone(fromJoint: fromJoint, toJoint: toJoint)
    }
    
    private func createBoneEntity(for skeletoneBone: SkeletonBone, diameter: Float = 0.04, color: UIColor = .white) -> Entity {
        let mesh = MeshResource.generateBox(size: [diameter, diameter, skeletoneBone.length], cornerRadius: diameter/2) // using box to creating a cylinder that represents a bone
        let material = SimpleMaterial(color: color, roughness: 0.5, isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        return entity
    }
}
