namespace Sedulous.Editor.ViewportTools;

/// A domain editor lib's tool contribution ("Editor.Terrain adds sculpt and splat").
/// Registered explicitly from the lib's registrar, never discovered.
interface IViewportToolProvider
{
	/// Creates this provider's tools into the manager for one host; once per page.
	void CreateTools(ViewportToolManager manager, in ViewportToolHostContext context);
}
