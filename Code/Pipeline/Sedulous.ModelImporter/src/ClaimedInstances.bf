using System;
using System.Collections;
using Sedulous.Content;

namespace Sedulous.ModelImporter;

/// Naming what an import creates when something of that name may already be there.
///
/// Re-import is the whole point: a same named instance OF THE SAME TYPE from a previous import
/// is REUSED, so its identity survives, its cooked product overwrites in place, and everything
/// pointing at it, materials, prefabs, placed scenes, follows the re-imported content instead
/// of dangling.
static class ClaimedInstances
{
	/// Reuses or creates the instance for a name, recording the name as taken.
	///
	/// A name already claimed THIS run, which two source textures called the same thing
	/// produce, or one squatted by a DIFFERENT type, gets a numeric suffix rather than
	/// colliding.
	public static Instance Claim(Group group, StringView @base, StringView typeName,
		List<String> claimed)
	{
		let name = scope String(@base);
		for (uint32 n = 2;; ++n)
		{
			var taken = false;
			for (let c in claimed)
			{
				if (c == name)
				{
					taken = true;
					break;
				}
			}

			if (!taken)
			{
				let existing = group.GetInstance(name);
				if ((existing == null) || (existing.TypeName == typeName))
				{
					let instance = (existing != null) ? existing
						: group.CreateInstance(name, typeName);
					if (instance != null)
						claimed.Add(new String(name));
					return instance;
				}
			}

			name.Clear();
			name.AppendF("{}.{}", @base, n);
		}
	}
}
