//
//  ServerOnboardingView.swift
//  MAGE
//
//  Created by James McDougall on 6/25/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct ServerOnboardingView: View {
    var body: some View {
        VStack(spacing: 15) {
            VStack {
                Text("Create a Server")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("MAGE uses different individual servers for data protection between our users. This can be compared to a multi-server application such as Discord. The only difference is that you provide your own server. This allows you the user, to set your own security protocols. This puts you in control of your data and how it is used on our platform.")
                    .multilineTextAlignment(.center)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: UIScreen.screenWidth - 40, height: 50)
                    .padding(.horizontal)
                HStack {
                    Image(systemName: "globe.americas.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading) {
                        Text("Mage Server URL")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("MAGE Server URL")
                            .foregroundStyle(.gray)
                            .font(.body)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .frame(width: UIScreen.screenWidth - 40, height: 50)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: UIScreen.screenWidth - 40, height: 2)
                    .padding(.horizontal)
            }
            .padding(.vertical)

        }
    }
}

#Preview {
    ServerOnboardingView()
}
