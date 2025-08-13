import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView { UIView() }
    func updateUIView(_ uiView: UIView, context: Context) {}

    static func fire(in view: UIView, duration: TimeInterval = 1.2) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.width, height: 2)

        func cell(_ color: UIColor) -> CAEmitterCell {
            let c = CAEmitterCell()
            c.birthRate = 8
            c.lifetime = 3.5
            c.velocity = 180
            c.velocityRange = 80
            c.emissionLongitude = .pi
            c.emissionRange = .pi/8
            c.spin = 3.5
            c.spinRange = 4
            c.scale = 0.6
            c.scaleRange = 0.3
            c.contents = UIImage(systemName: "seal.fill")?.withTintColor(color, renderingMode: .alwaysOriginal).cgImage
            return c
        }
        emitter.emitterCells = [
            cell(.systemGreen), cell(.systemYellow), cell(.systemBlue), cell(.systemPink)
        ]
        view.layer.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            emitter.birthRate = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { emitter.removeFromSuperlayer() }
        }
    }
}

final class ConfettiHost: ObservableObject {
    weak var view: UIView?
    func fire() { if let v = view { ConfettiView.fire(in: v) } }
}

struct ConfettiHosting: UIViewRepresentable {
    @ObservedObject var host: ConfettiHost
    func makeUIView(context: Context) -> UIView { let v = UIView(); host.view = v; return v }
    func updateUIView(_ uiView: UIView, context: Context) {}
} 