// 参考元:
// https://github.com/ondrej-kvasnovsky/SimpleToastDemo

import Foundation
import SwiftUI

struct Toast: Equatable {
    var message: String
    var duration: Double = 3
    var width: Double = .infinity
}

struct ToastView: View {
    var message: String
    var width = CGFloat.infinity
    var onCancelTapped: (() -> Void)
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(message)
                .font(Font.caption)
                .foregroundColor(Color.white)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: width)
        .background(Color(UIColor.darkGray))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
}


struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    mainToastView()
                        .offset(y: 32)
                }.animation(.spring(), value: toast)
            )
            .onChange(of: toast) {
                showToast()
            }
    }
    
    @ViewBuilder func mainToastView() -> some View {
        if let toast {
            VStack {
                Spacer()
                ToastView(
                    message: toast.message,
                    width: toast.width
                ) {
                    dismissToast()
                }
            }
            .padding(32)
        }
    }
    
    private func showToast() {
        guard let toast else { return }
        
        UIImpactFeedbackGenerator(style: .light)
            .impactOccurred()
        
        if toast.duration > 0 {
            workItem?.cancel()
            
            let task = DispatchWorkItem {
                dismissToast()
            }
            
            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
        }
    }
    
    private func dismissToast() {
        withAnimation {
            toast = nil
        }
        
        workItem?.cancel()
        workItem = nil
    }
}


extension View {
    func toastView(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}
