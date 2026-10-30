using System;
using Sedulous.Content;

namespace Sedulous.Pipeline.Importer;

/// What an import does when the name it would take is held by an asset of its own type that
/// ANOTHER file made. An asset of another type is always refused, and a re-import of the same
/// file replaces its asset without asking.
enum ImportConflictChoice : uint8
{
	/// Fail, naming the asset there (the default).
	Refuse,
	/// The asset there takes the new file: its guid, and so what refers to it, kept.
	Replace,
	/// The new asset under the next free name ("Menu.2").
	KeepBoth,
}

enum ImportClashKind : uint8
{
	/// The name is free.
	None,
	/// Held by this file's own earlier import: it is replaced, as a re-import is.
	Reimport,
	/// Held by an asset of another type: always refused.
	OtherType,
	/// Held by an asset of its type from another file: ImportConflictChoice decides.
	SameType,
}

/// What taking a name meets (ImportPaths.FindImportClash).
class ImportClash
{
	public ImportClashKind Kind = .None;
	/// The name asked for.
	public String Name = new .() ~ delete _;
	/// What holds it.
	public String ExistingType = new .() ~ delete _;
	/// The asset there, which the database owns.
	public Instance Existing;

	public void Clear()
	{
		Kind = .None;
		Name.Clear();
		ExistingType.Clear();
		Existing = null;
	}
}
