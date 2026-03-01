//
//  MarkdownTextView.swift
//  BaatCheet
//
//  Rich markdown rendering for AI chat responses
//

import SwiftUI

struct MarkdownTextView: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let blocks = parseBlocks(content)
            ForEach(blocks.indices, id: \.self) { index in
                renderBlock(blocks[index])
            }
        }
    }
    
    // MARK: - Block Parsing

    private enum Block {
        case heading(level: Int, text: String)
        case codeBlock(language: String, code: String)
        case table(headers: [String], rows: [[String]])
        case orderedList(items: [String])
        case unorderedList(items: [String])
        case blockquote(text: String)
        case horizontalRule
        case paragraph(text: String)
    }
    
    private func parseBlocks(_ text: String) -> [Block] {
        var blocks: [Block] = []
        let lines = text.components(separatedBy: "\n")
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
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
            
            if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
                var tableLines: [String] = []
                while i < lines.count {
                    let tl = lines[i].trimmingCharacters(in: .whitespaces)
                    guard tl.hasPrefix("|") && tl.hasSuffix("|") else { break }
                    tableLines.append(tl)
                    i += 1
                }
                if let table = parseTable(tableLines) {
                    blocks.append(table)
                }
                continue
            }
            
            if let headingLevel = headingLevel(trimmed) {
                let text = String(trimmed.drop(while: { $0 == "#" })).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(level: headingLevel, text: text))
                i += 1
                continue
            }
            
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
                blocks.append(.unorderedList(items: items))
                continue
            }
            
            if let _ = trimmed.range(of: #"^\d+[\.\)] "#, options: .regularExpression) {
                var items: [String] = []
                while i < lines.count {
                    let ol = lines[i].trimmingCharacters(in: .whitespaces)
                    if let range = ol.range(of: #"^\d+[\.\)] "#, options: .regularExpression) {
                        items.append(String(ol[range.upperBound...]))
                        i += 1
                    } else if ol.hasPrefix("  ") && !items.isEmpty {
                        items[items.count - 1] += " " + ol.trimmingCharacters(in: .whitespaces)
                        i += 1
                    } else { break }
                }
                blocks.append(.orderedList(items: items))
                continue
            }
            
            if trimmed.hasPrefix("> ") {
                var quoteLines: [String] = []
                while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("> ") {
                    quoteLines.append(String(lines[i].trimmingCharacters(in: .whitespaces).dropFirst(2)))
                    i += 1
                }
                blocks.append(.blockquote(text: quoteLines.joined(separator: "\n")))
                continue
            }
            
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                blocks.append(.horizontalRule)
                i += 1
                continue
            }
            
            if trimmed.isEmpty {
                i += 1
                continue
            }
            
            var paraLines: [String] = []
            while i < lines.count {
                let pl = lines[i].trimmingCharacters(in: .whitespaces)
                if pl.isEmpty || pl.hasPrefix("#") || pl.hasPrefix("```") || pl.hasPrefix("|") ||
                    pl.hasPrefix("- ") || pl.hasPrefix("* ") || pl.hasPrefix("+ ") ||
                    pl.hasPrefix("> ") || pl == "---" || pl == "***" || pl == "___" ||
                    pl.range(of: #"^\d+[\.\)] "#, options: .regularExpression) != nil {
                    break
                }
                paraLines.append(lines[i])
                i += 1
            }
            if !paraLines.isEmpty {
                blocks.append(.paragraph(text: paraLines.joined(separator: "\n")))
            }
        }
        
        return blocks
    }
    
    private func headingLevel(_ line: String) -> Int? {
        guard line.hasPrefix("#") else { return nil }
        var level = 0
        for ch in line {
            if ch == "#" { level += 1 } else { break }
        }
        guard level >= 1 && level <= 6, line.count > level,
              line[line.index(line.startIndex, offsetBy: level)] == " " else { return nil }
        return level
    }
    
    private func parseTable(_ lines: [String]) -> Block? {
        guard lines.count >= 2 else { return nil }
        
        func splitRow(_ row: String) -> [String] {
            row.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        
        let headers = splitRow(lines[0])
        guard !headers.isEmpty else { return nil }
        
        let startRow = (lines.count > 1 && lines[1].contains("---")) ? 2 : 1
        var rows: [[String]] = []
        for idx in startRow..<lines.count {
            let cells = splitRow(lines[idx])
            if !cells.isEmpty {
                rows.append(cells)
            }
        }
        
        return .table(headers: headers, rows: rows)
    }
    
    // MARK: - Block Rendering
    
    @ViewBuilder
    private func renderBlock(_ block: Block) -> some View {
        switch block {
        case .heading(let level, let text):
            headingView(level: level, text: text)
                .padding(.top, level <= 2 ? 12 : 8)
                .padding(.bottom, 4)
        case .codeBlock(let language, let code):
            codeBlockView(language: language, code: code)
                .padding(.vertical, 6)
        case .table(let headers, let rows):
            tableView(headers: headers, rows: rows)
                .padding(.vertical, 6)
        case .orderedList(let items):
            orderedListView(items: items)
                .padding(.vertical, 4)
        case .unorderedList(let items):
            unorderedListView(items: items)
                .padding(.vertical, 4)
        case .blockquote(let text):
            blockquoteView(text: text)
                .padding(.vertical, 4)
        case .horizontalRule:
            Divider().padding(.vertical, 8)
        case .paragraph(let text):
            inlineRichText(text)
                .padding(.vertical, 3)
        }
    }
    
    private func headingView(level: Int, text: String) -> some View {
        let size: CGFloat = [24, 20, 18, 16, 15, 14][min(level - 1, 5)]
        let weight: Font.Weight = level <= 2 ? .bold : .semibold
        return Text(text)
            .font(.system(size: size, weight: weight))
            .foregroundColor(.primary)
    }
    
    private func codeBlockView(language: String, code: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !language.isEmpty {
                HStack {
                    Text(language.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { UIPasteboard.general.string = code }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 11))
                            Text("Copy")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGray5))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .padding(12)
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func tableView(headers: [String], rows: [[String]]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(headers.indices, id: \.self) { col in
                        Text(headers[col])
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(minWidth: 80, alignment: .leading)
                        if col < headers.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(Color.bcPrimary.opacity(0.08))
                
                Divider()
                
                ForEach(rows.indices, id: \.self) { rowIdx in
                    HStack(spacing: 0) {
                        ForEach(0..<max(headers.count, rows[rowIdx].count), id: \.self) { col in
                            Text(col < rows[rowIdx].count ? rows[rowIdx][col] : "")
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(minWidth: 80, alignment: .leading)
                            if col < max(headers.count, rows[rowIdx].count) - 1 {
                                Divider()
                            }
                        }
                    }
                    .background(rowIdx % 2 == 0 ? Color.clear : Color(UIColor.secondarySystemBackground).opacity(0.5))
                    
                    if rowIdx < rows.count - 1 {
                        Divider()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(UIColor.separator), lineWidth: 0.5)
            )
            .cornerRadius(10)
        }
    }
    
    private func orderedListView(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items.indices, id: \.self) { idx in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(idx + 1).")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.bcPrimary)
                        .frame(width: 22, alignment: .trailing)
                    inlineRichText(items[idx])
                }
            }
        }
        .padding(.leading, 4)
    }
    
    private func unorderedListView(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items.indices, id: \.self) { idx in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.bcPrimary)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    inlineRichText(items[idx])
                }
            }
        }
        .padding(.leading, 4)
    }
    
    private func blockquoteView(text: String) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.bcPrimary)
                .frame(width: 3)
            
            inlineRichText(text)
                .italic()
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .background(Color.bcPrimary.opacity(0.04))
        .cornerRadius(6)
    }
    
    // MARK: - Inline Rich Text

    private func inlineRichText(_ text: String) -> Text {
        var result = Text("")
        var remaining = text[text.startIndex...]
        
        while !remaining.isEmpty {
            if remaining.hasPrefix("**") || remaining.hasPrefix("__") {
                let delim = String(remaining.prefix(2))
                remaining = remaining.dropFirst(2)
                if let end = remaining.range(of: delim) {
                    let bold = String(remaining[remaining.startIndex..<end.lowerBound])
                    result = result + Text(bold).bold()
                    remaining = remaining[end.upperBound...]
                    continue
                } else {
                    result = result + Text(delim)
                    continue
                }
            }
            
            if remaining.hasPrefix("*") || remaining.hasPrefix("_") {
                let delim = String(remaining.prefix(1))
                remaining = remaining.dropFirst(1)
                if let end = remaining.range(of: delim) {
                    let italic = String(remaining[remaining.startIndex..<end.lowerBound])
                    result = result + Text(italic).italic()
                    remaining = remaining[end.upperBound...]
                    continue
                } else {
                    result = result + Text(delim)
                    continue
                }
            }
            
            if remaining.hasPrefix("`") {
                remaining = remaining.dropFirst(1)
                if let end = remaining.firstIndex(of: "`") {
                    let code = String(remaining[remaining.startIndex..<end])
                    result = result + Text(code)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                    remaining = remaining[remaining.index(after: end)...]
                    continue
                } else {
                    result = result + Text("`")
                    continue
                }
            }
            
            var plain = ""
            while !remaining.isEmpty {
                let ch = remaining[remaining.startIndex]
                if ch == "*" || ch == "_" || ch == "`" { break }
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
}
