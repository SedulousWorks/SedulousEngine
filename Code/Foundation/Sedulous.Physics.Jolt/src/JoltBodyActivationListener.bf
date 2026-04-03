namespace Sedulous.Physics.Jolt;

using System;
using joltc_Beef;
using Sedulous.Physics;

/// Internal wrapper for JPH_BodyActivationListener that forwards events to IBodyActivationListener.
class JoltBodyActivationListener
{
	private static bool sProcsInitialized = false;
	private static JPH_BodyActivationListener_Procs sProcs;

	private JPH_BodyActivationListener* mListener;
	private JoltPhysicsWorld mWorld;
	private IBodyActivationListener mUserListener;

	public this(JoltPhysicsWorld world, IBodyActivationListener userListener)
	{
		mWorld = world;
		mUserListener = userListener;

		// Initialize global procs once
		InitializeProcs();

		// Create the listener with this wrapper as user data
		mListener = JPH_BodyActivationListener_Create(Internal.UnsafeCastToPtr(this));
	}

	public ~this()
	{
		if (mListener != null)
		{
			JPH_BodyActivationListener_Destroy(mListener);
			mListener = null;
		}
	}

	public JPH_BodyActivationListener* GetHandle() => mListener;

	private static void InitializeProcs()
	{
		if (sProcsInitialized)
			return;

		sProcs = .();
		sProcs.OnBodyActivated = => OnBodyActivatedCallback;
		sProcs.OnBodyDeactivated = => OnBodyDeactivatedCallback;

		JPH_BodyActivationListener_SetProcs(&sProcs);
		sProcsInitialized = true;
	}

	private static void OnBodyActivatedCallback(void* userData, JPH_BodyID bodyID, uint64 bodyUserData)
	{
		let wrapper = Internal.UnsafeCastToObject(userData) as JoltBodyActivationListener;
		if (wrapper == null || wrapper.mUserListener == null)
			return;

		// Get handle from body ID
		let handle = wrapper.mWorld.[Friend]GetBodyHandleFromId(bodyID);
		if (!handle.IsValid)
			return;

		wrapper.mUserListener.OnBodyActivated(handle);
	}

	private static void OnBodyDeactivatedCallback(void* userData, JPH_BodyID bodyID, uint64 bodyUserData)
	{
		let wrapper = Internal.UnsafeCastToObject(userData) as JoltBodyActivationListener;
		if (wrapper == null || wrapper.mUserListener == null)
			return;

		// Get handle from body ID
		let handle = wrapper.mWorld.[Friend]GetBodyHandleFromId(bodyID);
		if (!handle.IsValid)
			return;

		wrapper.mUserListener.OnBodyDeactivated(handle);
	}
}
