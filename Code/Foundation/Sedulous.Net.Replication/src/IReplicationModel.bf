using Sedulous.Net;
using Sedulous.Scene;

namespace Sedulous.Net.Replication;

/// The seam a replication architecture implements: StateReplication, which sends server
/// authoritative property snapshots, against a CommandReplication that would send lockstep
/// input instead.
///
/// A snapshot is written on the server and applied on the client, both over the bit stream.
interface IReplicationModel
{
	void CaptureSnapshot(Scene scene, BitWriter outWriter);
	void ApplySnapshot(Scene scene, BitReader reader);
}
