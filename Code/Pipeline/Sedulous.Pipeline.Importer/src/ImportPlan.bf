using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Pipeline.Importer;

/// Everything an import would create, in fan out order.
///
/// EMPTY means the importer offers no per resource review, so the dialog shows its toggles and
/// nothing else.
class ImportPlan : ISerializable
{
	public List<ImportPlanEntry> Entries = new .() ~ DeleteContainerAndItems!(_);

	public bool IsEmpty => Entries.IsEmpty;

	public ImportPlanEntry Find(ImportResourceKind kind, StringView sourceName)
	{
		for (let entry in Entries)
		{
			if ((entry.Kind == kind) && (entry.SourceName == sourceName))
				return entry;
		}
		return null;
	}

	/// Appends an entry and TAKES OWNERSHIP of it.
	public void Add(ImportPlanEntry entry) => Entries.Add(entry);

	/// Written by hand rather than through a list helper: the helpers take value types or
	/// strings, and an entry is a class the list OWNS, so reading has to delete what was there
	/// and allocate fresh ones.
	public void Serialize(ISerializer ar)
	{
		ar.Key("entries");
		uint32 count = (uint32)Entries.Count;
		ar.BeginArray(ref count);

		if (ar.Mode == .Read)
		{
			ClearAndDeleteItems!(Entries);
			Entries.Reserve((int)count);
			for (uint32 i < count)
			{
				let entry = new ImportPlanEntry();
				entry.Serialize(ar);
				Entries.Add(entry);
			}
		}
		else
		{
			for (let entry in Entries)
				entry.Serialize(ar);
		}

		ar.EndArray();
	}

	/// Re-import memory: overlays a PREVIOUS import's stored decisions onto a freshly described
	/// plan.
	///
	/// A matched entry, by kind and source name, takes the stored enabled state and rename;
	/// a resource that is NEW in the source keeps the defaults it was described with. So
	/// re-importing does not re-ask what was already settled, and does not silently settle
	/// what has not been.
	public void MergeStoredSelection(ImportPlan stored)
	{
		for (let entry in Entries)
		{
			if (let match = stored.Find(entry.Kind, entry.SourceName))
			{
				entry.Enabled = match.Enabled;
				if (!match.TargetName.IsEmpty)
					entry.TargetName.Set(match.TargetName);
			}
		}
	}
}
