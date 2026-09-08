namespace Sedulous.Runtime.Client;

/// Loop level settings: frame pacing, and nothing else.
///
/// How the MAIN WINDOW presents is not here. That is a RenderWindowDesc, the same one a
/// runtime window takes, supplied by IApplication.MainRenderWindow, so both configure
/// through one path.
struct ApplicationSettings
{
	public float FixedTimeStep = 1.0f / 60.0f;

	/// The per frame clamp that avoids the spiral of death.
	public float MaxFrameTime = 0.25f;

	/// The catch up cap at the ACCUMULATOR: time past this is DROPPED, so a hitch, a
	/// debugger pause, never cascades into a storm of steps. Independent of the runner's
	/// MaxFrameTime clamp.
	public uint32 MaxFixedStepsPerFrame = 4;

	public this() {}
}
