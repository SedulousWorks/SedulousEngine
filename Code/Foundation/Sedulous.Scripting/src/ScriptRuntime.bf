using System;

namespace Sedulous.Scripting;

/// A script backend.
///
/// Thin by design: a backend is handed a surface and registers it. What a backend can do
/// beyond that, loading and calling, is added here as the first real VM lands and shapes
/// it; the null backend needs only the binding.
abstract class ScriptRuntime
{
	/// BORROWED for the runtime's life: the host owns the surface.
	protected ScriptSurface mSurface = null;

	public ScriptSurface Surface => mSurface;

	public abstract StringView Name { get; }

	/// Registers every type of the surface with the backend.
	public virtual void Bind(ScriptSurface surface)
	{
		mSurface = surface;
	}
}
