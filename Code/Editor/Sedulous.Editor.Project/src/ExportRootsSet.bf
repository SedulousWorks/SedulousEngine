using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// The project's explicit "Always Export" set, <project>/export_roots.xml, a committed
/// sidecar: instances flagged by guid, rename and move proof, and group subtrees by mount
/// relative path. Absent is the empty set, the common case; only a project with flagged
/// assets carries the file.
[Serializable(1)]
class ExportRootsSet
{
	public List<Guid> Instances = new .() ~ delete _;
	public List<String> Groups = new .() ~ DeleteContainerAndItems!(_);

	public bool IsEmpty => Instances.IsEmpty && Groups.IsEmpty;

	public bool HasInstance(Guid id) => Instances.Contains(id);

	public bool HasGroup(StringView path)
	{
		for (let group in Groups)
			if (group == path)
				return true;
		return false;
	}

	/// Idempotent: returns `member`.
	public bool SetInstance(Guid id, bool member)
	{
		let has = HasInstance(id);
		if (member && !has)
			Instances.Add(id);
		else if (!member && has)
			Instances.Remove(id);
		return member;
	}

	public bool ToggleInstance(Guid id) => SetInstance(id, !HasInstance(id));

	public bool SetGroup(StringView path, bool member)
	{
		let has = HasGroup(path);
		if (member && !has)
		{
			Groups.Add(new String(path));
		}
		else if (!member && has)
		{
			for (int i < Groups.Count)
			{
				if (Groups[i] == path)
				{
					delete Groups[i];
					Groups.RemoveAt(i);
					break;
				}
			}
		}
		return member;
	}

	public bool ToggleGroup(StringView path) => SetGroup(path, !HasGroup(path));
}
