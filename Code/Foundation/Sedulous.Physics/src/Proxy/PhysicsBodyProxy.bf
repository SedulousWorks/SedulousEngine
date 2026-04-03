namespace Sedulous.Physics;

using Sedulous.Core.Mathematics;

/// Physics body proxy struct storing synchronized data.
/// Similar to StaticMeshProxy in the Renderer.
/// Stored in dense arrays for cache efficiency.
struct PhysicsBodyProxy
{
	/// Unique ID for this proxy (matches array index when valid).
	public uint32 Id;

	/// Handle to the actual physics body in the physics world.
	public BodyHandle BodyHandle;

	/// Associated entity ID (for Engine integration).
	public uint64 EntityId;

	/// Body motion type.
	public BodyType BodyType;

	/// Last synced position.
	public Vector3 LastPosition;

	/// Last synced rotation.
	public Quaternion LastRotation;

	/// Last synced linear velocity.
	public Vector3 LastLinearVelocity;

	/// Last synced angular velocity.
	public Vector3 LastAngularVelocity;

	/// Proxy behavior flags.
	public PhysicsProxyFlags Flags;

	/// Creates an invalid proxy.
	public static Self Invalid
	{
		get
		{
			Self p = default;
			p.Id = uint32.MaxValue;
			p.BodyHandle = .Invalid;
			p.EntityId = uint64.MaxValue;
			p.BodyType = .Static;
			p.LastPosition = .Zero;
			p.LastRotation = .Identity;
			p.LastLinearVelocity = .Zero;
			p.LastAngularVelocity = .Zero;
			p.Flags = .None;
			return p;
		}
	}

	/// Checks if this proxy is valid.
	public bool IsValid => Id != uint32.MaxValue && BodyHandle.IsValid;

	/// Checks if this proxy is active.
	public bool IsActive => (Flags & .Active) != 0;

	/// Checks if this proxy is dirty.
	public bool IsDirty => (Flags & .Dirty) != 0;

	/// Checks if this proxy is sleeping.
	public bool IsSleeping => (Flags & .Sleeping) != 0;
}
