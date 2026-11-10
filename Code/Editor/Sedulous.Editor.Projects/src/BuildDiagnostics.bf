using System;
using System.Collections;

namespace Sedulous.Editor.Project;

enum BuildSeverity
{
	Error,
	Warning
}

/// A place a diagnostic points to besides its own: BeefBuild's "  > Previous declaration at
/// line 60:62 in FILE" under a duplicate declaration.
class BuildNote
{
	public String Message = new .() ~ delete _;
	/// Empty for a note with no place.
	public String File = new .() ~ delete _;
	/// 1 based, 0 with no place.
	public int Line;
	public int Column;
	/// The source line BeefBuild printed under it, and the carets under that when it printed them.
	public String Excerpt = new .() ~ delete _;

	public void CopyTo(BuildNote outNote)
	{
		outNote.Message.Set(Message);
		outNote.File.Set(File);
		outNote.Line = Line;
		outNote.Column = Column;
		outNote.Excerpt.Set(Excerpt);
	}
}

/// One error or warning of a build: from the compiler with its place in a source file, or one
/// with no place (a linker's error, a project BeefBuild could not load).
class BuildDiagnostic
{
	public BuildSeverity Severity;
	public String Message = new .() ~ delete _;
	/// The source file as BeefBuild named it (absolute); empty for one with no place.
	public String File = new .() ~ delete _;
	/// 1 based, 0 with no place.
	public int Line;
	public int Column;
	/// The warning's number ("BF0168"), empty when it has none.
	public String Code = new .() ~ delete _;
	/// The source line BeefBuild printed under it, and the carets under that when it printed them.
	public String Excerpt = new .() ~ delete _;
	public List<BuildNote> Notes = new .() ~ DeleteContainerAndItems!(_);

	public bool HasPlace => !File.IsEmpty;

	/// "file:line:column: message", the form editors and terminals turn into a link; the
	/// message alone for one with no place.
	public void Describe(String outText)
	{
		if (HasPlace)
			outText.AppendF("{}:{}:{}: ", File, Line, Column);
		outText.Append(Message);
	}

	/// Whether `other` says the same thing at the same place: BeefBuild run once per config
	/// reports the engine's warnings each time.
	public bool SameAs(BuildDiagnostic other)
	{
		return (Severity == other.Severity) && (Line == other.Line) && (Column == other.Column) && (Message == other.Message) &&
			(File == other.File) && (Code == other.Code);
	}

	public void CopyTo(BuildDiagnostic outDiagnostic)
	{
		outDiagnostic.Severity = Severity;
		outDiagnostic.Message.Set(Message);
		outDiagnostic.File.Set(File);
		outDiagnostic.Line = Line;
		outDiagnostic.Column = Column;
		outDiagnostic.Code.Set(Code);
		outDiagnostic.Excerpt.Set(Excerpt);
		ClearAndDeleteItems!(outDiagnostic.Notes);
		for (let note in Notes)
		{
			let copy = new BuildNote();
			note.CopyTo(copy);
			outDiagnostic.Notes.Add(copy);
		}
	}
}

/// BeefBuild's output read into diagnostics, one line at a time as the build prints it (Feed).
///
/// What BeefBuild prints, and what is made of it:
/// - "ERROR: message at line L:C in FILE" and "WARNING(n): BFnnnn: message at line L:C in FILE"
///   start a diagnostic (a message ending in '.', '?' or '!' says "Line L:C" instead of "at
///   line L:C"); one with no place ("ERROR: Unable to load project ...") has none;
/// - the source line after a placed one, and the carets under it, are its excerpt;
/// - "  > message at line L:C in FILE" is a note of the diagnostic above, with an excerpt of
///   its own;
/// - "Errors: N. Warnings: M." is the compiler's own count (SummaryErrors, SummaryWarnings);
/// - "ERROR-SOFT: Compile failed. ..." is the build failing as a whole (CompileFailed): not a
///   diagnostic, as the errors that failed it are already counted;
/// - a linker's line ("wasm-ld: error: ...", ld's "undefined reference to ...") is an error
///   with no place, its message the whole line.
/// The progress bar BeefBuild draws ("[    ]" with backspaces, then runs of '*') sits in front
/// of whatever line follows it, and is taken off first (StripProgress).
class BuildDiagnostics
{
	private enum Expecting
	{
		None,
		/// The source line under a placed diagnostic or note.
		Source,
		/// The carets under that line, which BeefBuild leaves out when they would underline all
		/// of it.
		Carets
	}

	/// In the order BeefBuild printed them, each said once.
	public List<BuildDiagnostic> Items = new .() ~ DeleteContainerAndItems!(_);
	/// The compiler's own counts from its summary line, -1 until one is read.
	public int SummaryErrors = -1;
	public int SummaryWarnings = -1;
	/// BeefBuild said "Compile failed".
	public bool CompileFailed;

	/// The last diagnostic begun, until a line that is not its own ends it.
	private BuildDiagnostic mCurrent;
	/// Its last note, whose excerpt the next lines are while mExpecting says so.
	private BuildNote mCurrentNote;
	private Expecting mExpecting = .None;

	public int ErrorCount => Count(.Error);
	public int WarningCount => Count(.Warning);

	public int Count(BuildSeverity severity)
	{
		int count = 0;
		for (let item in Items)
		{
			if (item.Severity == severity)
				count++;
		}
		return count;
	}

	/// Every line of `text` in turn, then Finish.
	public void Parse(StringView text)
	{
		for (let line in text.Split('\n'))
			Feed(line);
		Finish();
	}

	/// One line of BeefBuild's output, without its ending.
	public void Feed(StringView rawLine)
	{
		var line = StripProgress(rawLine);
		if (line.EndsWith('\r'))
			line = line.Substring(0, line.Length - 1);

		// Never a line that starts a diagnostic: a line from the other pipe can come between.
		if ((mExpecting == .Source) && !IsHeader(line))
		{
			AppendExcerpt(line);
			mExpecting = .Carets;
			return;
		}
		if ((mExpecting == .Carets) && IsCarets(line))
		{
			AppendExcerpt(line);
			mExpecting = .None;
			return;
		}
		mExpecting = .None;

		if (line.IsWhiteSpace)
			return;
		if (line.StartsWith("ERROR-SOFT:"))
		{
			End();
			CompileFailed = true;
			return;
		}
		if (ReadHeader(line, var severity, var rest))
		{
			Begin(severity);
			ReadCode(ref rest, mCurrent.Code);
			if (ReadPlace(rest, mCurrent.Message, mCurrent.File, out mCurrent.Line, out mCurrent.Column))
				mExpecting = .Source;
			return;
		}
		var trimmed = line;
		trimmed.TrimStart();
		if ((mCurrent != null) && trimmed.StartsWith("> "))
		{
			let note = new BuildNote();
			mCurrent.Notes.Add(note);
			mCurrentNote = note;
			if (ReadPlace(trimmed.Substring(2), note.Message, note.File, out note.Line, out note.Column))
				mExpecting = .Source;
			return;
		}
		if (ReadSummary(line))
		{
			End();
			return;
		}
		if (line.Contains(": error:") || line.Contains("undefined reference"))
		{
			Begin(.Error);
			mCurrent.Message.Set(trimmed);
			End();
			return;
		}
		// Any other line (a step BeefBuild reports, a timing) ends the diagnostic above.
		End();
	}

	/// Ends the diagnostic being read: the end of a run's output.
	public void Finish()
	{
		End();
		mExpecting = .None;
	}

	/// `line` less the progress bar BeefBuild draws in front of it: a "[" and "]" holding only
	/// spaces and '*', the backspaces that walk back over it, and the '*' it fills it with.
	public static StringView StripProgress(StringView line)
	{
		var rest = line;
		while (!rest.IsEmpty)
		{
			let first = rest[0];
			if ((first == '\b') || (first == '*'))
			{
				rest = rest.Substring(1);
				continue;
			}
			if (first == '[')
			{
				let close = rest.IndexOf(']');
				if (close < 0)
					break;
				bool bar = true;
				for (let c in rest.Substring(1, close - 1))
					bar &= (c == ' ') || (c == '*');
				if (!bar)
					break;
				rest = rest.Substring(close + 1);
				continue;
			}
			break;
		}
		return rest;
	}

	private void Begin(BuildSeverity severity)
	{
		End();
		mCurrent = new BuildDiagnostic();
		mCurrent.Severity = severity;
		Items.Add(mCurrent);
	}

	/// Ends the diagnostic being read, dropping it when an earlier one says the same.
	private void End()
	{
		if (mCurrent != null)
		{
			for (int i < Items.Count - 1)
			{
				if (Items[i].SameAs(mCurrent))
				{
					Items.PopBack();
					delete mCurrent;
					break;
				}
			}
		}
		mCurrent = null;
		mCurrentNote = null;
	}

	private void AppendExcerpt(StringView line)
	{
		let excerpt = (mCurrentNote != null) ? mCurrentNote.Excerpt : ((mCurrent != null) ? mCurrent.Excerpt : null);
		if (excerpt == null)
			return;
		if (!excerpt.IsEmpty)
			excerpt.Append('\n');
		excerpt.Append(line);
	}

	/// Whether `line` starts a diagnostic.
	private static bool IsHeader(StringView line) => ReadHeader(line, ?, ?);

	/// "ERROR" or "WARNING", then a count in brackets or a space, then ':': its severity and what
	/// follows the colon.
	private static bool ReadHeader(StringView line, out BuildSeverity severity, out StringView rest)
	{
		severity = .Error;
		rest = default;
		var after = line;
		if (line.StartsWith("ERROR"))
			after = line.Substring("ERROR".Length);
		else if (line.StartsWith("WARNING"))
		{
			severity = .Warning;
			after = line.Substring("WARNING".Length);
		}
		else
			return false;
		after = after..TrimStart();
		if (after.StartsWith('('))
		{
			let close = after.IndexOf(')');
			if (close < 0)
				return false;
			after = after.Substring(close + 1)..TrimStart();
		}
		if (!after.StartsWith(':'))
			return false;
		rest = after.Substring(1)..TrimStart();
		return true;
	}

	/// A warning's number ("BF0168: ") off the front of `rest`, into `outCode`.
	private static void ReadCode(ref StringView rest, String outCode)
	{
		if ((rest.Length < 7) || !rest.StartsWith("BF") || (rest[6] != ':'))
			return;
		for (int i = 2; i < 6; i++)
		{
			if (!rest[i].IsDigit)
				return;
		}
		outCode.Set(rest.Substring(0, 6));
		rest = rest.Substring(7)..TrimStart();
	}

	/// A message and the place after it: "message at line L:C in FILE", or "message Line L:C in
	/// FILE" for one ending in '.', '?' or '!'. The last marker that reads as a place wins, so a
	/// message quoting one keeps it. False, the whole text the message, for one with no place.
	private static bool ReadPlace(StringView text, String outMessage, String outFile, out int line, out int column)
	{
		line = 0;
		column = 0;
		int placeAt = -1;
		int markerLength = 0;
		for (let marker in StringView[2](" at line ", " Line "))
		{
			int from = 0;
			while (true)
			{
				let found = text.IndexOf(marker, from);
				if (found < 0)
					break;
				from = found + 1;
				if ((found > placeAt) && ReadLocation(text.Substring(found + marker.Length), ?, ?, ?))
				{
					placeAt = found;
					markerLength = marker.Length;
				}
			}
		}
		if (placeAt < 0)
		{
			outMessage.Set(text);
			return false;
		}
		outMessage.Set(text.Substring(0, placeAt));
		ReadLocation(text.Substring(placeAt + markerLength), out line, out column, var file);
		outFile.Set(file);
		return true;
	}

	/// "L:C in FILE".
	private static bool ReadLocation(StringView text, out int line, out int column, out StringView file)
	{
		line = 0;
		column = 0;
		file = default;
		let colon = text.IndexOf(':');
		if (colon <= 0)
			return false;
		let space = text.IndexOf(" in ");
		if (space <= colon + 1)
			return false;
		if (!ReadNumber(text.Substring(0, colon), out line) || !ReadNumber(text.Substring(colon + 1, space - colon - 1), out column))
			return false;
		file = text.Substring(space + " in ".Length)..Trim();
		return !file.IsEmpty;
	}

	/// "Errors: N. Warnings: M."
	private bool ReadSummary(StringView line)
	{
		if (!line.StartsWith("Errors: "))
			return false;
		let rest = line.Substring("Errors: ".Length);
		let dot = rest.IndexOf('.');
		if (dot <= 0)
			return false;
		if (!ReadNumber(rest.Substring(0, dot), let errors))
			return false;
		let warnings = rest.Substring(dot + 1)..Trim();
		if (!warnings.StartsWith("Warnings: "))
			return false;
		var count = warnings.Substring("Warnings: ".Length);
		if (count.EndsWith('.'))
			count = count.Substring(0, count.Length - 1);
		if (!ReadNumber(count, let warningCount))
			return false;
		SummaryErrors = errors;
		SummaryWarnings = warningCount;
		return true;
	}

	/// A line of carets under a source line: spaces, then at least one '^'.
	private static bool IsCarets(StringView line)
	{
		var trimmed = line;
		trimmed.Trim();
		if (trimmed.IsEmpty)
			return false;
		for (let c in trimmed)
		{
			if (c != '^')
				return false;
		}
		return true;
	}

	private static bool ReadNumber(StringView text, out int value)
	{
		value = 0;
		if (text.IsEmpty)
			return false;
		for (let c in text)
		{
			if (!c.IsDigit)
				return false;
			value = value * 10 + ((int)c - (int)'0');
		}
		return true;
	}
}
