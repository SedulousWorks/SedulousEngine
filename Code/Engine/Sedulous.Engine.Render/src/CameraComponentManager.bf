using System;
using System.Collections;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// The pool of cameras.
class CameraComponentManager : ResourceBindingComponentManager<CameraComponent>
{
	/// Points the entity's camera at the texture `id` (a render texture asset): it then draws
	/// into that texture instead of the screen. A nil id clears the target, so the camera may
	/// be the screen's again. Bound through the manager the scene was resolved with, as
	/// SetMesh binds. False for an entity without a camera.
	public bool SetTarget(EntityHandle entity, Guid id)
	{
		let component = Get(entity);
		if (component == null)
			return false;
		component.Target.SetId(id);
		component.Target.Rebind(Resources);
		return true;
	}

	/// Who may take the scene's view from its primary camera: a sequence's camera cut names a
	/// camera for as long as its section runs. Of the claims held, the highest order wins (the
	/// play begun last), and of equal orders the one claimed last (the shot cut to); when it lets
	/// go the view passes to the next, then back to the primary camera. Runtime state only: never
	/// saved with the scene.
	private struct ViewClaim
	{
		/// Compared, never dereferenced.
		public Object Holder;
		public uint64 Order;
		/// When it was claimed.
		public uint64 Serial;
		public EntityHandle Camera;
	}

	private List<ViewClaim> mViewClaims = new .() ~ delete _;
	private uint64 mNextClaimSerial = 1;

	/// Claims the view for `camera`, or moves `holder`'s claim to it with its new order.
	public void ClaimView(Object holder, uint64 order, EntityHandle camera)
	{
		for (var claim in ref mViewClaims)
		{
			if (claim.Holder == holder)
			{
				claim.Order = order;
				claim.Camera = camera;
				return;
			}
		}
		mViewClaims.Add(.() { Holder = holder, Order = order, Serial = mNextClaimSerial++, Camera = camera });
	}

	public void ReleaseView(Object holder)
	{
		for (int i < mViewClaims.Count)
		{
			if (mViewClaims[i].Holder == holder)
			{
				mViewClaims.RemoveAt(i);
				return;
			}
		}
	}

	/// The camera the winning claim names; unassigned when no claim is held.
	public EntityHandle ClaimedView
	{
		get
		{
			int best = -1;
			for (int i < mViewClaims.Count)
			{
				let claim = mViewClaims[i];
				if ((best < 0) || (claim.Order > mViewClaims[best].Order) ||
					((claim.Order == mViewClaims[best].Order) && (claim.Serial > mViewClaims[best].Serial)))
					best = i;
			}
			return (best >= 0) ? mViewClaims[best].Camera : .Invalid;
		}
	}
}
