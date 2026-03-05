//
//  MarkdownTextView.swift
//  BaatCheet
//
//  Production-grade Markdown renderer matching Android MarkdownText + ChatGPT quality
//  Supports: Headers, Bold, Italic, Bold-Italic, Strikethrough, Code blocks with syntax
//  highlighting & line numbers, Tables with dynamic column widths & horizontal scroll,
//  Nested Lists (bullet & numbered), Blockquotes, Links, Inline code, Horizontal rules,
//  Citations [1], Superscripts, Performance truncation for long content
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
    static let codeHeaderBg = Color(red: 0.176, green: 0.176, blue: 0.176)
    static let tableBorder = Color(red: 0.898, green: 0.906, blue: 0.922)
    static let tableHeaderBg = Color(red: 0.204, green: 0.78, blue: 0.349).opacity(0.1)
    static let tableAccent = Color(red: 0.204, green: 0.78, blue: 0.349)
    static let blockquoteBorder = Color(red: 0.204, green: 0.78, blue: 0.349)
    static let blockquoteBg = Color(red: 0.204, green: 0.78, blue: 0.349).opacity(0.05)
    static let bulletColor = Color(red: 0.204, green: 0.78, blue: 0.349)
    static let inlineCodeBg = Color(UIColor.secondarySystemBackground)
    static let inlineCodeText = Color(red: 0.216, green: 0.255, blue: 0.318)
    static let keyword = Color(red: 0.773, green: 0.525, blue: 0.753)
    static let string = Color(red: 0.808, green: 0.569, blue: 0.471)
    static let comment = Color(red: 0.416, green: 0.6, blue: 0.333)
    static let number = Color(red: 0.71, green: 0.808, blue: 0.659)
    static let function = Color(red: 0.863, green: 0.863, blue: 0.667)
    static let lineNumber = Color(white: 0.43)
    static let codeSeparator = Color(white: 0.25)
    static let badgeBg = Color(white: 0.25)
    static let badgeText = Color(white: 0.8)
    static let metaText = Color(white: 0.55)
    static let copiedBg = Color(red: 0.204, green: 0.78, blue: 0.349).opacity(0.2)
    static let copiedText = Color(red: 0.204, green: 0.78, blue: 0.349)
}

// MARK: - Language Display Names

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
    "xml": "XML", "markdown": "Markdown", "md": "Markdown",
    "text": "Text", "txt": "Text", "r": "R",
    "dart": "Dart", "lua": "Lua", "perl": "Perl",
    "scala": "Scala", "groovy": "Groovy", "haskell": "Haskell",
    "objective-c": "Objective-C", "objc": "Objective-C",
    "dockerfile": "Dockerfile", "docker": "Docker",
    "graphql": "GraphQL", "gql": "GraphQL",
    "powershell": "PowerShell", "ps1": "PowerShell"
]

// MARK: - Block Types

private enum MDBlock: Identifiable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(language: String, code: String)
    case table(headers: [String], rows: [[String]], colWidths: [CGFloat])
    case bulletList(items: [String])
    case numberedList(items: [String])
    case blockquote(text: String)
    case horizontalRule
    case empty

    var id: String {
        switch self {
        case .heading(_, let t): return "h_\(t.prefix(20))"
        case .paragraph(let t): return "p_\(t.prefix(20))"
        case .codeBlock(let l, let c): return "cb_\(l)_\(c.prefix(20))"
        case .table(let h, _, _): return "t_\(h.joined())"
        case .bulletList(let items): return "bl_\(items.count)"
        case .numberedList(let items): return "nl_\(items.count)"
        case .blockquote(let t): return "bq_\(t.prefix(20))"
        case .horizontalRule: return "hr"
        case .empty: return "empty"
        }
    }
}

// MARK: - Main View

struct MarkdownTextView: View {
    let content: String

    var body: some View {
        if content.count < 100
            && !content.contains("```")
            && !content.contains("#")
            && !content.contains("|") {
            Text(content)
                .font(.system(size: 15))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        } else if content.count > 8000 {
            let truncated = String(content.prefix(8000)) + "\n\n[Content truncated for performance...]"
            MarkdownBlocksView(blocks: MDParser.parseBlocks(truncated))
        } else {
            MarkdownBlocksView(blocks: MDParser.parseBlocks(content))
        }
    }
}

// MARK: - Blocks Renderer

private struct MarkdownBlocksView: View {
    let blocks: [MDBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                MDBlockView(block: block)
            }
        }
    }
}

// MARK: - Single Block Router

private struct MDBlockView: View {
    let block: MDBlock

    var body: some View {
        switch block {
        case .heading(let level, let text):
            MDHeadingView(level: level, text: text)
        case .paragraph(let text):
            MDRichText(text)
                .fixedSize(horizontal: false, vertical: true)
        case .codeBlock(let lang, let code):
            MDCodeBlockView(language: lang, code: code)
        case .table(let headers, let rows, let widths):
            MDTableView(headers: headers, rows: rows, colWidths: widths)
        case .bulletList(let items):
            MDBulletListView(items: items)
        case .numberedList(let items):
            MDNumberedListView(items: items)
        case .blockquote(let text):
            MDBlockquoteView(text: text)
        case .horizontalRule:
            Divider().padding(.vertical, 6)
        case .empty:
            EmptyView()
        }
    }
}

// MARK: - Heading

private struct MDHeadingView: View {
    let level: Int
    let text: String

    private var fontSize: CGFloat {
        switch level {
        case 1: return 24
        case 2: return 20
        case 3: return 17
        case 4: return 16
        default: return 15
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MDRichText(text)
                .font(.system(size: fontSize, weight: level <= 2 ? .bold : .semibold))
            if level <= 2 {
                Divider().opacity(0.5)
            }
        }
        .padding(.top, level <= 2 ? 12 : 6)
        .padding(.bottom, 2)
    }
}

// MARK: - Code Block (dark theme, line numbers, syntax highlight, copy, collapse)

private struct MDCodeBlockView: View {
    let language: String
    let code: String

    @State private var copied = false
    @State private var collapsed = false

    private var lines: [String] { code.components(separatedBy: "\n") }
    private var lineCount: Int { lines.count }
    private var isLong: Bool { lineCount > 15 }
    private var displayLang: String {
        languageNames[language.lowercased()] ?? (language.isEmpty ? "Code" : language)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar
            codeContent
            if collapsed && isLong {
                expandButton
            }
        }
        .background(MDColors.codeBlockBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var headerBar: some View {
        HStack {
            HStack(spacing: 8) {
                Text(displayLang)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(MDColors.badgeText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MDColors.badgeBg)
                    .cornerRadius(4)

                Text("\(lineCount) line\(lineCount == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundColor(MDColors.metaText)
            }
            Spacer()
            HStack(spacing: 4) {
                if isLong {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { collapsed.toggle() }
                    } label: {
                        Image(systemName: collapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 12))
                            .foregroundColor(MDColors.metaText)
                    }
                    .frame(width: 28, height: 28)
                }
                Button {
                    UIPasteboard.general.string = code
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                        if copied {
                            Text("Copied!")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .foregroundColor(copied ? MDColors.copiedText : MDColors.badgeText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(copied ? MDColors.copiedBg : MDColors.badgeBg)
                    .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(MDColors.codeHeaderBg)
    }

    private var codeContent: some View {
        let displayLines = collapsed && isLong ? Array(lines.prefix(5)) : lines
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(displayLines.indices, id: \.self) { idx in
                        Text("\(idx + 1)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(MDColors.lineNumber)
                            .frame(height: 20)
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, 12)

                Rectangle()
                    .fill(MDColors.codeSeparator)
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(displayLines.indices, id: \.self) { idx in
                        syntaxHighlightedLine(displayLines[idx])
                            .frame(height: 20, alignment: .leading)
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 10)
        }
    }

    private var expandButton: some View {
        Button {
            withAnimation { collapsed = false }
        } label: {
            Text("Click to expand (\(lineCount - 5) more lines)")
                .font(.system(size: 11))
                .foregroundColor(MDColors.metaText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(MDColors.codeHeaderBg)
        }
    }

    private func syntaxHighlightedLine(_ line: String) -> Text {
        guard line.count <= 500 else {
            return Text(line)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(MDColors.codeBlockText)
        }

        let keywords = MDSyntax.keywords(for: language)
        var result = Text("")
        var remaining = line[line.startIndex...]

        var safety = 0
        while !remaining.isEmpty && safety < line.count + 10 {
            safety += 1
            var matched = false

            // String literal (double quotes)
            if remaining.first == "\"" {
                if let end = MDSyntax.findClosingQuote(remaining, quote: "\"") {
                    let s = String(remaining[remaining.startIndex...end])
                    result = result + Text(s).font(.system(size: 12, design: .monospaced)).foregroundColor(MDColors.string)
                    remaining = remaining[remaining.index(after: end)...]
                    continue
                }
            }
            // String literal (single quotes)
            if remaining.first == "'" {
                if let end = MDSyntax.findClosingQuote(remaining, quote: "'") {
                    let s = String(remaining[remaining.startIndex...end])
                    result = result + Text(s).font(.system(size: 12, design: .monospaced)).foregroundColor(MDColors.string)
                    remaining = remaining[remaining.index(after: end)...]
                    continue
                }
            }

            // Comment (// or # at start)
            let trimmedRemaining = remaining.drop(while: { $0 == " " || $0 == "\t" })
            if (remaining.hasPrefix("//") || (remaining.hasPrefix("#") && !remaining.hasPrefix("#!"))) && trimmedRemaining.hasPrefix(remaining.prefix(1)) {
                let s = String(remaining)
                result = result + Text(s).font(.system(size: 12, design: .monospaced)).foregroundColor(MDColors.comment).italic()
                return result
            }

            // Numbers
            if let ch = remaining.first, ch.isNumber {
                var numStr = ""
                var idx = remaining.startIndex
                while idx < remaining.endIndex && (remaining[idx].isNumber || remaining[idx] == ".") {
                    numStr.append(remaining[idx])
                    idx = remaining.index(after: idx)
                }
                result = result + Text(numStr).font(.system(size: 12, design: .monospaced)).foregroundColor(MDColors.number)
                remaining = remaining[idx...]
                continue
            }

            // Keywords & identifiers
            if let ch = remaining.first, ch.isLetter || ch == "_" {
                var word = ""
                var idx = remaining.startIndex
                while idx < remaining.endIndex && (remaining[idx].isLetter || remaining[idx].isNumber || remaining[idx] == "_") {
                    word.append(remaining[idx])
                    idx = remaining.index(after: idx)
                }
                let isKeyword = keywords.contains(word)
                let isFunc = idx < remaining.endIndex && remaining[idx] == "("
                let color: Color = isKeyword ? MDColors.keyword : (isFunc ? MDColors.function : MDColors.codeBlockText)
                let weight: Font.Weight = isKeyword ? .medium : .regular
                result = result + Text(word).font(.system(size: 12, weight: weight, design: .monospaced)).foregroundColor(color)
                remaining = remaining[idx...]
                continue
            }

            // Default character
            let ch = String(remaining.prefix(1))
            result = result + Text(ch).font(.system(size: 12, design: .monospaced)).foregroundColor(MDColors.codeBlockText)
            remaining = remaining.dropFirst(1)
        }

        return result
    }
}

// MARK: - Table (dynamic widths, scroll, alternating rows, styled headers)

private struct MDTableView: View {
    let headers: [String]
    let rows: [[String]]
    let colWidths: [CGFloat]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
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
                        .background(rowIdx % 2 == 0
                                    ? Color(UIColor.systemBackground)
                                    : Color(UIColor.secondarySystemBackground).opacity(0.4))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(MDColors.tableBorder, lineWidth: 1)
                )
            }

            if headers.count > 2 {
                Text("\u{2190} Swipe to see more \u{2192}")
                    .font(.system(size: 11))
                    .italic()
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color(UIColor.tertiarySystemBackground))
            }
        }
        .cornerRadius(12)
    }
}

// MARK: - Bullet List

private struct MDBulletListView: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(items.indices, id: \.self) { idx in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\u{2022}")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(MDColors.bulletColor)
                    MDRichText(items[idx])
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.leading, 4)
    }
}

// MARK: - Numbered List

private struct MDNumberedListView: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(items.indices, id: \.self) { idx in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(idx + 1).")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MDColors.bulletColor)
                        .frame(width: 24, alignment: .trailing)
                    MDRichText(items[idx])
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.leading, 4)
    }
}

// MARK: - Blockquote

private struct MDBlockquoteView: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(MDColors.blockquoteBorder)
                .frame(width: 3)
            MDRichText(text)
                .italic()
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .padding(.vertical, 2)
        .background(MDColors.blockquoteBg)
        .cornerRadius(6)
    }
}

// MARK: - Inline Rich Text (bold, italic, bold-italic, strikethrough, inline code, links, citations)

private struct MDRichText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        parse(text)
            .font(.system(size: 15))
            .lineSpacing(3)
    }

    private func parse(_ input: String) -> Text {
        var result = Text("")
        var remaining = input[input.startIndex...]

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
                let delimiter = String(remaining.prefix(1))
                let afterDelim = remaining.dropFirst(1)
                if let ch = afterDelim.first, !ch.isWhitespace {
                    if let end = afterDelim.range(of: delimiter) {
                        let s = String(afterDelim[afterDelim.startIndex..<end.lowerBound])
                        if !s.isEmpty && !s.contains("\n") {
                            result = result + Text(s).italic()
                            remaining = afterDelim[end.upperBound...]
                            continue
                        }
                    }
                }
                result = result + Text(delimiter)
                remaining = remaining.dropFirst(1)
                continue
            }
            // Inline code `text`
            if remaining.hasPrefix("`") {
                let afterTick = remaining.dropFirst(1)
                if let end = afterTick.firstIndex(of: "`") {
                    let s = String(afterTick[afterTick.startIndex..<end])
                    result = result + Text(" \(s) ")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(MDColors.inlineCodeText)
                    remaining = afterTick[afterTick.index(after: end)...]
                    continue
                }
                result = result + Text("`")
                remaining = remaining.dropFirst(1)
                continue
            }
            // Link [text](url)
            if remaining.hasPrefix("[") {
                let sub = String(remaining)
                if let bracketEnd = sub.firstIndex(of: "]") {
                    let afterBracket = sub.index(after: bracketEnd)
                    if afterBracket < sub.endIndex && sub[afterBracket] == "(" {
                        if let parenEnd = sub[afterBracket...].firstIndex(of: ")") {
                            let linkText = String(sub[sub.index(after: sub.startIndex)..<bracketEnd])
                            result = result + Text(linkText)
                                .foregroundColor(MDColors.link)
                                .underline()
                            let advance = sub.distance(from: sub.startIndex, to: sub.index(after: parenEnd))
                            remaining = remaining.dropFirst(advance)
                            continue
                        }
                    }
                    // Citation like [1]
                    let content = String(sub[sub.index(after: sub.startIndex)..<bracketEnd])
                    if content.allSatisfy({ $0.isNumber }) && content.count <= 3 {
                        result = result + Text("[\(content)]")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(MDColors.link)
                            .baselineOffset(4)
                        let advance = sub.distance(from: sub.startIndex, to: sub.index(after: bracketEnd))
                        remaining = remaining.dropFirst(advance)
                        continue
                    }
                }
                result = result + Text("[")
                remaining = remaining.dropFirst(1)
                continue
            }
            // Superscript unicode characters
            if let ch = remaining.first, "\u{00B9}\u{00B2}\u{00B3}\u{2074}\u{2075}\u{2076}\u{2077}\u{2078}\u{2079}\u{2070}".contains(ch) {
                result = result + Text(String(ch))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(MDColors.link)
                remaining = remaining.dropFirst(1)
                continue
            }
            // Plain text segment
            var plain = ""
            while !remaining.isEmpty {
                let ch = remaining[remaining.startIndex]
                if ch == "*" || ch == "_" || ch == "`" || ch == "~" || ch == "[" { break }
                if "\u{00B9}\u{00B2}\u{00B3}\u{2074}\u{2075}\u{2076}\u{2077}\u{2078}\u{2079}\u{2070}".contains(ch) { break }
                plain.append(ch)
                remaining = remaining.dropFirst(1)
            }
            if !plain.isEmpty {
                result = result + Text(plain)
            }
        }
        return result
    }
}

// MARK: - Parser

private enum MDParser {
    static func parseBlocks(_ text: String) -> [MDBlock] {
        var blocks: [MDBlock] = []
        let lines = text.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let raw = lines[i]
            let trimmed = raw.trimmingCharacters(in: .whitespaces)

            // Empty line
            if trimmed.isEmpty {
                i += 1
                continue
            }

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

            // Horizontal rule
            if trimmed == "---" || trimmed == "***" || trimmed == "___" ||
                (trimmed.count >= 3 && trimmed.allSatisfy({ $0 == "-" || $0 == " " }) && trimmed.contains("-")) {
                blocks.append(.horizontalRule)
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
            if trimmed.range(of: #"^\d+[\.\)]\s"#, options: .regularExpression) != nil {
                var items: [String] = []
                while i < lines.count {
                    let ol = lines[i].trimmingCharacters(in: .whitespaces)
                    if let r = ol.range(of: #"^\d+[\.\)]\s"#, options: .regularExpression) {
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

            // Paragraph (collect contiguous non-special lines)
            var para: [String] = []
            while i < lines.count {
                let pl = lines[i].trimmingCharacters(in: .whitespaces)
                if pl.isEmpty || pl.hasPrefix("#") || pl.hasPrefix("```")
                    || (pl.hasPrefix("|") && pl.hasSuffix("|"))
                    || pl.hasPrefix("- ") || pl.hasPrefix("* ") || pl.hasPrefix("+ ")
                    || pl.hasPrefix("> ") || pl == "---" || pl == "***" || pl == "___"
                    || pl.range(of: #"^\d+[\.\)]\s"#, options: .regularExpression) != nil { break }
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
        for ch in line {
            if ch == "#" { level += 1 } else { break }
        }
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
            if !cells.isEmpty && !cells.allSatisfy({ $0.contains("---") || $0.contains(":--") || $0.contains("--:") }) {
                rows.append(cells)
            }
        }

        let colCount = headers.count
        var widths: [CGFloat] = Array(repeating: 0, count: colCount)
        for col in 0..<colCount {
            let headerLen = headers[safe: col]?.count ?? 0
            let maxDataLen = rows.map { $0[safe: col]?.count ?? 0 }.max() ?? 0
            let maxLen = max(headerLen, maxDataLen)
            widths[col] = switch maxLen {
            case 0...5: 80
            case 6...10: 110
            case 11...18: 145
            case 19...28: 180
            case 29...40: 220
            default: 260
            }
        }
        return .table(headers: headers, rows: rows, colWidths: widths)
    }
}

// MARK: - Syntax Highlighting Helper

private enum MDSyntax {
    static func keywords(for language: String) -> Set<String> {
        switch language.lowercased() {
        case "javascript", "js", "typescript", "ts":
            return ["const", "let", "var", "function", "return", "if", "else", "for", "while",
                    "class", "import", "export", "from", "async", "await", "try", "catch",
                    "throw", "new", "this", "true", "false", "null", "undefined", "typeof",
                    "interface", "type", "enum", "implements", "extends", "public", "private",
                    "protected", "switch", "case", "break", "default", "continue", "do", "of", "in"]
        case "python", "py":
            return ["def", "class", "return", "if", "elif", "else", "for", "while", "import",
                    "from", "as", "try", "except", "raise", "with", "True", "False", "None",
                    "and", "or", "not", "in", "is", "lambda", "yield", "async", "await", "self",
                    "pass", "break", "continue", "global", "nonlocal", "del", "assert"]
        case "swift":
            return ["func", "var", "let", "class", "struct", "enum", "protocol", "extension",
                    "import", "return", "if", "else", "for", "while", "switch", "case", "break",
                    "guard", "self", "Self", "true", "false", "nil", "throws", "throw", "try",
                    "catch", "async", "await", "private", "public", "internal", "fileprivate",
                    "open", "static", "override", "init", "deinit", "typealias", "where", "in",
                    "some", "any", "mutating", "weak", "unowned", "lazy", "final"]
        case "java", "kotlin", "kt":
            return ["public", "private", "protected", "class", "interface", "extends", "implements",
                    "return", "if", "else", "for", "while", "try", "catch", "throw", "new",
                    "this", "true", "false", "null", "void", "int", "String", "boolean",
                    "static", "final", "fun", "val", "var", "when", "data", "object", "companion",
                    "sealed", "suspend", "override", "abstract", "package", "import"]
        case "sql":
            return ["SELECT", "FROM", "WHERE", "JOIN", "LEFT", "RIGHT", "INNER", "OUTER", "ON",
                    "AND", "OR", "NOT", "IN", "LIKE", "ORDER", "BY", "GROUP", "HAVING",
                    "INSERT", "UPDATE", "DELETE", "CREATE", "TABLE", "DROP", "ALTER", "INDEX",
                    "NULL", "AS", "DISTINCT", "LIMIT", "OFFSET", "SET", "VALUES", "INTO", "BETWEEN",
                    "EXISTS", "UNION", "ALL", "COUNT", "SUM", "AVG", "MAX", "MIN", "CASE", "WHEN", "THEN", "END"]
        case "bash", "shell", "sh":
            return ["if", "then", "else", "elif", "fi", "for", "do", "done", "while", "case",
                    "esac", "function", "return", "echo", "exit", "export", "source", "cd", "ls",
                    "rm", "mkdir", "cp", "mv", "grep", "awk", "sed", "cat", "chmod", "chown"]
        case "html":
            return ["html", "head", "body", "div", "span", "p", "a", "img", "input", "button",
                    "form", "table", "tr", "td", "th", "ul", "ol", "li", "h1", "h2", "h3",
                    "script", "style", "link", "meta", "title", "class", "id", "src", "href"]
        case "css", "scss":
            return ["display", "position", "flex", "grid", "margin", "padding", "border",
                    "color", "background", "font", "width", "height", "top", "left", "right",
                    "bottom", "none", "block", "inline", "relative", "absolute", "fixed",
                    "important", "var", "calc", "auto", "inherit", "transparent"]
        case "go":
            return ["func", "package", "import", "var", "const", "type", "struct", "interface",
                    "return", "if", "else", "for", "range", "switch", "case", "break", "default",
                    "go", "defer", "chan", "select", "map", "make", "new", "nil", "true", "false",
                    "error", "string", "int", "bool", "byte", "float64"]
        case "rust":
            return ["fn", "let", "mut", "const", "struct", "enum", "impl", "trait", "pub",
                    "use", "mod", "crate", "self", "super", "return", "if", "else", "for",
                    "while", "loop", "match", "break", "continue", "move", "async", "await",
                    "true", "false", "Some", "None", "Ok", "Err", "Box", "Vec", "String",
                    "Option", "Result", "where", "type", "unsafe"]
        default:
            return ["if", "else", "for", "while", "return", "function", "class", "import",
                    "true", "false", "null", "new", "this", "try", "catch", "var", "let", "const"]
        }
    }

    static func findClosingQuote(_ text: Substring, quote: Character) -> String.Index? {
        guard text.first == quote else { return nil }
        var idx = text.index(after: text.startIndex)
        while idx < text.endIndex {
            if text[idx] == "\\" {
                idx = text.index(after: idx)
                if idx < text.endIndex { idx = text.index(after: idx) }
                continue
            }
            if text[idx] == quote { return idx }
            idx = text.index(after: idx)
        }
        return nil
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
