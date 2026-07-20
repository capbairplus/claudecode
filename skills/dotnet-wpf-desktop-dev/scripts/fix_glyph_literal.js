// Fixes a Segoe MDL2/Fluent icon glyph literal in a .cs file that got
// silently stripped to "" (or swapped to the wrong glyph) by the Edit/Write
// tool pipeline. See SKILL.md section 1 for background.
//
// Usage:
//   node fix_glyph_literal.js <path-to-cs-file> <line-number-1-indexed> <hex-codepoint>
//
// Example - fix line 42 of MainWindow.xaml.cs to contain the Play glyph (E768):
//   node fix_glyph_literal.js MainWindow.xaml.cs 42 E768
//
// This only touches the FIRST quoted string literal found on that line, and
// replaces its contents with the correct \uXXXX escape sequence (built from
// character codes so this script's own source never contains a literal
// backslash-u sequence for the tool pipeline to mis-handle).

const fs = require('fs');

const [, , filePath, lineArg, hexCode] = process.argv;

if (!filePath || !lineArg || !hexCode) {
  console.error('Usage: node fix_glyph_literal.js <file> <line-number> <hex-codepoint>');
  process.exit(1);
}

const lineIndex = parseInt(lineArg, 10) - 1;
const lines = fs.readFileSync(filePath, 'utf8').split('\n');

if (lineIndex < 0 || lineIndex >= lines.length) {
  console.error(`Line ${lineArg} is out of range (file has ${lines.length} lines).`);
  process.exit(1);
}

const line = lines[lineIndex];
const quoteMatch = line.match(/"[^"]*"/);
if (!quoteMatch) {
  console.error('No quoted string literal found on that line. Nothing changed.');
  console.error('Line content:', JSON.stringify(line));
  process.exit(1);
}

const backslash = String.fromCharCode(92);
const escapeSeq = `${backslash}u${hexCode.toUpperCase()}`;
const replacement = `"${escapeSeq}"`;

const before = line;
const after = line.slice(0, quoteMatch.index) + replacement + line.slice(quoteMatch.index + quoteMatch[0].length);

lines[lineIndex] = after;
fs.writeFileSync(filePath, lines.join('\n'), 'utf8');

console.log('before:', JSON.stringify(before));
console.log('after: ', JSON.stringify(after));
