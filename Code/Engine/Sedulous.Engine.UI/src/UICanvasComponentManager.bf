using Sedulous.Scene;

namespace Sedulous.Engine.UI;

/// The pool of screen space canvases.
///
/// The per canvas view tree and its host are the SUBSYSTEM's, not this pool's: building one
/// needs a UI context, which a headless scene consumer never has.
class UICanvasComponentManager : ResourceBindingComponentManager<UICanvasComponent>
{
	/// A built canvas holds its OWN reference to the tree, the host and the standalone render
	/// root, alongside the references the tree and the registry hold. The subsystem drops that
	/// half when it rebuilds a canvas or when the scene dies, but a component that is simply
	/// REMOVED reaches neither: it leaves the pool with its half still held, and the whole view
	/// subtree under it never comes back.
	///
	/// Only the component's own half goes here. The context registration and the registry's
	/// keep alive belong to the subsystem, and its per frame sweep takes both once the entry
	/// stops being claimed.
	protected override void OnComponentDestroyed(UICanvasComponent* component, EntityHandle entity)
	{
		if (component.Root != null)
		{
			component.Root.ReleaseRef();
			component.Root = null;
		}

		if (component.Host != null)
		{
			component.Host.ReleaseRef();
			component.Host = null;
		}

		if (component.RenderRoot != null)
		{
			component.RenderRoot.ReleaseRef();
			component.RenderRoot = null;
		}

		// Back pointers: the view they were installed on owns them.
		component.ThemeSheet = null;
		component.BuiltFrom = null;
		component.ThemeFrom = null;
	}
}
