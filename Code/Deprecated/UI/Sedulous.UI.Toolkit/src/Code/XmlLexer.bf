using System;
using System.Collections;

namespace Sedulous.UI.Toolkit;

/// The lexer for markup: UI documents, scene files, anything angle bracketed.
///
/// A pure STATE MACHINE, because markup's meaning depends entirely on where you are: the same
/// characters are text outside a tag, an attribute inside one, and nothing at all inside a
/// comment. The mode IS the carried state, with no depth to pack alongside it.
class XmlLexer : ICodeLexer
{
	private const uint32 ModeText = 0;
	private const uint32 ModeInTag = 1;
	private const uint32 ModeComment = 2;
	private const uint32 ModeCData = 3;
	private const uint32 ModeDeclaration = 4;
	private const uint32 ModeDoubleQuote = 5;
	private const uint32 ModeSingleQuote = 6;

	/// EMPTY: markup has only block comments, so there is nothing for a comment toggle to
	/// insert and the toggle disables itself.
	public StringView LineCommentPrefix => "";

	public uint32 LexLine(StringView line, uint32 entryState, List<CodeToken> outTokens)
	{
		var cursor = LexerCursor(line);
		var mode = entryState;
		var runBegin = 0;
		int32 runColumn = 0;

		while (!cursor.AtEnd)
		{
			switch (mode)
			{
			case ModeText:
				LexText(ref cursor, outTokens, ref mode, ref runBegin, ref runColumn);
			case ModeInTag:
				LexInsideTag(ref cursor, outTokens, ref mode, ref runBegin, ref runColumn);
			case ModeComment:
				LexUntil(ref cursor, outTokens, "-->", .Comment, ref mode, ref runBegin,
					ref runColumn);
			case ModeCData:
				LexUntil(ref cursor, outTokens, "]]>", .String, ref mode, ref runBegin,
					ref runColumn);
			case ModeDeclaration:
				LexUntil(ref cursor, outTokens, "?>", .Preprocessor, ref mode, ref runBegin,
					ref runColumn);
			case ModeDoubleQuote, ModeSingleQuote:
				LexAttributeValue(ref cursor, outTokens, ref mode, runBegin, runColumn);
			default:
				cursor.Advance();
			}
		}

		FlushOpenRun(outTokens, line, mode, runBegin, runColumn);
		return mode;
	}

	private void LexText(ref LexerCursor cursor, List<CodeToken> outTokens, ref uint32 mode,
		ref int runBegin, ref int32 runColumn)
	{
		if (cursor.Peek() != '<')
		{
			// Plain content runs to the next angle bracket as ONE token, because the renderer
			// draws only tokens and text left uncovered would not appear at all.
			runBegin = cursor.Index;
			runColumn = cursor.Column;
			while (!cursor.AtEnd && (cursor.Peek() != '<'))
				cursor.Advance();

			LexerScan.Emit(outTokens, runBegin, cursor.Index, runColumn, .Default);
			return;
		}

		// The three special openers are tested BEFORE a plain tag, since each begins with the
		// same bracket.
		if (EnterOn(ref cursor, "<!--", ModeComment, ref mode, ref runBegin, ref runColumn))
			return;
		if (EnterOn(ref cursor, "<![CDATA[", ModeCData, ref mode, ref runBegin, ref runColumn))
			return;
		if (EnterOn(ref cursor, "<?", ModeDeclaration, ref mode, ref runBegin, ref runColumn))
			return;

		LexTagOpen(ref cursor, outTokens, ref mode, ref runBegin, ref runColumn);
	}

	private bool EnterOn(ref LexerCursor cursor, StringView opener, uint32 nextMode,
		ref uint32 mode, ref int runBegin, ref int32 runColumn)
	{
		if (!cursor.Match(opener))
			return false;

		runBegin = cursor.Index;
		runColumn = cursor.Column;
		for (int k = 0; k < opener.Length; k++)
			cursor.Advance();

		mode = nextMode;
		return true;
	}

	/// The bracket, with its slash when closing, then the element NAME as its own token, so a
	/// theme can colour the name without the punctuation around it.
	private void LexTagOpen(ref LexerCursor cursor, List<CodeToken> outTokens, ref uint32 mode,
		ref int runBegin, ref int32 runColumn)
	{
		runBegin = cursor.Index;
		runColumn = cursor.Column;
		cursor.Advance();
		if (cursor.Peek() == '/')
			cursor.Advance();

		LexerScan.Emit(outTokens, runBegin, cursor.Index, runColumn, .Punctuation);

		runBegin = cursor.Index;
		runColumn = cursor.Column;
		ScanName(ref cursor);
		LexerScan.Emit(outTokens, runBegin, cursor.Index, runColumn, .Tag);
		mode = ModeInTag;
	}

	/// A name may carry colons and hyphens, which a plain identifier scan would stop at and
	/// namespaced markup is full of.
	private static void ScanName(ref LexerCursor cursor)
	{
		while (!cursor.AtEnd && (LexerScan.IsIdentChar(cursor.Peek()) || (cursor.Peek() == ':')
			|| (cursor.Peek() == '-')))
			cursor.Advance();
	}

	private void LexInsideTag(ref LexerCursor cursor, List<CodeToken> outTokens, ref uint32 mode,
		ref int runBegin, ref int32 runColumn)
	{
		let c = cursor.Peek();

		if (LexerScan.IsSpace(c))
		{
			cursor.Advance();
			return;
		}

		// The self closing form is tested first, since it starts with a character that is
		// otherwise an ordinary one.
		if (cursor.Match("/>"))
		{
			EmitGlyphs(ref cursor, outTokens, 2, .Punctuation, ref runBegin, ref runColumn);
			mode = ModeText;
			return;
		}

		if (c == '>')
		{
			EmitGlyphs(ref cursor, outTokens, 1, .Punctuation, ref runBegin, ref runColumn);
			mode = ModeText;
			return;
		}

		if (c == '=')
		{
			EmitGlyphs(ref cursor, outTokens, 1, .Operator, ref runBegin, ref runColumn);
			return;
		}

		if ((c == '"') || (c == '\''))
		{
			// The value's run starts at the QUOTE and is emitted when the closing one arrives,
			// or at the end of the line, so an unterminated value still colours.
			runBegin = cursor.Index;
			runColumn = cursor.Column;
			cursor.Advance();
			mode = (c == '"') ? ModeDoubleQuote : ModeSingleQuote;
			return;
		}

		if (LexerScan.IsIdentStart(c))
		{
			runBegin = cursor.Index;
			runColumn = cursor.Column;
			ScanName(ref cursor);
			LexerScan.Emit(outTokens, runBegin, cursor.Index, runColumn, .Attribute);
			return;
		}

		EmitGlyphs(ref cursor, outTokens, 1, .Operator, ref runBegin, ref runColumn);
	}

	private static void EmitGlyphs(ref LexerCursor cursor, List<CodeToken> outTokens, int count,
		CodeTokenKind kind, ref int runBegin, ref int32 runColumn)
	{
		runBegin = cursor.Index;
		runColumn = cursor.Column;
		for (int k = 0; k < count; k++)
			cursor.Advance();

		LexerScan.Emit(outTokens, runBegin, cursor.Index, runColumn, kind);
	}

	/// Runs to a closing sequence, emitting ONE token for the whole thing and returning to text.
	private void LexUntil(ref LexerCursor cursor, List<CodeToken> outTokens, StringView closer,
		CodeTokenKind kind, ref uint32 mode, ref int runBegin, ref int32 runColumn)
	{
		if (!cursor.Match(closer))
		{
			cursor.Advance();
			return;
		}

		for (int k = 0; k < closer.Length; k++)
			cursor.Advance();

		LexerScan.Emit(outTokens, runBegin, cursor.Index, runColumn, kind);
		mode = ModeText;
		runBegin = cursor.Index;
		runColumn = cursor.Column;
	}

	private void LexAttributeValue(ref LexerCursor cursor, List<CodeToken> outTokens,
		ref uint32 mode, int runBegin, int32 runColumn)
	{
		let quote = (mode == ModeDoubleQuote) ? '"' : '\'';
		let closing = cursor.Peek() == quote;
		cursor.Advance();

		if (!closing)
			return;

		LexerScan.Emit(outTokens, runBegin, cursor.Index, runColumn, .String);
		mode = ModeInTag;
	}

	/// Whatever was still open at the end of the line is emitted to the line's end, so a comment
	/// or a string spanning lines colours every line it crosses rather than only the last.
	private void FlushOpenRun(List<CodeToken> outTokens, StringView line, uint32 mode,
		int runBegin, int32 runColumn)
	{
		switch (mode)
		{
		case ModeComment:
			LexerScan.Emit(outTokens, runBegin, line.Length, runColumn, .Comment);
		case ModeCData, ModeDoubleQuote, ModeSingleQuote:
			LexerScan.Emit(outTokens, runBegin, line.Length, runColumn, .String);
		case ModeDeclaration:
			LexerScan.Emit(outTokens, runBegin, line.Length, runColumn, .Preprocessor);
		default:
		}
	}
}
