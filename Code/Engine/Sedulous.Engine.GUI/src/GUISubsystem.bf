namespace Sedulous.Engine.GUI;

using Sedulous.Runtime;
using Sedulous.Shell;
using Sedulous.Engine;

/// Owns the UI framework.
/// Not scene-aware — GUI is global, not per-scene.
/// Window-aware — needs to update layout on resize.
class GUISubsystem : Subsystem, IWindowAware
{
	public override int32 UpdateOrder => 400;

	protected override void OnInit()
	{
	}

	protected override void OnShutdown()
	{
	}

	public void OnWindowResized(IWindow window, int32 width, int32 height)
	{
		// TODO: update UI layout, projection, etc.
	}
}
