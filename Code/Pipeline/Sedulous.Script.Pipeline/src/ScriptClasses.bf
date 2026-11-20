using System;
using System.Collections;
using Sedulous.Pipeline.Importer;
using Sedulous.Script;

namespace Sedulous.Script.Pipeline;

/// The class a script plays, shared by every language's cook: the top-level `class Name` scan
/// (the C-family convention) and the choice among the classes a file declares. A file may
/// declare several (data, helpers), so the class it plays is chosen by name, never guessed.
static class ScriptClasses
{
	/// Every top-level `class Name` in `source`, in order, appended; none for a utility module.
	/// Comments and string literals are ignored.
	public static void ListClasses(StringView source, List<String> outNames)
	{
		let stripped = StripComments(source, .. scope .());
		int depth = 0;
		int i = 0;
		while (i < stripped.Length)
		{
			let c = stripped[i];
			if (c == '{')
				depth++;
			else if (c == '}')
				depth--;
			else if ((depth == 0) && stripped.Substring(i).StartsWith("class") && ((i == 0) || !stripped[i - 1].IsLetterOrDigit))
			{
				int j = i + 5;
				while ((j < stripped.Length) && stripped[j].IsWhiteSpace)
					j++;
				int start = j;
				while ((j < stripped.Length) && (stripped[j].IsLetterOrDigit || (stripped[j] == '_')))
					j++;
				if (j > start)
				{
					outNames.Add(new String(stripped.Substring(start, j - start)));
					i = j;
					continue;
				}
			}
			i++;
		}
	}

	/// The class a script plays among `declared`, into `outClass`: the one named `preferred`,
	/// else its only one. Several and none so named is no guess: false, with `outProblem`
	/// naming them and how to choose. None at all is a utility module: true, `outClass` empty.
	public static bool Choose(List<String> declared, StringView preferred, String outClass, String outProblem)
	{
		outClass.Clear();
		for (let name in declared)
		{
			if (name == preferred)
			{
				outClass.Set(name);
				return true;
			}
		}
		if (declared.Count == 1)
		{
			outClass.Set(declared[0]);
			return true;
		}
		if (declared.IsEmpty)
			return true;
		let names = scope String();
		for (let name in declared)
		{
			if (!names.IsEmpty)
				names.Append(", ");
			names.Append(name);
		}
		outProblem.AppendF("it declares the classes {} and none is '{}': set the script asset's Class Name to the one it plays (script_validate: className)", names, preferred);
		return false;
	}

	/// The behavior class a script plays: the one among `declared` that derives from a kind
	/// (`kinds[i]` is `declared[i]`'s), into `outClass`, its kind in `outKind`. Classes that
	/// derive from none make a module of helpers: true, `outClass` empty, kind None. Several
	/// that derive from a kind is no guess: false, `outProblem` naming them, since a script
	/// holds one behavior class.
	public static bool ChooseBehavior(List<String> declared, List<BehaviorKind> kinds, String outClass, out BehaviorKind outKind,
		String outProblem)
	{
		outClass.Clear();
		outKind = .None;
		let names = scope String();
		int count = 0;
		for (int i < declared.Count)
		{
			let kind = (i < kinds.Count) ? kinds[i] : BehaviorKind.None;
			if (kind == .None)
				continue;
			if (count == 0)
			{
				outClass.Set(declared[i]);
				outKind = kind;
			}
			count++;
			if (!names.IsEmpty)
				names.Append(", ");
			names.Append(declared[i]);
		}
		if (count <= 1)
			return true;
		outClass.Clear();
		outKind = .None;
		outProblem.AppendF("it declares the behavior classes {}: a script holds one, so move the others to scripts of their own", names);
		return false;
	}

	/// The class preferred for a source: `className` when given (an asset's recorded class),
	/// else the one named like `sourceName`'s file.
	public static void PreferredFor(StringView className, StringView sourceName, String outClass)
	{
		if (!className.IsEmpty)
			outClass.Append(className);
		else
			outClass.Append(ImportPaths.StemOf(ImportPaths.FileNameOf(sourceName)));
	}

	/// The class a script asset prefers: the one it records, else the one named like its file.
	public static void Preferred(ScriptClassAsset asset, String outClass) => PreferredFor(asset.ClassName, asset.FileName.Value, outClass);

	/// `source` with its comments dropped and its string literals blanked, so a `class` in
	/// either is not taken for a declaration.
	public static void StripComments(StringView source, String outStripped)
	{
		int i = 0;
		while (i < source.Length)
		{
			if ((i + 1 < source.Length) && (source[i] == '/') && (source[i + 1] == '/'))
			{
				while ((i < source.Length) && (source[i] != '\n')) i++;
				continue;
			}
			if ((i + 1 < source.Length) && (source[i] == '/') && (source[i + 1] == '*'))
			{
				i += 2;
				while ((i + 1 < source.Length) && !((source[i] == '*') && (source[i + 1] == '/'))) i++;
				i += 2;
				continue;
			}
			if (source[i] == '"')
			{
				outStripped.Append(' ');
				i++;
				while ((i < source.Length) && (source[i] != '"')) { if (source[i] == '\\') i++; i++; }
				i++;
				continue;
			}
			outStripped.Append(source[i]);
			i++;
		}
	}
}
