using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Putting the validation layer over a backend.
static class ValidationRhi
{
	/// Wraps `inner` so every object reached through it is checked.
	///
	/// The layer is TRANSPARENT: it forwards everything and changes no result, so a caller
	/// can wrap in a debug build and not wrap in a release one without touching a line of
	/// its own code. What it adds is reporting, through ValidationLog.
	///
	/// The wrapper does NOT own `inner`: whoever created the backend still destroys it.
	public static IBackend Wrap(IBackend inner)
	{
		if (inner == null)
		{
			ValidationLog.Error("ValidationRhi.Wrap: the inner backend is null");
			return null;
		}
		return new ValidatedBackend(inner);
	}
}
