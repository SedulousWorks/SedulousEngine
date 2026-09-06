using System;
using Sedulous.Core.Serialization;

namespace Sedulous.VFS;

/// A typed mount-relative logical path: the currency for source-file references in stored
/// asset data.
///
/// One guarantee, whatever string it was built from: the stored form is forward-slash,
/// relative, and free of dot segments. A Windows-authored "Fonts\Roboto.ttf" heals into
/// "Fonts/Roboto.ttf" rather than breaking every lookup on every other platform.
///
/// NOT a general OS path. No volumes, no macros, no absolute form. A string that violates
/// the contract, meaning absolute, escaping with "..", or carrying a ':' scheme or volume,
/// normalizes to EMPTY: a missing reference, never a wrong one.
///
/// Comparison is case SENSITIVE on every platform. One rule everywhere means a
/// Windows-authored case mismatch is caught by a test rather than by a user on Linux.
class SourcePath
{
	private String mValue = new .() ~ delete _;

	public this()
	{
	}

	public this(StringView raw)
	{
		Normalize(raw, mValue);
	}

	public StringView Value => mValue;
	public bool IsEmpty => mValue.IsEmpty;

	/// "Fonts/Roboto.ttf" gives "Roboto.ttf".
	public StringView FileName
	{
		get
		{
			let slash = mValue.LastIndexOf('/');
			return (slash < 0) ? (StringView)mValue : StringView(mValue, slash + 1);
		}
	}

	/// "Fonts/Roboto.ttf" gives "Roboto".
	public StringView Stem
	{
		get
		{
			let file = FileName;
			let dot = file.LastIndexOf('.');
			return (dot < 0) ? file : StringView(file, 0, dot);
		}
	}

	/// "Fonts/Roboto.ttf" gives "Fonts"; a bare filename gives empty.
	///
	/// Empty is a zero length view into the value rather than a null one, so comparing it
	/// does not depend on which equality overload the caller happened to select.
	public StringView Directory
	{
		get
		{
			let slash = mValue.LastIndexOf('/');
			return (slash < 0) ? StringView(mValue, 0, 0) : StringView(mValue, 0, slash);
		}
	}

	/// "Fonts/Roboto.TTF" gives "ttf": lowercased, and without the dot.
	///
	/// Lowercased because the extension selects an importer, and a type should not depend
	/// on how the file happened to be named.
	public void GetExtension(String outExtension)
	{
		outExtension.Clear();

		let file = FileName;
		let dot = file.LastIndexOf('.');
		if ((dot < 0) || (dot + 1 == file.Length))
			return;

		outExtension.Append(StringView(file, dot + 1));
		outExtension.ToLower();
	}

	public bool Equals(SourcePath other) => (other != null) && (mValue == other.mValue);
	public bool Equals(StringView other) => mValue == other;

	public static bool operator ==(SourcePath a, SourcePath b)
	{
		if (a == null || b == null)
			return (a == null) && (b == null);
		return a.mValue == b.mValue;
	}

	public override void ToString(String strBuffer) => strBuffer.Append(mValue);

	/// The normalization contract, usable on its own by an importer producing paths. An
	/// input that violates it leaves the output EMPTY.
	public static void Normalize(StringView raw, String outValue)
	{
		outValue.Clear();

		// A ':' means a scheme or a volume, neither of which is a mount-relative path.
		if (raw.Contains(':'))
			return;

		let cleaned = scope String(raw.Length);
		for (let c in raw)
			cleaned.Append((c == '\\') ? '/' : c);

		if (!cleaned.IsEmpty && (cleaned[0] == '/'))
			return; // absolute

		// Rebuilt segment by segment: empty segments and "." are dropped, ".." rejects.
		var start = 0;
		while (start <= cleaned.Length)
		{
			var end = start;
			while ((end < cleaned.Length) && (cleaned[end] != '/'))
				end++;

			let segment = StringView(cleaned, start, end - start);
			if (segment == "..")
			{
				outValue.Clear();
				return; // escapes the mount
			}

			if (!segment.IsEmpty && (segment != "."))
			{
				if (!outValue.IsEmpty)
					outValue.Append('/');
				outValue.Append(segment);
			}

			if (end == cleaned.Length)
				break;
			start = end + 1;
		}
	}

	/// Wire compatible with a plain string field, so data written before this type existed
	/// loads unchanged. Reads re-normalize, which is what heals Windows-authored data
	/// without a version bump.
	public void Serialize(ISerializer ar)
	{
		ar.Text(mValue);
		if (ar.Mode == .Read)
		{
			let raw = scope String(mValue);
			Normalize(raw, mValue);
		}
	}
}
