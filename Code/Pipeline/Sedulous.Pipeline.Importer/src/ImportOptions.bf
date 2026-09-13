using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Pipeline.Importer;

/// Importer specific options, shown by the import dialog before the import runs.
///
/// A subclass adds its fields and returns the toggles that point at them. The base is
/// deliberately empty: no options means no dialog, and the import runs on the drop.
class ImportOptions : ISerializable
{
	/// The review dialog's per resource decisions, being an edited copy of what DescribeImport
	/// returned.
	///
	/// Empty means import everything under its default name. An importer that supports review
	/// consults this at each creation site through the two accessors below; one that does not
	/// ignores it entirely.
	public ImportPlan Selection = new .() ~ delete _;

	/// The checkboxes this importer wants, appended to the list. None by default.
	public virtual void GetToggles(List<ImportToggle> outToggles)
	{
	}

	public virtual void Serialize(ISerializer ar)
	{
	}

	/// Whether the resource is checked. An UNMENTIONED resource is enabled: a selection that
	/// does not name something has no opinion about it, which is not the same as excluding it.
	public bool SelectionEnabled(ImportResourceKind kind, StringView sourceName)
	{
		let entry = Selection.Find(kind, sourceName);
		return (entry == null) || entry.Enabled;
	}

	/// The user's target name for the resource, falling back to the importer's base name.
	public StringView SelectionName(ImportResourceKind kind, StringView sourceName)
	{
		let entry = Selection.Find(kind, sourceName);
		return ((entry != null) && !entry.TargetName.IsEmpty) ? entry.TargetName : sourceName;
	}
}
