import SwiftUI

struct FlowLayout: Layout {
    var alignment: HorizontalAlignment = .center
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, line) in result.lines.enumerated() {
            let yOffset = result.lineOffsets[index]
            
            for item in line.items {
                let xOffset: CGFloat = item.offset
                item.subview.place(
                    at: CGPoint(x: bounds.minX + xOffset,
                              y: bounds.minY + yOffset),
                    proposal: .unspecified
                )
            }
        }
    }
}

private struct FlowResult {
    struct Item {
        let subview: LayoutSubview
        let size: CGSize
        var offset: CGFloat = 0
    }
    
    struct Line  {
        var items: [Item] = []
        var width: CGFloat = 0
    }
    
    var lines: [Line] = []
    var lineOffsets: [CGFloat] = []
    var size: CGSize = .zero
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var currentLine = Line()
        var currentY: CGFloat = 0
        
        for subview in subviews {
            let itemSize = subview.sizeThatFits(.unspecified)
            let item = Item(subview: subview, size: itemSize)
            
            if currentLine.width + itemSize.width + spacing <= maxWidth {
                currentLine.items.append(item)
                currentLine.width += itemSize.width + spacing
            } else {
                lines.append(currentLine)
                lineOffsets.append(currentY)
                currentY += currentLine.items.map(\.size.height).max() ?? 0 + spacing
                currentLine = Line(items: [item], width: itemSize.width + spacing)
            }
        }
        
        if !currentLine.items.isEmpty {
            lines.append(currentLine)
            lineOffsets.append(currentY)
        }
        
        size = CGSize(
            width: maxWidth,
            height: currentY + (currentLine.items.map(\.size.height).max() ?? 0)
        )
        
        // Calculate horizontal offsets for items in each line
        for i in lines.indices {
            var currentOffset: CGFloat = 0
            for j in lines[i].items.indices {
                lines[i].items[j].offset = currentOffset
                currentOffset += lines[i].items[j].size.width + spacing
            }
        }
    }
} 
