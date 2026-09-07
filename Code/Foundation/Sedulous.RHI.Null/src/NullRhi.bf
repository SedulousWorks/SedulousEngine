using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// Bringing the null backend up.
static class NullRhi
{
	/// A backend for headless work: tests, tooling, and CI boxes with no GPU.
	///
	/// The CALLER owns what comes back and deletes it when done. Destroy tears down what
	/// the backend holds but does not free the backend itself, matching the other backends.
	public static IBackend CreateBackend() => new NullBackend();
}
