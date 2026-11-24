using System;
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
	/// camera for as long as its section runs. The camera pick takes the winning claim's camera
	/// before the primary one (SceneClaims says which wins).
	public SceneClaims<EntityHandle> ViewClaims => mViewClaims;
	private SceneClaims<EntityHandle> mViewClaims = new .() ~ delete _;

	/// The camera the winning claim names; unassigned when no claim is held.
	public EntityHandle ClaimedView => mViewClaims.Winning(let camera) ? camera : .Invalid;
}
