using System;
using System.Collections;

namespace Sedulous.Scene;

/// Networked state a component manager supplies itself, for what its reflection does not
/// describe (a script behaviour's properties, declared by the script). Replication sends the
/// bytes it writes for a networked entity, compares them with what each peer last had, and
/// hands them back on every peer; the bytes are the manager's own format. Replication lives
/// above the scene and the scene does not depend on it: a manager keeps its own networked
/// state.
interface IReplicatedStateSource
{
	/// Writes `entity`'s networked state into `outState` (cleared first); false when it has
	/// none, and nothing is sent.
	bool WriteReplicatedState(EntityHandle entity, List<uint8> outState);

	/// Applies state a peer wrote for `entity`.
	void ReadReplicatedState(EntityHandle entity, Span<uint8> state);
}
