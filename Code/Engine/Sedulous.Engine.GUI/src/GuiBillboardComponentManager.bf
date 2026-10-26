using Sedulous.Scene;

namespace Sedulous.Engine.GUI;

/// The pool of GUI billboards, under the same split as the canvases.
class GuiBillboardComponentManager : ResourceBindingComponentManager<GuiBillboardComponent>
{
	/// See GuiCanvasComponentManager: the component holds its own reference to the tree, and a
	/// removal would otherwise carry it out of the pool unreleased. The billboard layer's half
	/// is the subsystem's, dropped in its sweep of what no component claims.
	protected override void OnComponentDestroyed(GuiBillboardComponent* component, EntityHandle entity)
	{
		if (component.Root != null)
		{
			component.Root.ReleaseRef();
			component.Root = null;
		}

		component.BuiltFrom = null;
		component.SheetFrom = null;
	}
}
