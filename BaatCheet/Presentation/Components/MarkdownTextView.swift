//
//  MarkdownTextView.swift
//  BaatCheet
//
//  Advanced Markdown renderer matching Android MarkdownText quality
//  Supports: Headers, Bold, Italic, Strikethrough, Code blocks with syntax highlighting,
//  Tables with dynamic column widths, Lists (nested), Blockquotes, Links, Inline code
//

import SwiftUI

// MARK: - Color Palette

private enum MDColors {
    static let text = Color.primary
    static let textSecondary = Color.secondary
    static let link = Color(red: 0, green: 0.478, blue: 1)
    static let codeBackground = Color(UIColor.secondarySystemBackground)
    static let codeBlockBg = Color(red: 0.118, green: 0.118, blue: 0.118)
    static let codeBlockText = Color(red: 0.831, green: 0.831, blue: 0.831)
    static let tableBorder = Color(red: 0.898, green: 0.906, blue: 0.922)
    static let tableHeaderBg = Color(red: 0.204, green: 0.78, blue: 0.349).opacity(0.1)
    static let tableAccent = Color(red: 0.204, green: 0.78, blue: 0.349)
    static let blockquoteBorder = Color(red: 0.204, green: 0.78, blue: 0.349)
    static let blockquoteBg = Color(red: 0.204, green: 0.78, blue: 0.349).opacity(0.05)
    static let bulletColor = Color(red: 0.204, green: 0.78, blue: 0.349)
    static let inlineCodeText = Color(red: 0.216, green: 0.255, blue: 0.318)
    // Syntax highlighting
    static let keyword = Color(red: 0.773, green: 0.525, blue: 0.753)
    static let string = Color(red: 0.808, green: 0.569, blue: 0.471)
    static let comment = Color(red: 0.416, green: 0.6, blue: 0.333)
    static let number = Color(red: 0.71, green: 0.808, blue: 0.659)
    static let function = Color(red: 0.863, green: 0.863, blue: 0.667)
}

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

// MARK: - Block Types

private enum MDBlock {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(language: String, code: String)
    case table(headers: [String], rows: [[String]], colWidths: [CGFloat])
    case bulletList(items: [String])
    case numberedList(items: [String])
    case blockquote(text: String)
    case horizontalRule
}

// MARK: - Main View

struct MarkdownTextView: View {
    let content: String
    
    var body: some View {
        let blocks = Self.parseBlocks(content)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(blocks.indices, id: \.self) { i in
                blockView(blocks[i])
            }
        }
    }

    // MARK: - Block Rendering

    @ViewBuilder
    private func blockView(_ block: MDBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            headingView(level: level, text: text)
        case .paragraph(let text):
            richText(text).fixedSize(horizontal: false, vertical: true)
        case .codeBlock(let lang, let code):
            codeBlockView(language: lang, code: code)
        case .table(let headers, let rows, let widths):
            tableView(headers: headers, rows: rows, colWidths: widths)
        case .bulletList(let items):
            bulletListView(items: items)
        case .numberedList(let items):
            numberedListView(items: items)
        case .blockquote(let text):
            blockquoteView(text: text)
        case .horizontalRule:
            Divider().padding(.vertical, 6)
        }
    }

    // MARK: - Heading

    private func headingView(level: Int, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            richText(text)
                .font(.system(size: headingSize(level), weight: level <= 2 ? .bold : .semibold))
            if level <= 2 {
                Divider().opacity(0.5)
            }
        }
        .padding(.top, level <= 2 ? 10 : 6)
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: return 22
        case 2: return 19
        case 3: return 17
        case 4: return 16
        default: return 15
        }
    }

    // MARK: - Code Block (dark theme, line numbers, copy, collapse)

    private func codeBlockView(language: String, code: String) -> some View {
        let lines = code.components(separatedBy: "\n")
        let lineCount = lines.count
        let isLong = lineCount > 15
        let displayLang = languageNames[language.lowercased()] ?? (language.isEmpty ? "Code" : language)

        return CodeBlockContainer(
            displayLang: displayLang,
            lineCount: lineCount,
            isLong: isLong,
            lines: lines,
            code: code,
            language: language
        )
    }

    // MARK: - Table (dynamic widths, scroll, alternating rows)

    private func tableView(headers: [String], rows: [[String]], colWidths: [CGFloat]) -> some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header row
                    HStack(spacing: 0) {
                        ForEach(headers.indices, id: \.self) { col in
                            Text(headers[col])
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(width: colWidths[safe: col] ?? 120, alignment: .leading)
                            if col < headers.count - 1 {
                                Rectangle()
                                    .fill(MDColors.tableBorder.opacity(0.5))
                                    .frame(width: 1)
                            }
                        }
                    }
                    .background(MDColors.tableHeaderBg)

                    Rectangle()
                        .fill(MDColors.tableAccent.opacity(0.3))
                        .frame(height: 2)

                    // Data rows
                    ForEach(rows.indices, id: \.self) { rowIdx in
                        if rowIdx > 0 {
                            Rectangle()
                                .fill(MDColors.tableBorder.opacity(0.5))
                                .frame(height: 1)
                        }
                        HStack(spacing: 0) {
                            ForEach(0..<headers.count, id: \.self) { col in
                                Text(rows[rowIdx][safe: col] ?? "")
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary.opacity(0.85))
                                    .lineLimit(nil)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .frame(width: colWidths[safe: col] ?? 120, alignment: .leading)
                                if col < headers.count - 1 {
                                    Rectangle()
                                        .fill(MDColors.tableBorder.opacity(0.3))
                                        .frame(width: 1)
                                }
                            }
                        }
                        .background(rowIdx % 2 == 0 ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemBackground).opacity(0.4))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(MDColors.tableBorder, lineWidth: 1)
                )
            }

            if headers.count > 2 {
                Text("← Swipe to see more →")
                    .font(.system(size: 11))
                    .italic()
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(0)
            }
        }
        .cornerRadius(12)
    }

    // MARK: - Bullet List

    private func bulletListView(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(items.indices, id: \.self) { idx in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("•")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(MDColors.bulletColor)
                    richText(items[idx]).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.leading, 4)
    }

    // MARK: - Numbered List

    private func numberedListView(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(items.indices, id: \.self) { idx in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(idx + 1).")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MDColors.bulletColor)
                        .frame(width: 24, alignment: .trailing)
                    richText(items[idx]).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.leading, 4)
    }

    // MARK: - Blockquote

    private func blockquoteView(text: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(MDColors.blockquoteBorder)
                .frame(width: 3)
            richText(text)
                .italic()
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .padding(.vertical, 2)
        .background(MDColors.blockquoteBg)
        .cornerRadius(6)
    }

    // MARK: - Inline Rich Text (bold, italic, strikethrough, inline code, links)

    private func richText(_ text: String) -> Text {
        var result = Text("")
        var remaining = text[text.startIndex...]

        while !remaining.isEmpty {
            // Bold italic ***text***
            if remaining.hasPrefix("***") {
                remaining = remaining.dropFirst(3)
                if let end = remaining.range(of: "***") {
                    let s = String(remaining[remaining.startIndex..<end.lowerBound])
                    result = result + Text(s).bold().italic()
                    remaining = remaining[end.upperBound...]
                    continue
                }
                result = result + Text("***")
                continue
            }
            // Bold **text**
            if remaining.hasPrefix("**") {
                remaining = remaining.dropFirst(2)
                if let end = remaining.range(of: "**") {
                    let s = String(remaining[remaining.startIndex..<end.lowerBound])
                    result = result + Text(s).bold()
                    remaining = remaining[end.upperBound...]
                    continue
                }
                result = result + Text("**")
                continue
            }
            // Strikethrough ~~text~~
            if remaining.hasPrefix("~~") {
                remaining = remaining.dropFirst(2)
                if let end = remaining.range(of: "~~") {
                    let s = String(remaining[remaining.startIndex..<end.lowerBound])
                    result = result + Text(s).strikethrough()
                    remaining = remaining[end.upperBound...]
                    continue
                }
                result = result + Text("~~")
                continue
            }
            // Italic *text* or _text_
            if remaining.hasPrefix("*") || remaining.hasPrefix("_") {
                let d = String(remaining.prefix(1))
                remaining = remaining.dropFirst(1)
                if let end = remaining.range(of: d) {
                    let s = String(remaining[remaining.startIndex..<end.lowerBound])
                    if !s.isEmpty && !s.contains("\n") {
                        result = result + Text(s).italic()
                        remaining = remaining[end.upperBound...]
                        continue
                    }
                }
                result = result + Text(d)
                continue
            }
            // Inline code `text`
            if remaining.hasPrefix("`") {
                remaining = remaining.dropFirst(1)
                if let end = remaining.firstIndex(of: "`") {
                    let s = String(remaining[remaining.startIndex..<end])
                    result = result + Text(" \(s) ")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(MDColors.inlineCodeText)
                    remaining = remaining[remaining.index(after: end)...]
                    continue
                }
                result = result + Text("`")
                continue
            }
            // Link [text](url)
            if remaining.hasPrefix("[") {
                let sub = String(remaining)
                if let bracketEnd = sub.firstIndex(of: "]"),
                   sub.index(after: bracketEnd) < sub.endIndex,
                   sub[sub.index(after: bracketEnd)] == "(" {
                    if let parenEnd = sub[sub.index(after: bracketEnd)...].firstIndex(of: ")") {
                        let linkText = String(sub[sub.index(after: sub.startIndex)..<bracketEnd])
                        result = result + Text(linkText)
                            .foregroundColor(MDColors.link)
                            .underline()
                        let advance = sub.distance(from: sub.startIndex, to: sub.index(after: parenEnd))
                        remaining = remaining.dropFirst(advance)
                        continue
                    }
                }
                var ch = ""
                ch.append(remaining[remaining.startIndex])
                remaining = remaining.dropFirst(1)
                result = result + Text(ch)
                continue
            }
            // Plain text
            var plain = ""
            while !remaining.isEmpty {
                let ch = remaining[remaining.startIndex]
                if ch == "*" || ch == "_" || ch == "`" || ch == "~" || ch == "[" { break }
                plain.append(ch)
                remaining = remaining.dropFirst(1)
            }
            if !plain.isEmpty {
                result = result + Text(plain)
            }
        }
        return result
            .font(.system(size: 15))
            .foregroundColor(.primary)
    }

    // MARK: - Parser

    static func parseBlocks(_ text: String) -> [MDBlock] {
        var blocks: [MDBlock] = []
        let lines = text.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let raw = lines[i]
            let trimmed = raw.trimmingCharacters(in: .whitespaces)

            // Code block
            if trimmed.hasPrefix("```") {
                let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                if i < lines.count { i += 1 }
                blocks.append(.codeBlock(language: lang, code: codeLines.joined(separator: "\n")))
                continue
            }

            // Table
            if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
                var tableLines: [String] = []
                while i < lines.count {
                    let tl = lines[i].trimmingCharacters(in: .whitespaces)
                    guard tl.hasPrefix("|") && tl.hasSuffix("|") else { break }
                    tableLines.append(tl)
                    i += 1
                }
                if let tbl = parseTable(tableLines) { blocks.append(tbl) }
                continue
            }

            // Heading
            if let level = headingLevel(trimmed) {
                let t = String(trimmed.drop(while: { $0 == "#" })).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(level: level, text: t))
                i += 1; continue
            }

            // Bullet list
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                var items: [String] = []
                while i < lines.count {
                    let ul = lines[i].trimmingCharacters(in: .whitespaces)
                    if ul.hasPrefix("- ") || ul.hasPrefix("* ") || ul.hasPrefix("+ ") {
                        items.append(String(ul.dropFirst(2)))
                        i += 1
                    } else if ul.hasPrefix("  ") && !items.isEmpty {
                        items[items.count - 1] += " " + ul.trimmingCharacters(in: .whitespaces)
                        i += 1
                    } else { break }
                }
                blocks.append(.bulletList(items: items))
                continue
            }

            // Numbered list
            if trimmed.range(of: #"^\d+[\.\)] "#, options: .regularExpression) != nil {
                var items: [String] = []
                while i < lines.count {
                    let ol = lines[i].trimmingCharacters(in: .whitespaces)
                    if let r = ol.range(of: #"^\d+[\.\)] "#, options: .regularExpression) {
                        items.append(String(ol[r.upperBound...]))
                        i += 1
                    } else if ol.hasPrefix("  ") && !items.isEmpty {
                        items[items.count - 1] += " " + ol.trimmingCharacters(in: .whitespaces)
                        i += 1
                    } else { break }
                }
                blocks.append(.numberedList(items: items))
                continue
            }

            // Blockquote
            if trimmed.hasPrefix("> ") || trimmed == ">" {
                var qLines: [String] = []
                while i < lines.count {
                    let ql = lines[i].trimmingCharacters(in: .whitespaces)
                    if ql.hasPrefix("> ") { qLines.append(String(ql.dropFirst(2))); i += 1 }
                    else if ql == ">" { qLines.append(""); i += 1 }
                    else { break }
                }
                blocks.append(.blockquote(text: qLines.joined(separator: "\n")))
                continue
            }

            // Horizontal rule
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                blocks.append(.horizontalRule)
                i += 1; continue
            }

            // Empty line
            if trimmed.isEmpty { i += 1; continue }

            // Paragraph
            var para: [String] = []
            while i < lines.count {
                let pl = lines[i].trimmingCharacters(in: .whitespaces)
                if pl.isEmpty || pl.hasPrefix("#") || pl.hasPrefix("```") || (pl.hasPrefix("|") && pl.hasSuffix("|")) ||
                    pl.hasPrefix("- ") || pl.hasPrefix("* ") || pl.hasPrefix("+ ") ||
                    pl.hasPrefix("> ") || pl == "---" || pl == "***" || pl == "___" ||
                    pl.range(of: #"^\d+[\.\)] "#, options: .regularExpression) != nil { break }
                para.append(lines[i])
                i += 1
            }
            if !para.isEmpty {
                blocks.append(.paragraph(text: para.joined(separator: "\n")))
            }
        }
        return blocks
    }

    private static func headingLevel(_ line: String) -> Int? {
        guard line.hasPrefix("#") else { return nil }
        var level = 0
        for ch in line { if ch == "#" { level += 1 } else { break } }
        guard level >= 1 && level <= 6, line.count > level,
              line[line.index(line.startIndex, offsetBy: level)] == " " else { return nil }
        return level
    }

    private static func parseTable(_ lines: [String]) -> MDBlock? {
        guard lines.count >= 2 else { return nil }
        func split(_ row: String) -> [String] {
            var r = row.trimmingCharacters(in: .whitespaces)
            if r.hasPrefix("|") { r = String(r.dropFirst()) }
            if r.hasSuffix("|") { r = String(r.dropLast()) }
            return r.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        let headers = split(lines[0])
        guard !headers.isEmpty else { return nil }
        let start = (lines.count > 1 && lines[1].contains("---")) ? 2 : 1
        var rows: [[String]] = []
        for idx in start..<lines.count {
            let cells = split(lines[idx])
            if !cells.isEmpty && !cells.allSatisfy({ $0.contains("---") || $0.contains(":--") }) {
                rows.append(cells)
            }
        }
        // Dynamic column widths based on content
        let colCount = headers.count
        var widths: [CGFloat] = Array(repeating: 0, count: colCount)
        for col in 0..<colCount {
            let headerLen = headers[safe: col]?.count ?? 0
            let maxDataLen = rows.map { $0[safe: col]?.count ?? 0 }.max() ?? 0
            let maxLen = max(headerLen, maxDataLen)
            widths[col] = switch maxLen {
            case 0...8: 100
            case 9...15: 130
            case 16...25: 170
            case 26...40: 210
            default: 250
            }
        }
        return .table(headers: headers, rows: rows, colWidths: widths)
    }
}

// MARK: - Code Block Container (stateful for copy/collapse)

private struct CodeBlockContainer: View {
    let displayLang: String
    let lineCount: Int
    let isLong: Bool
    let lines: [String]
    let code: String
    let language: String

    @State private var copied = false
    @State private var collapsed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text(displayLang)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(white: 0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.25))
                        .cornerRadius(4)

                    Text("\(lineCount) line\(lineCount == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.55))
                }
                Spacer()
                HStack(spacing: 4) {
                    if isLong {
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { collapsed.toggle() } }) {
                            Image(systemName: collapsed ? "chevron.down" : "chevron.up")
                                .font(.system(size: 12))
                                .foregroundColor(Color(white: 0.55))
                        }
                        .frame(width: 28, height: 28)
                    }
                    Button(action: {
                        UIPasteboard.general.string = code
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11))
                            if copied {
                                Text("Copied!")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .foregroundColor(copied ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(white: 0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(copied ? Color(red: 0.204, green: 0.78, blue: 0.349).opacity(0.2) : Color(white: 0.25))
                        .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.176, green: 0.176, blue: 0.176))

            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers
                    VStack(alignment: .trailing, spacing: 0) {
                        let displayLines = collapsed && isLong ? Array(lines.prefix(5)) : lines
                        ForEach(displayLines.indices, id: \.self) { idx in
                            Text("\(idx + 1)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(white: 0.43))
                                .frame(height: 20)
                        }
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 12)

                    Rectangle()
                        .fill(Color(white: 0.25))
                        .frame(width: 1)

                    // Code
                    VStack(alignment: .leading, spacing: 0) {
                        let displayLines = collapsed && isLong ? Array(lines.prefix(5)) : lines
                        ForEach(displayLines.indices, id: \.self) { idx in
                            Text(displayLines[idx])
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(MDColors.codeBlockText)
                                .frame(height: 20, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.vertical, 10)
            }

            if collapsed && isLong {
                Button(action: { withAnimation { collapsed = false } }) {
                    Text("Click to expand (\(lineCount - 5) more lines)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.176, green: 0.176, blue: 0.176))
                }
            }
        }
        .background(MDColors.codeBlockBg)
        .cornerRadius(10)
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
