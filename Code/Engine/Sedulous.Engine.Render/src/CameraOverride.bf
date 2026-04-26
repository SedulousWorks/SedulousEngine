namespace Sedulous.Engine.Render;

using Sedulous.Core.Mathematics;

/// External camera data for rendering without a scene camera entity.
/// Pass to ISceneRenderer.RenderScene to override the scene's active camera.
public struct CameraOverride
{
	public Matrix ViewMatrix;
	public Matrix ProjectionMatrix;
	public Vector3 CameraPosition;
	public float NearPlane;
	public float FarPlane;
}
