using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Navigation.Pipeline;

/// The baked navmesh for one zone.
///
/// The blob is deliberately NOT stored inline: it is bulk, and the envelope can be text. It
/// travels in a sidecar stream beside the envelope instead, and NavigationZoneStorage is what
/// keeps the two in step.
///
/// Zones are authored in the scene, so the file name a plain asset carries goes unused.
[Serializable]
class NavigationZoneAsset : Asset
{
	/// The baked navmesh, being its header and its tiles. FILLED FROM THE SIDECAR on load, and
	/// skipped by the generated body below because it is marked as ignored.
	[NotSerialized]
	public List<uint8> NavMeshBlob = new .() ~ delete _;
}
