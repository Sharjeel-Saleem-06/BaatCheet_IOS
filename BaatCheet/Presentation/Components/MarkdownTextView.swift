//
//  MarkdownTextView.swift
//  BaatCheet
//
//  Advanced Markdown renderer for chat messages
//  Supports: Headers, Bold, Italic, Code blocks with syntax highlighting,
//  Tables with horizontal scroll, Lists, Blockquotes, Links, Inline code
//

import SwiftUI

// MARK: - Markdown Element Types

private enum MarkdownElement: Identifiable {
    case heading(text: String, level: Int)
    case paragraph(segments: [InlineSegment])
    case codeBlock(code: String, language: String?)
    case bulletList(items: [[InlineSegment]])
    case numberedList(items: [[InlineSegment]])
    case blockquote(segments: [InlineSegment])
    case table(headers: [String], rows: [[String]])
    case horizontalRule
    case empty
    
    var id: String {
        switch self {
        case .heading(let text, let level): return "h\(level)-\(text.prefix(20))"
        case .paragraph(let segs): return "p-\(segs.hashValue)"
        case .codeBlock(let code, _): return "code-\(code.prefix(20).hashValue)"
        case .bulletList(let items): return "ul-\(items.count)"
        case .numberedList(let items): return "ol-\(items.count)"
        case .blockquote(let segs): return "bq-\(segs.hashValue)"
        case .table(let h, _): return "table-\(h.joined())"
        case .horizontalRule: return "hr-\(UUID().uuidString)"
        case .empty: return "empty-\(UUID().uuidString)"
        }
    }
}

private enum InlineSegment: Hashable {
    case text(String)
    case bold(String)
    case italic(String)
    case boldItalic(String)
    case code(String)
    case link(text: String, url: String)
    case strikethrough(String)
}

// MARK: - Main View

struct MarkdownTextView: View {
    let content: String
    var fontSize: CGFloat = 15
    
    var body: some View {
        let elements = parseMarkdown(content)
        
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(elements.enumerated()), id: \.offset) { _, element in
                renderElement(element)
            }
        }
    }
    
    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element {
        case .heading(let text, let level):
            HeadingView(text: text, level: level)
        case .paragraph(let segments):
            InlineTextView(segments: segments, fontSize: fontSize)
        case .codeBlock(let code, let language):
            CodeBlockView(code: code, language: language)
        case .bulletList(let items):
            BulletListView(items: items, fontSize: fontSize)
        case .numberedList(let items):
            NumberedListView(items: items, fontSize: fontSize)
        case .blockquote(let segments):
            BlockquoteView(segments: segments, fontSize: fontSize)
        case .table(let headers, let rows):
            TableView(headers: headers, rows: rows)
        case .horizontalRule:
            Divider().padding(.vertical, 4)
        case .empty:
            Spacer().frame(height: 4)
        }
    }
}

// MARK: - Heading View

private struct HeadingView: View {
    let text: String
    let level: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.system(size: headingSize, weight: level <= 2 ? .bold : .semibold))
                .foregroundColor(.primary)
                .padding(.top, 6)
            
            if level <= 2 {
                Divider()
            }
        }
    }
    
    private var headingSize: CGFloat {
        switch level {
        case 1: return 22
        case 2: return 19
        case 3: return 17
        case 4: return 16
        default: return 15
        }
    }
}

// MARK: - Inline Text View (renders bold, italic, code, links)

private struct InlineTextView: View {
    let segments: [InlineSegment]
    var fontSize: CGFloat = 15
    
    var body: some View {
        let attrString = buildAttributedString(from: segments, fontSize: fontSize)
        Text(attrString)
            .textSelection(.enabled)
    }
}

private func buildAttributedString(from segments: [InlineSegment], fontSize: CGFloat) -> AttributedString {
    var result = AttributedString()
    
    for segment in segments {
        var part: AttributedString
        switch segment {
        case .text(let str):
            part = AttributedString(str)
            part.font = .system(size: fontSize)
            part.foregroundColor = .primary
            
        case .bold(let str):
            part = AttributedString(str)
            part.font = .system(size: fontSize, weight: .bold)
            part.foregroundColor = .primary
            
        case .italic(let str):
            part = AttributedString(str)
            part.font = .system(size: fontSize).italic()
            part.foregroundColor = .primary
            
        case .boldItalic(let str):
            part = AttributedString(str)
            part.font = .system(size: fontSize, weight: .bold).italic()
            part.foregroundColor = .primary
            
        case .code(let str):
            part = AttributedString(" \(str) ")
            part.font = .system(size: fontSize - 1, design: .monospaced)
            part.foregroundColor = Color(red: 0.216, green: 0.255, blue: 0.318)
            part.backgroundColor = Color(red: 0.953, green: 0.957, blue: 0.965)
            
        case .link(let text, _):
            part = AttributedString(text)
            part.font = .system(size: fontSize)
            part.foregroundColor = .blue
            part.underlineStyle = .single
            
        case .strikethrough(let str):
            part = AttributedString(str)
            part.font = .system(size: fontSize)
            part.foregroundColor = .secondary
            part.strikethroughStyle = .single
        }
        result.append(part)
    }
    
    return result
}

// MARK: - Code Block View

private struct CodeBlockView: View {
    let code: String
    let language: String?
    @State private var copied = false
    @State private var collapsed = false
    
    private let languageNames: [String: String] = [
        "javascript": "JavaScript", "js": "JavaScript",
        "typescript": "TypeScript", "ts": "TypeScript",
        "python": "Python", "py": "Python",
        "java": "Java", "kotlin": "Kotlin", "kt": "Kotlin",
        "swift": "Swift", "csharp": "C#", "cs": "C#",
        "cpp": "C++", "c": "C", "go": "Go", "rust": "Rust",
        "php": "PHP", "ruby": "Ruby", "sql": "SQL",
        "html": "HTML", "css": "CSS", "scss": "SCSS",
        "bash": "Bash", "shell": "Shell", "sh": "Shell",
        "json": "JSON", "yaml": "YAML", "yml": "YAML",
        "xml": "XML", "markdown": "Markdown", "md": "Markdown"
    ]
    
    var body: some View {
        let lines = code.components(separatedBy: "\n")
        let lineCount = lines.count
        let isLong = lineCount > 15
        let displayName = language.flatMap { languageNames[$0.lowercased()] } ?? language ?? "Code"
        
        VStack(spacing: 0) {
            HStack {
                Text(displayName)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(white: 0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.25))
                    .cornerRadius(4)
                
                Text("\(lineCount) line\(lineCount == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.56))
                
                Spacer()
                
                if isLong {
                    Button(action: { collapsed.toggle() }) {
                        Image(systemName: collapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.56))
                    }
                }
                
                Button(action: {
                    UIPasteboard.general.string = code
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                        Text(copied ? "Copied" : "Copy")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(copied ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(white: 0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(copied ? Color(red: 0.204, green: 0.78, blue: 0.349).opacity(0.2) : Color(white: 0.25))
                    .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.176, green: 0.176, blue: 0.176))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .trailing, spacing: 0) {
                        let displayLines = collapsed && isLong ? Array(lines.prefix(5)) : lines
                        ForEach(Array(displayLines.enumerated()), id: \.offset) { index, _ in
                            Text("\(index + 1)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(white: 0.43))
                                .frame(height: 20)
                        }
                    }
                    .padding(.trailing, 12)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        let displayLines = collapsed && isLong ? Array(lines.prefix(5)) : lines
                        ForEach(Array(displayLines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(red: 0.831, green: 0.831, blue: 0.831))
                                .frame(height: 20, alignment: .leading)
                        }
                    }
                }
                .padding(12)
            }
            .background(Color(red: 0.118, green: 0.118, blue: 0.118))
            
            if collapsed && isLong {
                Button(action: { collapsed = false }) {
                    Text("Click to expand (\(lineCount - 5) more lines)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.56))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color(red: 0.176, green: 0.176, blue: 0.176))
            }
        }
        .cornerRadius(8)
    }
}

// MARK: - Bullet List View

private struct BulletListView: View {
    let items: [[InlineSegment]]
    var fontSize: CGFloat = 15
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\u{2022}")
                        .font(.system(size: fontSize + 2, weight: .bold))
                        .foregroundColor(Color(red: 0.204, green: 0.78, blue: 0.349))
                    
                    InlineTextView(segments: item, fontSize: fontSize)
                }
            }
        }
        .padding(.leading, 4)
    }
}

// MARK: - Numbered List View

private struct NumberedListView: View {
    let items: [[InlineSegment]]
    var fontSize: CGFloat = 15
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundColor(Color(red: 0.204, green: 0.78, blue: 0.349))
                        .frame(width: 24, alignment: .trailing)
                    
                    InlineTextView(segments: item, fontSize: fontSize)
                }
            }
        }
        .padding(.leading, 4)
    }
}

// MARK: - Blockquote View

private struct BlockquoteView: View {
    let segments: [InlineSegment]
    var fontSize: CGFloat = 15
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color(red: 0.204, green: 0.78, blue: 0.349))
                .frame(width: 3)
            
            InlineTextView(segments: segments, fontSize: fontSize)
                .foregroundColor(.secondary)
                .italic()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .background(Color(red: 0.941, green: 1.0, blue: 0.957))
        .cornerRadius(4)
    }
}

// MARK: - Table View

private struct TableView: View {
    let headers: [String]
    let rows: [[String]]
    
    var body: some View {
        if headers.isEmpty { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            ForEach(Array(headers.enumerated()), id: \.offset) { index, header in
                                Text(header)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(minWidth: columnWidth(for: index), alignment: .leading)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                
                                if index < headers.count - 1 {
                                    Rectangle()
                                        .fill(Color(UIColor.separator).opacity(0.5))
                                        .frame(width: 1)
                                }
                            }
                        }
                        .background(Color(red: 0.204, green: 0.78, blue: 0.349).opacity(0.1))
                        
                        Rectangle()
                            .fill(Color(red: 0.204, green: 0.78, blue: 0.349).opacity(0.3))
                            .frame(height: 2)
                        
                        ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                            if rowIndex > 0 {
                                Divider()
                            }
                            HStack(spacing: 0) {
                                ForEach(Array(headers.indices), id: \.self) { colIndex in
                                    let cell = colIndex < row.count ? row[colIndex] : ""
                                    Text(cell)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                        .frame(minWidth: columnWidth(for: colIndex), alignment: .leading)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                    
                                    if colIndex < headers.count - 1 {
                                        Rectangle()
                                            .fill(Color(UIColor.separator).opacity(0.3))
                                            .frame(width: 1)
                                    }
                                }
                            }
                            .background(rowIndex % 2 == 0 ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground).opacity(0.5))
                        }
                    }
                }
                
                if headers.count > 2 {
                    Text("\u{2190} Swipe to see more \u{2192}")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.tertiarySystemBackground))
                }
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
        )
    }
    
    private func columnWidth(for index: Int) -> CGFloat {
        let headerLen = index < headers.count ? headers[index].count : 0
        let maxDataLen = rows.map { $0.count > index ? $0[index].count : 0 }.max() ?? 0
        let maxLen = max(headerLen, maxDataLen)
        
        switch maxLen {
        case 0...8: return 90
        case 9...15: return 120
        case 16...25: return 160
        default: return 200
        }
    }
}

// MARK: - Markdown Parser

private func parseMarkdown(_ text: String) -> [MarkdownElement] {
    if text.count < 100 && !text.contains("```") && !text.contains("#") && !text.contains("|") {
        return [.paragraph(segments: parseInline(text))]
    }
    
    var elements: [MarkdownElement] = []
    var currentIndex = text.startIndex
    
    while currentIndex < text.endIndex {
        if let codeStart = text.range(of: "```", range: currentIndex..<text.endIndex) {
            if codeStart.lowerBound > currentIndex {
                let before = String(text[currentIndex..<codeStart.lowerBound])
                elements.append(contentsOf: parseTextContent(before))
            }
            
            let contentStart = codeStart.upperBound
            if let codeEnd = text.range(of: "```", range: contentStart..<text.endIndex) {
                let codeSection = String(text[contentStart..<codeEnd.lowerBound])
                let lines = codeSection.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                
                var language: String? = nil
                var code: String
                
                if lines.count > 1 {
                    let langCandidate = lines[0].trimmingCharacters(in: .whitespaces)
                    if langCandidate.count < 20 && langCandidate.allSatisfy({ $0.isLetter || $0.isNumber }) && !langCandidate.isEmpty {
                        language = langCandidate
                        code = String(lines[1])
                    } else {
                        code = codeSection
                    }
                } else {
                    code = codeSection
                }
                
                elements.append(.codeBlock(code: code.trimmingCharacters(in: .newlines), language: language))
                currentIndex = codeEnd.upperBound
            } else {
                let remaining = String(text[codeStart.lowerBound..<text.endIndex])
                elements.append(contentsOf: parseTextContent(remaining))
                break
            }
        } else {
            let remaining = String(text[currentIndex..<text.endIndex])
            elements.append(contentsOf: parseTextContent(remaining))
            break
        }
    }
    
    return elements
}

private func parseTextContent(_ text: String) -> [MarkdownElement] {
    var elements: [MarkdownElement] = []
    let lines = text.components(separatedBy: "\n")
    var i = 0
    
    while i < lines.count {
        let line = lines[i].trimmingCharacters(in: .whitespaces)
        
        if line.isEmpty {
            i += 1
            continue
        }
        
        // Headings
        if line.hasPrefix("#") {
            if let match = line.range(of: "^(#{1,6})\\s+(.+)$", options: .regularExpression) {
                let hashes = line.prefix(while: { $0 == "#" })
                let headingText = String(line.dropFirst(hashes.count).trimmingCharacters(in: .whitespaces))
                elements.append(.heading(text: headingText, level: hashes.count))
            }
            i += 1
            continue
        }
        
        // Table detection
        if line.contains("|") && i + 1 < lines.count && lines[i + 1].contains("---") {
            var tableLines: [String] = []
            while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).contains("|") {
                tableLines.append(lines[i])
                i += 1
            }
            elements.append(parseTable(tableLines))
            continue
        }
        
        // Horizontal rule
        if line.range(of: "^[-*_]{3,}$", options: .regularExpression) != nil {
            elements.append(.horizontalRule)
            i += 1
            continue
        }
        
        // Bullet list
        if line.range(of: "^[-*+]\\s+.+", options: .regularExpression) != nil {
            var items: [[InlineSegment]] = []
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                guard l.range(of: "^[-*+]\\s+.+", options: .regularExpression) != nil else { break }
                let itemText = l.replacingOccurrences(of: "^[-*+]\\s+", with: "", options: .regularExpression)
                items.append(parseInline(itemText))
                i += 1
            }
            elements.append(.bulletList(items: items))
            continue
        }
        
        // Numbered list
        if line.range(of: "^\\d+\\.\\s+.+", options: .regularExpression) != nil {
            var items: [[InlineSegment]] = []
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                guard l.range(of: "^\\d+\\.\\s+.+", options: .regularExpression) != nil else { break }
                let itemText = l.replacingOccurrences(of: "^\\d+\\.\\s+", with: "", options: .regularExpression)
                items.append(parseInline(itemText))
                i += 1
            }
            elements.append(.numberedList(items: items))
            continue
        }
        
        // Blockquote
        if line.hasPrefix(">") {
            var quoteLines: [String] = []
            while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                quoteLines.append(lines[i].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "^>\\s*", with: "", options: .regularExpression))
                i += 1
            }
            elements.append(.blockquote(segments: parseInline(quoteLines.joined(separator: " "))))
            continue
        }
        
        // Regular paragraph
        var paragraphLines: [String] = []
        while i < lines.count {
            let l = lines[i].trimmingCharacters(in: .whitespaces)
            if l.isEmpty || l.hasPrefix("#") || l.hasPrefix(">") || l.contains("|") ||
               l.range(of: "^[-*+]\\s+.+", options: .regularExpression) != nil ||
               l.range(of: "^\\d+\\.\\s+.+", options: .regularExpression) != nil {
                break
            }
            paragraphLines.append(lines[i])
            i += 1
        }
        
        if !paragraphLines.isEmpty {
            let paragraphText = paragraphLines.joined(separator: " ")
            elements.append(.paragraph(segments: parseInline(paragraphText)))
        }
    }
    
    return elements
}

private func parseTable(_ lines: [String]) -> MarkdownElement {
    guard lines.count >= 2 else { return .table(headers: [], rows: []) }
    
    let headerLine = lines[0].trimmingCharacters(in: .whitespaces)
        .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
    let headers = headerLine.components(separatedBy: "|")
        .map { $0.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "^\\*+|\\*+$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty && $0.range(of: "^[-:]+$", options: .regularExpression) == nil }
    
    let separatorIndex = lines.firstIndex { $0.contains("---") || $0.contains(":--") || $0.contains("--:") }
    let dataStartIndex = (separatorIndex ?? 1) + 1
    
    let rows = lines.dropFirst(dataStartIndex).compactMap { line -> [String]? in
        let cleanLine = line.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        guard !cleanLine.contains("---") && !cleanLine.isEmpty else { return nil }
        
        return cleanLine.components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "^\\*+|\\*+$", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }.filter { !$0.isEmpty }
    
    return .table(headers: headers, rows: rows)
}

// MARK: - Inline Markdown Parser

private func parseInline(_ text: String) -> [InlineSegment] {
    var segments: [InlineSegment] = []
    let chars = Array(text)
    var i = 0
    var buffer = ""
    
    func flushBuffer() {
        if !buffer.isEmpty {
            segments.append(.text(buffer))
            buffer = ""
        }
    }
    
    while i < chars.count {
        let char = chars[i]
        
        // Bold italic: ***text***
        if char == "*" && i + 2 < chars.count && chars[i + 1] == "*" && chars[i + 2] == "*" {
            if let endIdx = findClosing("***", in: chars, from: i + 3) {
                flushBuffer()
                let content = String(chars[(i + 3)..<endIdx])
                segments.append(.boldItalic(content))
                i = endIdx + 3
                continue
            }
        }
        
        // Bold: **text**
        if char == "*" && i + 1 < chars.count && chars[i + 1] == "*" {
            if let endIdx = findClosing("**", in: chars, from: i + 2) {
                flushBuffer()
                let content = String(chars[(i + 2)..<endIdx])
                segments.append(.bold(content))
                i = endIdx + 2
                continue
            }
        }
        
        // Strikethrough: ~~text~~
        if char == "~" && i + 1 < chars.count && chars[i + 1] == "~" {
            if let endIdx = findClosing("~~", in: chars, from: i + 2) {
                flushBuffer()
                let content = String(chars[(i + 2)..<endIdx])
                segments.append(.strikethrough(content))
                i = endIdx + 2
                continue
            }
        }
        
        // Italic: *text* (single asterisk, not followed by another)
        if char == "*" && (i + 1 >= chars.count || chars[i + 1] != "*") {
            let nextChar = i + 1 < chars.count ? chars[i + 1] : Character(" ")
            if nextChar.isLetter || nextChar.isNumber {
                if let endIdx = findSingleClosing("*", in: chars, from: i + 1) {
                    flushBuffer()
                    let content = String(chars[(i + 1)..<endIdx])
                    segments.append(.italic(content))
                    i = endIdx + 1
                    continue
                }
            }
            // Skip orphan asterisk
            i += 1
            continue
        }
        
        // Inline code: `code`
        if char == "`" && (i == 0 || chars[i - 1] != "`") {
            if let endIdx = findSingleClosing("`", in: chars, from: i + 1) {
                flushBuffer()
                let content = String(chars[(i + 1)..<endIdx])
                segments.append(.code(content))
                i = endIdx + 1
                continue
            }
        }
        
        // Link: [text](url)
        if char == "[" {
            if let closeBracket = findSingleClosing("]", in: chars, from: i + 1),
               closeBracket + 1 < chars.count && chars[closeBracket + 1] == "(",
               let closeParen = findSingleClosing(")", in: chars, from: closeBracket + 2) {
                flushBuffer()
                let linkText = String(chars[(i + 1)..<closeBracket])
                let linkUrl = String(chars[(closeBracket + 2)..<closeParen])
                segments.append(.link(text: linkText, url: linkUrl))
                i = closeParen + 1
                continue
            }
        }
        
        buffer.append(char)
        i += 1
    }
    
    flushBuffer()
    return segments
}

private func findClosing(_ marker: String, in chars: [Character], from start: Int) -> Int? {
    let markerChars = Array(marker)
    var i = start
    while i <= chars.count - markerChars.count {
        var matched = true
        for j in 0..<markerChars.count {
            if chars[i + j] != markerChars[j] {
                matched = false
                break
            }
        }
        if matched { return i }
        i += 1
    }
    return nil
}

private func findSingleClosing(_ marker: String, in chars: [Character], from start: Int) -> Int? {
    let markerChar = marker.first!
    var i = start
    while i < chars.count {
        if chars[i] == markerChar { return i }
        i += 1
    }
    return nil
}
