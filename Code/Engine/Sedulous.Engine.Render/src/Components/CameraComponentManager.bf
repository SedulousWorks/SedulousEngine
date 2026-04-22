namespace Sedulous.Engine.Render;

using Sedulous.Engine.Core;
using Sedulous.Core.Mathematics;
using System;

/// Manages camera components.
/// The RenderSubsystem queries this to find the active camera for building the RenderView.
/// Not an IRenderDataProvider - cameras don't produce render data, they define the viewpoint.
class CameraComponentManager : ComponentManager<CameraComponent>
{
	public override StringView SerializationTypeId => "Sedulous.CameraComponent";

	/// Finds the first active camera component. Returns null if none.
	public CameraComponent GetActiveCamera()
	{
		for (let camera in ActiveComponents)
		{
			if (camera.IsActive && camera.IsActiveCamera)
				return camera;
		}
		return null;
	}
}
