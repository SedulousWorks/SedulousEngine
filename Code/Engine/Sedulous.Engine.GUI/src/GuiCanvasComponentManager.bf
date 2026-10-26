using Sedulous.Scene;

namespace Sedulous.Engine.GUI;

/// The pool of GUI canvases.
///
/// The tree and its host are the SUBSYSTEM's to build, not this pool's: building one needs the
/// GUI's context, which a headless scene consumer never has.
class GuiCanvasComponentManager : ResourceBindingComponentManager<GuiCanvasComponent>
{
	/// A built canvas holds its OWN reference to the tree, the host and the render texture's
	/// root, beside the ones the scene's root holds. The subsystem drops that half when it
	/// rebuilds a canvas or when the scene goes, but a component that is simply REMOVED reaches
	/// neither: it would leave the pool with its half still held, and the tree never go.
	///
	/// Only the component's own half goes here; taking the host out of the scene's root is the
	/// subsystem's, in its sweep of what no component claims.
	protected override void OnComponentDestroyed(GuiCanvasComponent* component, EntityHandle entity)
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

		// Borrowed: the resource manager owns the products.
		component.BuiltFrom = null;
		component.SheetFrom = null;
	}
}
