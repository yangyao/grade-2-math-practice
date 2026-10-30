import SwiftUI

struct PracticeBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.91, green: 0.94, blue: 0.98)
                Ellipse().fill(Color(red: 0.69, green: 0.74, blue: 0.98).opacity(0.75))
                    .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.9)
                    .blur(radius: 95).offset(x: -geometry.size.width * 0.35, y: -geometry.size.height * 0.35)
                Ellipse().fill(Color(red: 0.57, green: 0.86, blue: 0.85).opacity(0.55))
                    .frame(width: geometry.size.width * 0.75, height: geometry.size.height * 0.85)
                    .blur(radius: 90).offset(x: geometry.size.width * 0.4, y: geometry.size.height * 0.15)
                Circle().fill(Color(red: 1, green: 0.83, blue: 0.71).opacity(0.4))
                    .frame(width: 440, height: 440).blur(radius: 100)
                    .offset(x: -geometry.size.width * 0.1, y: geometry.size.height * 0.45)
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}

private struct PracticeGlass: ViewModifier {
    var radius: CGFloat
    var tint: Color
    var interactive: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ViewBuilder func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color.white.opacity(0.96), in: RoundedRectangle(cornerRadius: radius))
        } else if #available(iOS 26.0, macOS 26.0, *) {
            content.glassEffect(.clear.tint(tint).interactive(interactive), in: RoundedRectangle(cornerRadius: radius))
        } else {
            content.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
                .overlay(RoundedRectangle(cornerRadius: radius).stroke(.white.opacity(0.75), lineWidth: 1))
        }
    }
}

extension View {
    func practiceGlass(radius: CGFloat = 18, tint: Color = .white.opacity(0.25), interactive: Bool = false) -> some View {
        modifier(PracticeGlass(radius: radius, tint: tint, interactive: interactive))
    }
    @ViewBuilder func groupedGlass() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) { GlassEffectContainer(spacing: 4) { self } }
        else { self }
    }
}

struct ArithmeticMark: View {
    var body: some View {
        Group {
            #if os(macOS)
            if let url = Bundle.main.url(forResource: "ArithmeticGlass", withExtension: "icns"), let image = NSImage(contentsOf: url) {
                Image(nsImage: image).resizable().interpolation(.high).frame(width: 58, height: 58)
            } else {
                Image(systemName: "plus.forwardslash.minus").font(.system(size: 30, weight: .semibold)).frame(width: 58, height: 58)
            }
            #else
            Image("AppIconPreview").resizable().scaledToFit().frame(width: 58, height: 58)
            #endif
        }.accessibilityHidden(true)
    }
}

struct GlassKeyStyle: ButtonStyle {
    var accent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0.15), Color.cyan.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .practiceGlass(radius: 14, tint: accent ? .indigo.opacity(0.08) : .white.opacity(0.08), interactive: true)
            .overlay {
                RoundedRectangle(cornerRadius: 14).strokeBorder(LinearGradient(stops: [.init(color: .white, location: 0), .init(color: .white.opacity(0.15), location: 0.48), .init(color: .white.opacity(0.75), location: 1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.3)
                    .allowsHitTesting(false)
            }
            .shadow(color: Color(red: 0.35, green: 0.45, blue: 0.65).opacity(configuration.isPressed ? 0.02 : 0.15), radius: 5, x: 0, y: configuration.isPressed ? 1 : 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.13), value: configuration.isPressed)
    }
}

struct PracticeActionStyle: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.padding(.horizontal, 18).padding(.vertical, 10)
            .foregroundStyle(prominent ? .white : Color(red: 0.33, green: 0.38, blue: 0.55))
            .background {
                if prominent {
                    RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Color(red: 0.48, green: 0.57, blue: 0.88), Color(red: 0.36, green: 0.43, blue: 0.77)], startPoint: .top, endPoint: .bottom))
                }
            }
            .practiceGlass(radius: 16, tint: prominent ? .indigo.opacity(0.12) : .white.opacity(0.35), interactive: true)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

// Keep desktop sheets compact while allowing iPad Split View to constrain width.
extension View {
    @ViewBuilder func practiceSheetSize(width: CGFloat, height: CGFloat) -> some View {
        #if os(macOS)
        self.frame(width: width, height: height)
        #else
        self.frame(maxWidth: width).frame(height: height)
        #endif
    }
}
