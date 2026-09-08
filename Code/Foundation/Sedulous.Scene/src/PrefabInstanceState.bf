using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Scene;

/// The runtime record of one spawned prefab instance.
///
/// `SourceIds[i]` is a member's guid in the PREFAB PAYLOAD, which is the stable key a
/// delta is written against, and `LiveIds[i]` is the same member's guid in this scene.
///
/// The baselines capture the template's state at spawn, and the scene serializer DIFFS
/// live state against them when saving. So an override is DERIVED: nothing tracks an edit,
/// and undo can never leave the override set disagreeing with what is actually there.
///
/// Never serialized as it stands. A scene persists an instance as a reference plus deltas,
/// or expanded for a snapshot, and rebuilds this on load.
class PrefabInstanceState
{
	/// The prefab asset, and the live root this instance hangs from.
	public Guid PrefabId = .();
	public Guid RootEntityId = .();

	/// Parallel: payload guid to live guid.
	public List<Guid> SourceIds = new .() ~ delete _;
	public List<Guid> LiveIds = new .() ~ delete _;

	/// The template's local transforms, parallel to SourceIds.
	public List<Transform> BaselineTransforms = new .() ~ delete _;
	public List<PrefabComponentBaseline> ComponentBaselines = new .() ~ DeleteContainerAndItems!(_);

	/// Component operations whose manager was absent when the instance spawned, such as a
	/// plugin's types. Kept so the next save re-emits them, and applied the moment the
	/// manager arrives.
	public List<PendingPrefabComponentOp> UnresolvedComponentOps
		= new .() ~ DeleteContainerAndItems!(_);

	/// NESTING. An instance spawned BY another instance's payload links to its owner, and
	/// NestedRootSourceId is this instance's identity in the OWNER's namespace, which is
	/// what a rebuild matches on. Nil means top level.
	public Guid OwnerRootEntityId = .();
	public Guid NestedRootSourceId = .();

	/// Top level only, and TRANSIENT, recomputed at spawn: every prefab this instance's
	/// payload consumed, its own and its nested ones. A template edit to any of them
	/// rebuilds this instance through its owner.
	public List<Guid> ReferencedPrefabIds = new .() ~ delete _;
}
