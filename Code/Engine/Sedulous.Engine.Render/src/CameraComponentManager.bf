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
}
