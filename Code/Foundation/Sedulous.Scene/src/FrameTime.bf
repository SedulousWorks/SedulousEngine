namespace Sedulous.Scene;

/// The ONE value carrying the scene lane's time scale chain, host by context by group by
/// scene, plus the lane's configured fixed step.
///
/// It exists so the chain is not hand multiplied in several places independently, which is
/// how the terms drift apart. The fixed step ACCUMULATOR stays per scene, since each scene
/// owns its own; the step here is configuration published alongside the scales.
///
/// "Context" is the application level term, handed down as a plain float. Scene stays
/// runtime free and never sees a runtime type: this is CONSTRUCTED at the engine bridge.
struct FrameTime
{
	/// The host's delta, unscaled.
	public float RawDelta = 0.0f;
	/// The application wide term.
	public float ContextScale = 1.0f;
	/// The group, or instance, term.
	public float GroupScale = 1.0f;
	/// The per scene term.
	public float SceneScale = 1.0f;
	public float FixedStep = 1.0f / 60.0f;

	public this() {}

	public this(float rawDelta, float contextScale = 1.0f, float groupScale = 1.0f,
		float sceneScale = 1.0f, float fixedStep = 1.0f / 60.0f)
	{
		RawDelta = rawDelta;
		ContextScale = contextScale;
		GroupScale = groupScale;
		SceneScale = sceneScale;
		FixedStep = fixedStep;
	}

	/// What a context level subsystem sees on the variable lane: host by context.
	public float ContextDelta => RawDelta * ContextScale;

	/// What a scene's variable lane sees: the whole chain.
	public float SceneDelta => RawDelta * ContextScale * GroupScale * SceneScale;
}
