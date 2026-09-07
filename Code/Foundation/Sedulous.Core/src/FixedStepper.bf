namespace Sedulous.Core;

/// The fixed timestep accumulator.
///
/// Pure: it has no clock and the caller feeds it the frame time, which is what lets a
/// scene scale its own time independently and lets a test drive it exactly.
///
/// Advance drains whole steps and CLAMPS how many it reports. The excess time is DROPPED,
/// not carried: carrying it means a frame that ran long asks for more steps next frame,
/// which makes the next frame longer still. That is the spiral of death, and dropping time
/// is the only way out of it. A simulation that falls behind runs in slow motion, which is
/// survivable; one that spirals stops responding.
struct FixedStepper
{
	/// Sixty hertz.
	public float Step = 1.0f / 60.0f;
	/// The hitch clamp.
	public uint32 MaxSteps = 4;
	public float Accumulator = 0.0f;

	public this() { Step = 1.0f / 60.0f; MaxSteps = 4; Accumulator = 0.0f; }

	public this(float step, uint32 maxSteps)
	{
		Step = step; MaxSteps = maxSteps; Accumulator = 0.0f;
	}

	/// How many fixed steps this frame's time earns.
	public uint32 Advance(float deltaTime) mut
	{
		// A zero or negative step would loop forever on any positive time at all.
		if (Step <= 0.0f)
		{
			Accumulator = 0.0f;
			return 0;
		}

		// Negative time is not a thing, and adding it would wind the accumulator
		// backwards.
		if (deltaTime > 0.0f)
			Accumulator += deltaTime;

		uint32 steps = 0;
		while (Accumulator >= Step)
		{
			Accumulator -= Step;
			steps++;
		}

		// Clamped AFTER the drain, so the time beyond the clamp is gone rather than owed.
		if (steps > MaxSteps)
			steps = MaxSteps;
		return steps;
	}

	/// How far into the next step the leftover time reaches, in [0, 1).
	///
	/// The interpolation weight for anything blending fixed rate state into a variable
	/// rate frame: without it, physics at sixty hertz rendered at a hundred and forty four
	/// visibly stutters.
	public float Alpha => (Step > 0.0f) ? (Accumulator / Step) : 0.0f;
}
