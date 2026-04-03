namespace Sedulous.Physics;

/// Flags for physics proxy behavior and state.
enum PhysicsProxyFlags : uint8
{
	/// No flags set.
	None = 0,

	/// Proxy is active and should be updated.
	Active = 1 << 0,

	/// Proxy data has been modified and needs sync.
	Dirty = 1 << 1,

	/// Body is currently sleeping.
	Sleeping = 1 << 2,

	/// Transform sync is disabled for this proxy.
	SyncDisabled = 1 << 3,

	/// Body is a sensor (trigger).
	Sensor = 1 << 4
}
