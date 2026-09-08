using Sedulous.Core;

namespace Sedulous.Scene;

/// One entity's place in the hierarchy: its local transform, its cached world matrices,
/// and its links.
///
/// The links are a DOUBLY LINKED tree, with head, tail and back pointers, so a splice
/// costs O(1) rather than a walk to find a predecessor or the end of a sibling list.
struct TransformData
{
	public Transform Local = .();
	public Float4x4 WorldMatrix = Float4x4.Identity();
	/// Last frame's world matrix, which is what a motion vector needs.
	public Float4x4 PrevWorldMatrix = Float4x4.Identity();

	public EntityHandle Parent = .Invalid;
	public EntityHandle FirstChild = .Invalid;
	public EntityHandle LastChild = .Invalid;
	public EntityHandle NextSibling = .Invalid;
	public EntityHandle PrevSibling = .Invalid;

	public bool Dirty = false;
	public bool UpdatedThisFrame = false;

	public this() {}
}
