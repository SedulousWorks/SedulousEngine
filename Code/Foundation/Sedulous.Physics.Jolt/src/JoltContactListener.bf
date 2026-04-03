namespace Sedulous.Physics.Jolt;

using System;
using joltc_Beef;
using Sedulous.Core.Mathematics;
using Sedulous.Physics;

/// Internal wrapper for JPH_ContactListener that forwards events to IContactListener.
class JoltContactListener
{
	private static bool sProcsInitialized = false;
	private static JPH_ContactListener_Procs sProcs;

	private JPH_ContactListener* mListener;
	private JoltPhysicsWorld mWorld;
	private IContactListener mUserListener;

	public this(JoltPhysicsWorld world, IContactListener userListener)
	{
		mWorld = world;
		mUserListener = userListener;

		// Initialize global procs once
		InitializeProcs();

		// Create the listener with this wrapper as user data
		mListener = JPH_ContactListener_Create(Internal.UnsafeCastToPtr(this));
	}

	public ~this()
	{
		if (mListener != null)
		{
			JPH_ContactListener_Destroy(mListener);
			mListener = null;
		}
	}

	public JPH_ContactListener* GetHandle() => mListener;

	private static void InitializeProcs()
	{
		if (sProcsInitialized)
			return;

		sProcs = .();
		sProcs.OnContactValidate = => OnContactValidateCallback;
		sProcs.OnContactAdded = => OnContactAddedCallback;
		sProcs.OnContactPersisted = => OnContactPersistedCallback;
		sProcs.OnContactRemoved = => OnContactRemovedCallback;

		JPH_ContactListener_SetProcs(&sProcs);
		sProcsInitialized = true;
	}

	private static JPH_ValidateResult OnContactValidateCallback(
		void* userData,
		JPH_Body* body1,
		JPH_Body* body2,
		JPH_RVec3* baseOffset,
		JPH_CollideShapeResult* collisionResult)
	{
		// Always accept contacts by default
		return .JPH_ValidateResult_AcceptAllContactsForThisBodyPair;
	}

	private static void OnContactAddedCallback(
		void* userData,
		JPH_Body* body1,
		JPH_Body* body2,
		JPH_ContactManifold* manifold,
		JPH_ContactSettings* settings)
	{
		let wrapper = Internal.UnsafeCastToObject(userData) as JoltContactListener;
		if (wrapper == null || wrapper.mUserListener == null)
			return;

		// Get body IDs
		let bodyId1 = JPH_Body_GetID(body1);
		let bodyId2 = JPH_Body_GetID(body2);

		// Get handles
		let handle1 = wrapper.mWorld.[Friend]GetBodyHandleFromId(bodyId1);
		let handle2 = wrapper.mWorld.[Friend]GetBodyHandleFromId(bodyId2);

		if (!handle1.IsValid || !handle2.IsValid)
			return;

		// Build contact event
		let contactEvent = BuildContactEvent(manifold);

		// Call user listener
		wrapper.mUserListener.OnContactAdded(handle1, handle2, contactEvent);
	}

	private static void OnContactPersistedCallback(
		void* userData,
		JPH_Body* body1,
		JPH_Body* body2,
		JPH_ContactManifold* manifold,
		JPH_ContactSettings* settings)
	{
		let wrapper = Internal.UnsafeCastToObject(userData) as JoltContactListener;
		if (wrapper == null || wrapper.mUserListener == null)
			return;

		// Get body IDs
		let bodyId1 = JPH_Body_GetID(body1);
		let bodyId2 = JPH_Body_GetID(body2);

		// Get handles
		let handle1 = wrapper.mWorld.[Friend]GetBodyHandleFromId(bodyId1);
		let handle2 = wrapper.mWorld.[Friend]GetBodyHandleFromId(bodyId2);

		if (!handle1.IsValid || !handle2.IsValid)
			return;

		// Build contact event
		let contactEvent = BuildContactEvent(manifold);

		// Call user listener
		wrapper.mUserListener.OnContactPersisted(handle1, handle2, contactEvent);
	}

	private static void OnContactRemovedCallback(
		void* userData,
		JPH_SubShapeIDPair* subShapePair)
	{
		let wrapper = Internal.UnsafeCastToObject(userData) as JoltContactListener;
		if (wrapper == null || wrapper.mUserListener == null)
			return;

		// Note: OnContactRemoved only gives us sub-shape pair, not body IDs
		// For now we pass invalid handles - this would need more work to track
		wrapper.mUserListener.OnContactRemoved(.Invalid, .Invalid);
	}

	private static ContactEvent BuildContactEvent(JPH_ContactManifold* manifold)
	{
		ContactEvent event;

		// Get normal
		JPH_Vec3 normal = default;
		JPH_ContactManifold_GetWorldSpaceNormal(manifold, &normal);
		event.Normal = JoltConversions.ToVector3(normal);

		// Get penetration depth
		event.PenetrationDepth = JPH_ContactManifold_GetPenetrationDepth(manifold);

		// Get first contact point if available
		let pointCount = JPH_ContactManifold_GetPointCount(manifold);
		if (pointCount > 0)
		{
			JPH_RVec3 point = default;
			JPH_ContactManifold_GetWorldSpaceContactPointOn1(manifold, 0, &point);
			event.Position = JoltConversions.ToVector3(point);
		}
		else
		{
			event.Position = .Zero;
		}

		// Simplified - relative velocity would need body velocities
		event.RelativeVelocity = .Zero;
		event.CombinedFriction = 0.5f;
		event.CombinedRestitution = 0.0f;

		return event;
	}
}
