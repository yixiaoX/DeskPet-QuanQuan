//
//  PetAvatarView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import SwiftUI
import SDWebImageSwiftUI

struct PetAvatarView: View {
    var imageName: String
    
    var body: some View {
        AnimatedImage(name: imageName)
            .resizable()
            .indicator(.activity)
            .transition(.fade(duration: 0.5))
            .aspectRatio(contentMode: .fit)
            .frame(width: 200, height: 200)
    }
}
