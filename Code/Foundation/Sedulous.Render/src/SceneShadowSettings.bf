namespace Sedulous.Render;

/// A scene's directional shadow reach, from its environment settings: how far from the camera
/// the cascades cover (clamped to the camera's far plane, but independent of how far the
/// camera sees, so a near cascade's texels stay small), how the splits blend (nought uniform,
/// one logarithmic) and the width of the soft edge the shadow fades over at the reach.
struct SceneShadowSettings
{
	public float Distance = 300.0f;
	public float CascadeSplit = 0.5f;
	public float FadeDistance = 40.0f;

	public this() {}

	public this(float distance, float cascadeSplit, float fadeDistance)
	{
		Distance = distance;
		CascadeSplit = cascadeSplit;
		FadeDistance = fadeDistance;
	}
}
