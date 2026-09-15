using Sedulous.Scene;

namespace Sedulous.Engine.UI;

/// The pool of world panels, under the same split as the canvases.
class UIWorldPanelComponentManager : ResourceBindingComponentManager<UIWorldPanelComponent>
{
	/// See UICanvasComponentManager: only the component's own half goes here, the context
	/// registration and the registry's keep alive being the subsystem's to sweep.
	protected override void OnComponentDestroyed(UIWorldPanelComponent* component,
		EntityHandle entity)
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

		component.ThemeSheet = null;
		component.BuiltFrom = null;
		component.ThemeFrom = null;
	}
}
