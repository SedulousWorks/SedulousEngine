using System;

namespace Sedulous.Render;

/// The categories a draw can belong to, with their sort and pass rules.
///
/// Categories are ASSIGNED IDS at registration, so an extension adds one without editing the
/// built in list. The core pre registers its own at their well known ids, which is what keeps
/// the constants beside them true, and registration is idempotent by name.
///
/// One instance per process. Registration happens at start up, on one thread; the reads,
/// which happen while a draw list is being built, then need no lock.
class CategoryRegistry
{
	private static CategoryRegistry sInstance ~ delete _;

	private CategoryInfo[RenderCategories.MaxCategories] mInfo = .();
	private uint16 mCount = 0;

	public this()
	{
		// In id order, so the ids match the constants beside them.
		Register("Opaque", .FrontToBack, .Opaque);
		Register("Masked", .FrontToBack, .Opaque);
		Register("Transparent", .BackToFront, .Blended);
		Register("Sky", .FrontToBack, .None);
		Register("Decal", .FrontToBack, .None);
		// A light is a shading input rather than something drawn.
		Register("Light", .FrontToBack, .None);
		Register("ReflectionProbe", .FrontToBack, .None);
		Register("GUI", .BackToFront, .Blended);
		Register("Particle", .BackToFront, .Blended);
		Register("WorldUI", .BackToFront, .PostTonemap);
	}

	/// The ONE registry.
	///
	/// Shared rather than per module: the producers register categories and the sorter reads
	/// them, and two copies would disagree about the ids, which sorts a draw into the wrong
	/// pass rather than failing.
	public static CategoryRegistry Instance
	{
		get
		{
			if (sInstance == null)
				sInstance = new CategoryRegistry();
			return sInstance;
		}
	}

	public uint16 Count => mCount;

	/// Idempotent by NAME: registering a name that is taken hands back the id it already has.
	/// The maximum comes back when there is no room, which a caller treats as a refusal.
	public uint16 Register(StringView name, SortMode sort, PassAffinity affinity)
	{
		for (uint16 i = 0; i < mCount; i++)
		{
			if (mInfo[i].Name == name)
				return i;
		}

		if (mCount >= RenderCategories.MaxCategories)
			return RenderCategories.MaxCategories;

		let id = mCount;
		mInfo[id] = .(name, sort, affinity);
		mCount++;
		return id;
	}

	public SortMode Sort(uint16 category) =>
		(category < mCount) ? mInfo[category].Sort : SortMode.FrontToBack;

	public PassAffinity Affinity(uint16 category) =>
		(category < mCount) ? mInfo[category].Affinity : PassAffinity.None;

	public StringView Name(uint16 category) => (category < mCount) ? mInfo[category].Name : "";
}
