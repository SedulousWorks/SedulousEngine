using System;
using Sedulous.Core.IO;
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
	/// The top-level name a source path reserves for a project's code: Code/Weapon.cs is a file in
	/// the project's Code/ folder, any other path one under its Sources/ folder.
	public const String CodeFolder = "Code";

	/// The rest of `path` after its first folder `folder` ("Weapon.cs" for "Code/Weapon.cs"; empty
	/// for "Code" itself), or false when it does not start with that folder (a longer name,
	/// "Codex/", is not it). An empty `folder` matches nothing.
	public static bool AfterFolder(StringView path, StringView folder, out StringView rest)
	{
		rest = default;
		if (folder.IsEmpty || !path.StartsWith(folder))
			return false;
		if (path.Length == folder.Length)
		{
			rest = StringView(path, path.Length, 0);
			return true;
		}
		if (path[folder.Length] != '/')
			return false;
		rest = StringView(path, folder.Length + 1);
		return true;
	}

	/// The file on disk a source path names, into `outPath`: under `codeRoot` when it starts with
	/// Code/ (and a code folder is given), else under `sourcesRoot`.
	public static void FileOnDisk(StringView sourcesRoot, StringView codeRoot, StringView path, String outPath)
	{
		if (!codeRoot.IsEmpty && AfterFolder(path, CodeFolder, let rest))
		{
			if (rest.IsEmpty)
				outPath.Set(codeRoot);
			else
				PathJoin(codeRoot, rest, outPath);
			return;
		}
		PathJoin(sourcesRoot, path, outPath);
	}

	private String mValue = new .() ~ delete _;

	public this()
	{
	}

	public this(StringView raw)
	{
		Normalize(raw, mValue);
	}

	/// Replaces the path in place, normalising as a constructor does. An importer writing a
	/// fresh asset sets this rather than building a second object to assign over.
	public void Set(StringView raw) => Normalize(raw, mValue);

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
