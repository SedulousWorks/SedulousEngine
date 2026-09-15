using Sedulous.Scene;

namespace Sedulous.Engine.UI;

/// The pool of world anchored billboards, under the same split as the canvases.
class UIBillboardComponentManager : ResourceBindingComponentManager<UIBillboardComponent>
{
	/// See UICanvasComponentManager: the component holds its own reference to the tree, and a
	/// removal would otherwise carry it out of the pool unreleased. The billboard layer's own
	/// half is dropped by the subsystem's sweep, which removes whatever nothing claims.
	protected override void OnComponentDestroyed(UIBillboardComponent* component,
		EntityHandle entity)
	{
		if (component.Root != null)
		{
			component.Root.ReleaseRef();
			component.Root = null;
		}

		component.BuiltFrom = null;
	}
}
