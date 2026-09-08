namespace Sedulous.Input;

/// Conditioning applied to an action's folded value each frame.
struct ActionProcessors
{
	/// Above zero, a key driven axis RAMPS toward its target at this much per second
	/// rather than snapping. What gives a keyboard the feel of a stick.
	public float Sensitivity = 0.0f;

	/// Above zero, the rate the value recenters at when the target is zero. Falls back to
	/// Sensitivity when unset, so a ramp up without a stated ramp down is symmetric.
	public float Gravity = 0.0f;

	/// Zero the value first when the direction flips, so a reversal is immediate instead of
	/// having to travel back through the middle.
	public bool Snap = false;

	/// An analog response curve: the sign kept, the magnitude raised to this power. Above
	/// one gives fine control near the centre, which is what a stick wants for aiming.
	public float ResponseExponent = 1.0f;

	/// Whether the value follows a global time scale. STORED but not yet applied: there is
	/// no time scale system for it to read, and a flag that silently did nothing would be
	/// worse than one that is honestly waiting.
	public bool TimeScale = false;

	public this() {}
}
