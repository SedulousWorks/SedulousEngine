using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Scene;

/// A prefab instance READ from a scene stream, waiting for its payload.
///
/// The scene serializer cannot resolve a prefab asset itself, having no database, so it
/// parks a descriptor here and the resolve pass respawns it with a caller supplied
/// resolver. The same two phase shape a component's resource reference follows.
class PendingPrefabInstance
{
	public Guid PrefabId = .();
	/// Nil means a scene root.
	public Guid ParentEntityId = .();
	public Transform RootTransform = .();

	/// Parallel member guid map, as captured.
	public List<Guid> SourceIds = new .() ~ delete _;
	public List<Guid> LiveIds = new .() ~ delete _;

	/// Source ids the user deleted out of the instance.
	public List<Guid> DestroyedMembers = new .() ~ delete _;

	/// Parallel: which members carry a transform override, and what it is.
	public List<Guid> OverrideTransformIds = new .() ~ delete _;
	public List<Transform> OverrideTransforms = new .() ~ delete _;

	public List<PendingPrefabComponentOp> ComponentOps = new .() ~ DeleteContainerAndItems!(_);

	/// NESTING, mirroring PrefabInstanceState. RootLiveId is the instance root's live id;
	/// in a payload record it is the owner namespace id a nested scene record matches.
	public Guid RootLiveId = .();
	public Guid OwnerRootEntityId = .();
	public Guid NestedRootSourceId = .();

	/// The sibling immediately AFTER the root when it was captured, nil when it was last.
	/// A spawn appends records after the plain members and then restores list order from
	/// this link.
	public Guid NextSiblingId = .();

	/// False means the root transform MATCHED its baseline when captured: the scene never
	/// moved this nested instance, so on respawn the owner template's placement wins. A
	/// moved root is a scene override and re-applies. A top level placement always applies,
	/// and reverting forces this false.
	public bool ApplyPlacement = true;
}
