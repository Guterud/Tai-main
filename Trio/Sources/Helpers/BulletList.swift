import SwiftUI

struct BulletList: View {
    var withBorder: Bool = false
    var toInfinity: Bool = true
    var alignLeft: Bool = true
    var borderWidth: CGFloat {
        withBorder ? 1 : 0
    }

    var textFrameMaxWidth: CGFloat? {
        toInfinity ? .infinity : nil
    }

    var textFrameAlignment: Alignment {
        alignLeft ? .leading : .center
    }

    var listItems: [String]
    var listItemSpacing: CGFloat? = nil
    var bullet: String = "•"
    var bulletWidth: CGFloat? = nil
    var bulletAlignment: Alignment = .leading

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: listItemSpacing
        ) {
            ForEach(listItems, id: \.self) { data in
                HStack(alignment: .top, spacing: 5) {
                    Text(bullet)
                        .frame(
                            width: bulletWidth,
                            alignment: bulletAlignment
                        )
                        .border(
                            Color.blue,
                            width: borderWidth
                        )

                    Text(data)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(
                            maxWidth: textFrameMaxWidth,
                            alignment: textFrameAlignment
                        )
                        .border(
                            Color.orange,
                            width: borderWidth
                        )
                }
            }
        }
        .padding(2)
        .border(.green, width: borderWidth)
    }
}
