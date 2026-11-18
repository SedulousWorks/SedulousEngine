using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;

namespace Sedulous.Editor.Project;

// Recognizers turn a log line's text into references for lines logged without them: most of the
// engine's lines, a compiler's output, a stack trace. Each is a matcher over the message that adds
// the references it finds, with the part of the message each stands for. A host keeps one set
// (LogReferenceRecognizers) and runs it when it shows or returns a line; the console then links the
// parts and log_read returns them. Two come with the engine: paths of files in the project, with a
// line and column when the text gives them (`file(12,5)`, `file:12:5`), and the ids of the
// project's assets.

class LogReferenceRecognizers
{
	/// Adds what it finds in `message` to `outFound` (new references, the list's owner's).
	public typealias Recognizer = delegate void(StringView message, List<LogReference> outFound);

	private List<(uint64 Id, Recognizer Fn)> mRecognizers = new .() ~ { for (let entry in _) delete entry.Fn; delete _; };
	private uint64 mNextId = 1;

	/// Adds a recognizer, TAKING OWNERSHIP of it; the id removes it.
	public uint64 Add(Recognizer recognizer)
	{
		mRecognizers.Add((mNextId, recognizer));
		return mNextId++;
	}

	public void Remove(uint64 id)
	{
		for (int i < mRecognizers.Count)
		{
			if (mRecognizers[i].Id == id)
			{
				delete mRecognizers[i].Fn;
				mRecognizers.RemoveAt(i);
				return;
			}
		}
	}

	public int Count => mRecognizers.Count;

	/// What every recognizer finds in `message`, appended to `outFound` (the caller's) in the
	/// order of their parts; where two overlap, the one that starts first (else the longer) is kept.
	public void Recognize(StringView message, List<LogReference> outFound)
	{
		let found = scope List<LogReference>();
		for (let entry in mRecognizers)
			entry.Fn(message, found);
		// Insertion sort, stable: few per line.
		for (int i = 1; i < found.Count; i++)
		{
			for (int k = i; (k > 0) && Before(found[k], found[k - 1]); k--)
				Swap!(found[k], found[k - 1]);
		}
		LogReference kept = null;
		for (let reference in found)
		{
			if ((kept == null) || (reference.Start >= (kept.Start + kept.Length)))
			{
				outFound.Add(reference);
				kept = reference;
			}
			else
				delete reference;
		}
	}

	/// A line's references, appended to `outAll` (the caller's): copies of those its log call
	/// attached first, then those recognized in it that overlap none of the attached parts, so a
	/// place links once.
	public void Of(StringView message, Span<LogReference> attached, List<LogReference> outAll)
	{
		for (let reference in attached)
			outAll.Add(reference.Clone());
		let recognized = scope List<LogReference>();
		Recognize(message, recognized);
		for (let reference in recognized)
		{
			bool overlaps = false;
			for (let given in attached)
			{
				overlaps |= (given.Length > 0) && (reference.Start < (given.Start + given.Length)) &&
					(given.Start < (reference.Start + reference.Length));
			}
			if (overlaps)
				delete reference;
			else
				outAll.Add(reference);
		}
	}

	private static bool Before(LogReference a, LogReference b)
	{
		return (a.Start != b.Start) ? (a.Start < b.Start) : (a.Length > b.Length);
	}

	private static bool IsSeparator(char8 c) => (c == '/') || (c == '\\');

	// The number at `at`, how many digits it took in `length`; 0 when there is none.
	private static uint32 NumberAt(StringView text, int at, out int length)
	{
		uint32 value = 0;
		length = 0;
		while (((at + length) < text.Length) && text[at + length].IsDigit && (length < 9))
		{
			value = value * 10 + (uint32)(text[at + length] - '0');
			length++;
		}
		return value;
	}

	// Where a path that starts at `start` ends: at whitespace, a quote, a bracket, a comma, or a
	// colon that a number follows (a line).
	private static int PathEnd(StringView text, int start)
	{
		int end = start;
		while (end < text.Length)
		{
			let c = text[end];
			if ((c == ' ') || (c == '\t') || (c == '\n') || (c == '"') || (c == '\'') || (c == '(') || (c == ')') ||
				(c == ',') || (c == '[') || (c == ']') || (c == '<') || (c == '>'))
				break;
			if ((c == ':') && ((end + 1) < text.Length) && text[end + 1].IsDigit)
				break;
			end++;
		}
		// A sentence's full stop is not the path's.
		while ((end > start) && ((text[end - 1] == '.') || (text[end - 1] == ':') || (text[end - 1] == ';')))
			end--;
		return end;
	}

	/// Paths of files under `projectRoot` (absolute, in either separator), and paths starting with
	/// the project's Code/ folder, which are read under it: each a source reference with the file's
	/// absolute path, and the line and column after it as `(12,5)`, `(12)`, `:12:5` or `:12` (its
	/// part takes them in). The caller's.
	public static Recognizer SourcePath(StringView projectRoot, StringView codeFolder = "Code")
	{
		var rootLength = projectRoot.Length;
		while ((rootLength > 0) && IsSeparator(projectRoot[rootLength - 1]))
			rootLength--;
		let root = new String(projectRoot, 0, rootLength);
		let code = new String(codeFolder);
		return new [=root, =code] (message, outFound) =>
			{
				if (root.IsEmpty)
					return;
				for (int i = 0; i < message.Length; i++)
				{
					// A path starts at the project's root, or at "Code/" where a word starts.
					int after = 0;
					bool relative = false;
					if ((message.Length - i) > root.Length)
					{
						bool matches = true;
						for (int k = 0; (k < root.Length) && matches; k++)
						{
							let a = message[i + k];
							let b = root[k];
							matches = (a == b) || (IsSeparator(a) && IsSeparator(b));
						}
						if (matches && IsSeparator(message[i + root.Length]))
							after = i + root.Length + 1;
					}
					if ((after == 0) && ((i == 0) || (message[i - 1] == ' ') || (message[i - 1] == '\'') || (message[i - 1] == '"') || (message[i - 1] == '(')))
					{
						let rest = StringView(message, i);
						if ((rest.Length > (code.Length + 1)) && rest.StartsWith(code) && IsSeparator(rest[code.Length]))
						{
							after = i + code.Length + 1;
							relative = true;
						}
					}
					if (after == 0)
						continue;
					let end = PathEnd(message, after);
					if (end <= after)
						continue;
					let file = scope String();
					if (relative)
						PathJoin(root, StringView(message, i, end - i), file);
					else
						file.Append(StringView(message, i, end - i));
					file.Replace('\\', '/');
					// The line and column: (12,5), (12), :12:5 or :12.
					uint32 line = 0;
					uint32 column = 0;
					int stop = end;
					if ((end < message.Length) && (message[end] == '('))
					{
						line = NumberAt(message, end + 1, let digits);
						int at = end + 1 + digits;
						if ((digits > 0) && (at < message.Length) && (message[at] == ','))
						{
							column = NumberAt(message, at + 1, let more);
							at += 1 + more;
						}
						if ((digits > 0) && (at < message.Length) && (message[at] == ')'))
							stop = at + 1;
						else
						{
							line = 0;
							column = 0;
						}
					}
					else if ((end < message.Length) && (message[end] == ':'))
					{
						line = NumberAt(message, end + 1, let digits);
						stop = end + 1 + digits;
						if ((stop < message.Length) && (message[stop] == ':'))
						{
							column = NumberAt(message, stop + 1, let more);
							if (more > 0)
								stop += 1 + more;
						}
					}
					let reference = LogReference.ForSource(file, line, column);
					reference.Start = i;
					reference.Length = stop - i;
					outFound.Add(reference);
					i = stop - 1;
				}
			} ~ { delete root; delete code; };
	}

	/// Asset ids in their text form (with or without braces) that `known` says are the project's
	/// assets: each an asset reference. TAKES OWNERSHIP of `known`; the result is the caller's.
	public static Recognizer AssetId(delegate bool(Guid id) known)
	{
		return new [=known] (message, outFound) =>
			{
				const int cLength = 36;
				for (int i = 0; (i + cLength) <= message.Length; i++)
				{
					// A guid's dashes sit at 8, 13, 18 and 23; checked first to skip most text.
					if ((message[i + 8] != '-') || (message[i + 13] != '-') || (message[i + 18] != '-') || (message[i + 23] != '-'))
						continue;
					let parsed = Guid.Parse(StringView(message, i, cLength));
					if (parsed case .Err)
						continue;
					let id = parsed.Value;
					if ((known == null) || !known(id))
						continue;
					let braced = (i > 0) && (message[i - 1] == '{') && ((i + cLength) < message.Length) && (message[i + cLength] == '}');
					let reference = LogReference.ForAsset(id);
					reference.Start = braced ? i - 1 : i;
					reference.Length = braced ? cLength + 2 : cLength;
					outFound.Add(reference);
					i += cLength - 1;
				}
			} ~ delete known;
	}
}
