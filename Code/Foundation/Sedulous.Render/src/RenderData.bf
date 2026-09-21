using Sedulous.Core;

namespace Sedulous.Render;

/// One unit of renderable work.
///
/// Render data is EXTRACTED AND PUSHED to the renderer, which never reaches back into a
/// scene: the dependency runs one way, and that is what keeps the renderer scene agnostic.
///
/// Allocated from a frame arena, valid for exactly one frame, and carrying NO VIEW DEPENDENT
/// state: the sort key depends on the camera and so lives on a per view draw item, worked out
/// while that view culls and sorts against the shared snapshot.
///
/// Dispatch is by category rather than by virtual call: the registered renderer knows the
/// concrete type and casts, so there is no call through a table per draw.
class RenderData
{
	public uint16 Category = RenderCategories.Opaque;

	/// WHICH RENDERER draws this, which is the per item DISPATCH key: several renderers can
	/// share a category, sprites and transparent meshes both being blended, and still be
	/// routed correctly. The default is the first registered one, the mesh renderer in the
	/// standard subsystem, so mesh data needs no change. That is a dispatch default and NOT a
	/// type: a frame registering another renderer first routes id nought there. Another
	/// producer stamps its own renderer's id. Never infer the concrete type from it; read Kind.
	public uint16 RendererId = 0;

	/// What this data IS, stamped by the subtype's constructor. See RenderDataKind.
	public RenderDataKind Kind = .Generic;

	/// The world space point the depth sort is measured to, read GENERICALLY by the draw list
	/// builder rather than by casting to a concrete type.
	public Float3 WorldCenter = .(0, 0, 0);
	/// The bounding radius about that point, which is what the view frustum culls against.
	public float WorldRadius = 0.0f;
	/// Folds a mesh and material identity into the sort, so same state draws stay contiguous.
	/// Opaque work only: blended work zeroes it, since depth has to dominate there.
	public uint32 SortBatchKey = 0;
	/// The producer's entity tag, in EntityTag's layout: what the GPU pick pass writes and its
	/// readback decodes. Nought is untagged. Every producer whose draws should be pickable
	/// stamps it: meshes, instanced sets, terrain.
	public uint64 EntityId = 0;
}

/// The one layout of the tag a producer stamps on RenderData for picking: the scene entity's
/// slot index in the low word, its generation in the high word. Producers pack, the pick
/// readback unpacks; nothing in between interprets it.
static class EntityTag
{
	public static uint64 Pack(uint32 index, uint32 generation) =>
		((uint64)generation << 32) | (uint64)index;
	public static uint32 Index(uint64 tag) => (uint32)(tag & 0xFFFFFFFF);
	public static uint32 Generation(uint64 tag) => (uint32)(tag >> 32);
}
