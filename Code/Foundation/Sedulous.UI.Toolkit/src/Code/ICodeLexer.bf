using System;
using System.Collections;

namespace Sedulous.UI.Toolkit;

/// Lexes ONE LINE at a time, given the state the previous line left behind.
///
/// Line at a time, because a code editor's highlighting has to be incremental: re-lexing a whole
/// file on every keystroke does not scale, and a line's colouring depends on nothing but the
/// carried state. State nought is "nothing open"; everything else is the lexer's own business,
/// so a block comment or a long string can carry its depth in the upper bits without anyone
/// else knowing.
///
/// THE CONTRACT: every visible character must be covered by a token, because the renderer draws
/// tokens and nothing else. Whitespace may be skipped.
interface ICodeLexer
{
	/// Appends this line's tokens and returns the state the NEXT line starts in.
	uint32 LexLine(StringView line, uint32 entryState, List<CodeToken> outTokens);

	/// What starts a line comment, for the comment toggle. Empty disables it, which is what a
	/// language with only block comments wants.
	StringView LineCommentPrefix => "//";
}
