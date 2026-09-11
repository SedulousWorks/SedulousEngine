using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[CodeDocument]]: searching, bracket matching, markers, diagnostics and the word harvest.
extension CodeDocument
{
	/// OWNED, keyed by line. Only the markers SET directly; the derived ones are computed.
	private Dictionary<int32, uint8> mLineMarkers = new .() ~ delete _;
	/// OWNED, replaced wholesale each validation run.
	private List<CodeDiagnostic> mDiagnostics = new .() ~ DeleteContainerAndItems!(_);
	private int32 mExecutionLine = -1;

	/// OWNED, rebuilt whenever the content version moves past it.
	private List<String> mWordCache = new .() ~ DeleteContainerAndItems!(_);
	private uint64 mWordCacheVersion = uint64.MaxValue;

	// ---- Search ---------------------------------------------------------------------------------

	/// Every occurrence of a query, in document order.
	///
	/// SINGLE LINE only: a query containing a newline never matches, because the buffer is
	/// stored split and a match across lines is a different problem from the one a find bar
	/// poses. Case folding is ASCII only, which is what a code editor's find actually wants.
	public void FindAll(StringView query, bool caseSensitive, bool wholeWord,
		List<CodeSpan> outMatches)
	{
		outMatches.Clear();
		if (query.IsEmpty)
			return;

		for (int32 line = 0; line < LineCount; line++)
		{
			let text = Line(line);
			if (query.Length > text.Length)
				continue;

			var i = 0;
			while (i + query.Length <= text.Length)
			{
				if (!MatchesAt(text, i, query, caseSensitive)
					|| (wholeWord && !IsWordBoundedMatch(text, i, query.Length)))
				{
					i++;
					continue;
				}

				outMatches.Add(.(.(line, ByteToColumn(line, i)),
					.(line, ByteToColumn(line, i + query.Length))));

				// Matches do not OVERLAP: finding "aa" in "aaa" gives one match, not two, which
				// is what a replace-all needs to be well defined.
				i += query.Length;
			}
		}
	}

	private static char8 FoldAsciiCase(char8 c) =>
		((c >= 'A') && (c <= 'Z')) ? (char8)(c + 32) : c;

	private static bool MatchesAt(StringView text, int at, StringView query, bool caseSensitive)
	{
		for (int k = 0; k < query.Length; k++)
		{
			let a = caseSensitive ? text[at + k] : FoldAsciiCase(text[at + k]);
			let b = caseSensitive ? query[k] : FoldAsciiCase(query[k]);
			if (a != b)
				return false;
		}

		return true;
	}

	/// Whether a byte range butts against no word character on either side.
	private static bool IsWordBoundedMatch(StringView text, int at, int size)
	{
		if (at > 0)
		{
			var probe = Utf8Text.PrevBoundary(text, at);
			if (Classify(Utf8Text.DecodeAt(text, ref probe)) == .Word)
				return false;
		}

		if (at + size < text.Length)
		{
			var probe = at + size;
			if (Classify(Utf8Text.DecodeAt(text, ref probe)) == .Word)
				return false;
		}

		return true;
	}

	// ---- Brackets -------------------------------------------------------------------------------

	/// The codepoint at a position, or nought at or past the end of a line, which every caller
	/// here reads as "nothing there".
	public uint32 CodepointAt(CodePosition pos)
	{
		if ((pos.Line < 0) || (pos.Line >= LineCount))
			return 0;

		let text = Line(pos.Line);
		var index = ColumnToByte(pos.Line, pos.Column);
		if (index >= text.Length)
			return 0;

		return Utf8Text.DecodeAt(text, ref index);
	}

	/// The partner of a bracket, counting nesting across the whole document.
	///
	/// LEXER BLIND on purpose: a bracket inside a string or a comment counts. Making it
	/// otherwise would tie bracket matching to whichever language is loaded, and get it wrong
	/// in a different way whenever the lexer is wrong.
	public bool FindMatchingBracket(CodePosition bracketPos, out CodePosition outMatch)
	{
		outMatch = .();

		char8[3] openers = .('(', '[', '{');
		char8[3] closers = .(')', ']', '}');

		let at = CodepointAt(bracketPos);
		var pair = -1;
		var forward = false;

		for (int32 i = 0; i < 3; i++)
		{
			if (at == (uint32)openers[i])
			{
				pair = i;
				forward = true;
			}
			if (at == (uint32)closers[i])
			{
				pair = i;
			}
		}

		if (pair < 0)
			return false;

		let open = (uint32)openers[pair];
		let close = (uint32)closers[pair];
		var depth = 0;
		var pos = bracketPos;

		while (true)
		{
			let codepoint = CodepointAt(pos);
			if (codepoint == open)
				depth += forward ? 1 : -1;
			else if (codepoint == close)
				depth += forward ? -1 : 1;

			// Back to nought somewhere OTHER than where we started is the partner.
			if ((depth == 0) && !(pos == bracketPos))
			{
				outMatch = pos;
				return true;
			}

			let next = forward ? NextOnDocument(pos) : PreviousOnDocument(pos);
			if (next == pos)
				return false; // ran off the end of the document

			pos = next;
		}
	}

	// ---- Markers --------------------------------------------------------------------------------

	public void SetMarker(int32 line, CodeMarkers flag)
	{
		if ((line < 0) || (line >= LineCount))
			return;

		if (mLineMarkers.TryGetValue(line, let existing))
			mLineMarkers[line] = existing | (uint8)flag;
		else
			mLineMarkers[line] = (uint8)flag;
	}

	public void ClearMarker(int32 line, CodeMarkers flag)
	{
		if (!mLineMarkers.TryGetValue(line, let existing))
			return;

		let remaining = existing & ~(uint8)flag;
		// A line with NO markers left is removed rather than kept at zero, so the map only ever
		// holds lines that mean something and iterating it is iterating the marked lines.
		if (remaining == 0)
			mLineMarkers.Remove(line);
		else
			mLineMarkers[line] = remaining;
	}

	/// Flips a DIRECT marker. True when it is set afterwards.
	public bool ToggleMarker(int32 line, CodeMarkers flag)
	{
		if ((DirectMarkersOn(line) & flag) != .None)
		{
			ClearMarker(line, flag);
			return false;
		}

		SetMarker(line, flag);
		return true;
	}

	/// The union of what was set directly, what the diagnostics imply, and the execution line,
	/// so the gutter asks once.
	public CodeMarkers MarkersOn(int32 line)
	{
		var mask = DirectMarkersOn(line);

		for (let diagnostic in mDiagnostics)
		{
			if (diagnostic.Line == line)
				mask |= diagnostic.IsError ? CodeMarkers.Error : CodeMarkers.Warning;
		}

		if (line == mExecutionLine)
			mask |= .ExecutionLine;

		return mask;
	}

	/// Every line carrying a direct marker, SORTED, which is what a debugger harvesting
	/// breakpoints wants and what a hash map does not give.
	public void CollectMarkerLines(CodeMarkers flag, List<int32> outLines)
	{
		outLines.Clear();

		for (let pair in mLineMarkers)
		{
			if ((pair.value & (uint8)flag) != 0)
				outLines.Add(pair.key);
		}

		outLines.Sort();
	}

	private CodeMarkers DirectMarkersOn(int32 line) =>
		mLineMarkers.TryGetValue(line, let mask) ? (CodeMarkers)mask : .None;

	// ---- Diagnostics ----------------------------------------------------------------------------

	/// Replaces the whole list, which is what one validation run produces. CONSUMES the list and
	/// everything in it.
	public void SetDiagnostics(List<CodeDiagnostic> diagnostics)
	{
		ClearAndDeleteItems!(mDiagnostics);

		for (let diagnostic in diagnostics)
		{
			// CLAMPED, because a validator may be reporting against a version of the file that
			// has since been edited shorter.
			diagnostic.Line = Math.Clamp(diagnostic.Line, 0, LineCount - 1);
			mDiagnostics.Add(diagnostic);
		}

		delete diagnostics;
	}

	public int DiagnosticCount => mDiagnostics.Count;

	/// BORROWED.
	public CodeDiagnostic GetDiagnostic(int index) => mDiagnostics[index];

	/// The first diagnostic on a line, or null. What a row's tooltip shows.
	public CodeDiagnostic DiagnosticOn(int32 line)
	{
		for (let diagnostic in mDiagnostics)
		{
			if (diagnostic.Line == line)
				return diagnostic;
		}

		return null;
	}

	/// The one paused line. Minus one clears it.
	public void SetExecutionLine(int32 line) =>
		mExecutionLine = ((line >= 0) && (line < LineCount)) ? line : -1;

	public int32 ExecutionLine => mExecutionLine;

	protected void ClearAnchors()
	{
		mLineMarkers.Clear();
		ClearAndDeleteItems!(mDiagnostics);
		mExecutionLine = -1;
	}

	/// What an edit does to everything anchored to a line.
	///
	/// Lines strictly AFTER the edited range shift by the line delta. Markers on lines the edit
	/// swallowed go with them. The first line of the range KEEPS its markers, because a splice
	/// always leaves that line standing, and a breakpoint on the line being typed into should
	/// not vanish.
	private void ShiftLineAnchors(CodeSpan span, int32 delta)
	{
		if (!mLineMarkers.IsEmpty)
		{
			let shifted = scope Dictionary<int32, uint8>();
			for (let pair in mLineMarkers)
			{
				if (pair.key <= span.Begin.Line)
					shifted[pair.key] = pair.value;
				else if (pair.key > span.End.Line)
					shifted[pair.key + delta] = pair.value;
			}

			mLineMarkers.Clear();
			for (let pair in shifted)
				mLineMarkers[pair.key] = pair.value;
		}

		for (let diagnostic in mDiagnostics)
		{
			if (diagnostic.Line > span.End.Line)
				diagnostic.Line += delta;
		}

		if (mExecutionLine > span.End.Line)
			mExecutionLine += delta;
		else if ((mExecutionLine > span.Begin.Line) && (mExecutionLine <= span.End.Line))
			mExecutionLine = -1;
	}

	// ---- Word harvest ---------------------------------------------------------------------------

	/// Every distinct identifier in the buffer, for the completion provider that offers words
	/// already used in the file.
	///
	/// CACHED against the content version rather than recomputed, because completion asks on
	/// every keystroke and the answer only changes when the text does.
	public void GetWords(List<StringView> outWords)
	{
		if (mWordCacheVersion != mVersion)
			RebuildWordCache();

		for (let word in mWordCache)
			outWords.Add(word);
	}

	private void RebuildWordCache()
	{
		ClearAndDeleteItems!(mWordCache);
		let seen = scope HashSet<int>();

		for (let line in mLines)
		{
			let text = StringView(line);
			var i = 0;

			while (i < text.Length)
			{
				let begin = i;
				let codepoint = Utf8Text.DecodeAt(text, ref i);

				// A word must not START with a digit: `42` is not an identifier, and offering
				// it as a completion is noise.
				if ((Classify(codepoint) != .Word)
					|| ((codepoint >= (uint32)'0') && (codepoint <= (uint32)'9')))
					continue;

				var end = i;
				while (end < text.Length)
				{
					var probe = end;
					if (Classify(Utf8Text.DecodeAt(text, ref probe)) != .Word)
						break;

					end = probe;
				}

				let word = text.Substring(begin, end - begin);
				if (seen.Add(word.GetHashCode()))
					mWordCache.Add(new String(word));

				i = end;
			}
		}

		mWordCacheVersion = mVersion;
	}
}
