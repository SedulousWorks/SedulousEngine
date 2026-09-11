using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// The per line token cache over a [[CodeDocument]].
///
/// Highlighting a whole file on every keystroke does not scale, so this re-lexes LAZILY from the
/// first line that went invalid and stops as soon as it can. There are two ways to stop, and
/// both matter:
///
/// CONVERGENCE. A cached line whose entry state matches the chain coming into it is still
/// correct, and so is everything after it until the next explicit invalidation. Typing inside a
/// string re-lexes one line; typing a quote that opens one cascades until the states line up
/// again, which is usually the very next line.
///
/// THE FRONTIER. Lexing stops at the last line asked for and resumes from there next time. A
/// file with a thousand lines below the viewport costs nothing until it is scrolled to.
class CodeHighlighter
{
	private class LineCache
	{
		public uint32 Entry = 0;
		public uint32 Exit = 0;
		public List<CodeToken> Tokens = new .() ~ delete _;
		public bool Valid = false;
	}

	/// BORROWED: the owner owns the lexer.
	private ICodeLexer mLexer = null;
	private List<LineCache> mLines = new .() ~ DeleteContainerAndItems!(_);
	private int32 mFirstInvalid = 0;
	private uint64 mLexLineCalls = 0;

	/// BORROWED. Null disables highlighting and empties the cache.
	public void SetLexer(ICodeLexer lexer)
	{
		mLexer = lexer;
		Reset((int32)mLines.Count);
	}

	public bool HasLexer => mLexer != null;

	/// How many times a line has actually been lexed. Tests assert incrementality through it,
	/// which is the only way to observe laziness from outside.
	public uint64 LexLineCallCount => mLexLineCalls;

	public void Reset(int32 lineCount)
	{
		ClearAndDeleteItems!(mLines);
		for (int32 i = 0; i < lineCount; i++)
			mLines.Add(new LineCache());

		mFirstInvalid = 0;
	}

	/// Mirrors the document's own notification: lines removed at a point, lines added there.
	/// A removal count of minus one is a wholesale reload.
	public void OnLinesChanged(int32 first, int32 removed, int32 added)
	{
		if (removed < 0)
		{
			Reset(added);
			return;
		}

		for (int32 i = 0; (i < removed) && (first < mLines.Count); i++)
		{
			delete mLines[first];
			mLines.RemoveAt(first);
		}

		for (int32 i = 0; i < added; i++)
			mLines.Insert(first, new LineCache());

		mFirstInvalid = Math.Min(mFirstInvalid, first);
	}

	/// Brings every line up to the one asked for into date, plus whatever cascade they need.
	public void EnsureLexed(CodeDocument document, int32 upToLine)
	{
		if (mLexer == null)
			return;

		ResyncLineCount(document);

		let count = (int32)mLines.Count;
		let limit = Math.Min(upToLine, count - 1);
		var line = mFirstInvalid;

		while (line < count)
		{
			let entry = (line > 0) ? mLines[line - 1].Exit : 0;
			let cache = mLines[line];

			if (cache.Valid && (cache.Entry == entry))
			{
				// CONVERGED: this line and everything valid after it are still right, so skip
				// to the next line somebody actually invalidated.
				line = SkipValidRun(line, count);
				if (line > limit)
					return;

				continue;
			}

			cache.Tokens.Clear();
			cache.Entry = entry;
			cache.Exit = mLexer.LexLine(document.Line(line), entry, cache.Tokens);
			cache.Valid = true;
			mLexLineCalls++;
			line++;

			if (line > limit)
			{
				// THE FRONTIER: stop here and resume from this line when it is next needed.
				mFirstInvalid = line;
				return;
			}
		}

		mFirstInvalid = count;
	}

	private int32 SkipValidRun(int32 from, int32 count)
	{
		var next = from + 1;
		while ((next < count) && mLines[next].Valid)
			next++;

		mFirstInvalid = next;
		return next;
	}

	/// DEFENSIVE. The owner normally keeps the counts aligned by forwarding the document's
	/// notifications, and a cache out of step with the buffer would index past its end.
	private void ResyncLineCount(CodeDocument document)
	{
		while (mLines.Count < document.LineCount)
			mLines.Add(new LineCache());

		while (mLines.Count > document.LineCount)
		{
			delete mLines[mLines.Count - 1];
			mLines.RemoveAt(mLines.Count - 1);
		}
	}

	/// BORROWED, and valid only for a line already covered. Empty otherwise, which is what an
	/// unlexed line below the frontier looks like.
	public Span<CodeToken> TokensFor(int32 line)
	{
		if ((line < 0) || (line >= mLines.Count) || !mLines[line].Valid)
			return .();

		return mLines[line].Tokens;
	}
}
