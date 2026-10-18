using System;
using System.Collections;

namespace Sedulous.Fonts;

/// The process-wide choice of text shaper: a backend registers how to make one, the one
/// registered last wins (a fuller shaper over the basic one), and font services ask here for
/// the shaper each font gets. Null with none registered: the service uses its own default.
static class TextShaperFactory
{
	public typealias Creator = function ITextShaper();

	private static List<Creator> sCreators = new .() ~ delete _;

	public static void Register(Creator creator)
	{
		if (creator == null)
			return;
		Unregister(creator);
		sCreators.Add(creator);
	}

	public static void Unregister(Creator creator) => sCreators.Remove(creator);

	/// A new shaper from the backend registered last, which the caller owns; null when none is.
	public static ITextShaper Create()
	{
		if (sCreators.IsEmpty)
			return null;
		let creator = sCreators.Back;
		return creator();
	}

	public static int Count => sCreators.Count;
}
