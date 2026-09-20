using System.Collections;

namespace Sedulous.Editor.ViewportTools;

/// The global provider registry. Pages call CreateAll after adding their default tool, so
/// provider tools can never become the default.
static class ViewportToolProviderRegistry
{
	/// Borrowed, static lifetime.
	private static List<IViewportToolProvider> sProviders = new .() ~ delete _;

	public static int Count => sProviders.Count;

	/// Duplicates are ignored, so a re-run registrar stays idempotent.
	public static void Register(IViewportToolProvider provider)
	{
		if (provider == null)
			return;
		for (let existing in sProviders)
		{
			if (existing === provider)
				return;
		}
		sProviders.Add(provider);
	}

	public static void CreateAll(ViewportToolManager manager, in ViewportToolHostContext context)
	{
		for (let provider in sProviders)
			provider.CreateTools(manager, context);
	}
}
