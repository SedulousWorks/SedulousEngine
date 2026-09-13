using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Engine.Navigation;

/// The last bake's intermediate capture, in ZONE LOCAL space, with the entity that places it.
///
/// An editor's bake deposits this and the overlay draws it. TRANSIENT: it is never serialized,
/// because it describes how one bake ran rather than anything about the scene.
class NavigationBakeStageCache
{
	public EntityHandle ZoneEntity = .();
	/// Segment PAIRS.
	public List<Float3> ContourLines = new .() ~ delete _;
	/// One point per walkable span top.
	public List<Float3> WalkableSamples = new .() ~ delete _;

	public bool IsEmpty => ContourLines.IsEmpty && WalkableSamples.IsEmpty;

	public void Set(EntityHandle zoneEntity, Span<Float3> contourLines,
		Span<Float3> walkableSamples)
	{
		ZoneEntity = zoneEntity;

		ContourLines.Clear();
		ContourLines.AddRange(contourLines);

		WalkableSamples.Clear();
		WalkableSamples.AddRange(walkableSamples);
	}
}
