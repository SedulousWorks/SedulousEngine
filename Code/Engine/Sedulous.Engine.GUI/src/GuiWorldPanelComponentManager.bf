using Sedulous.Scene;

namespace Sedulous.Engine.GUI;

/// The pool of GUI world panels, under the same split as the canvases.
class GuiWorldPanelComponentManager : ResourceBindingComponentManager<GuiWorldPanelComponent>
{
	/// See GuiCanvasComponentManager: only the component's own half goes here, the texture and
	/// the root's input being the subsystem's to sweep.
	protected override void OnComponentDestroyed(GuiWorldPanelComponent* component, EntityHandle entity)
	{
		if (component.Root != null)
		{
			component.Root.ReleaseRef();
			component.Root = null;
		}

		if (component.RenderRoot != null)
		{
			component.RenderRoot.ReleaseRef();
			component.RenderRoot = null;
		}

		component.BuiltFrom = null;
		component.SheetFrom = null;
	}
}
