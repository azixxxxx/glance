import SwiftUI

struct ActiveAppWidget: View {
    @StateObject private var viewModel = ActiveAppViewModel()

    var body: some View {
        Text(viewModel.appName)
            .font(.system(size: 13, weight: .medium))
            .lineLimit(1)
            .shadow(color: .foregroundShadow, radius: 3)
            .experimentalConfiguration(horizontalPadding: 10)
            .frame(maxHeight: .infinity)
            .animation(.smooth(duration: 0.2), value: viewModel.appName)
    }
}

struct ActiveAppWidget_Previews: PreviewProvider {
    static var previews: some View {
        ActiveAppWidget()
            .frame(width: 200, height: 100)
            .background(Color.black)
    }
}
