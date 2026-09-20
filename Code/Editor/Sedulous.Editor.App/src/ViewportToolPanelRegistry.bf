using System;
using System.Collections;

namespace Sedulous.Editor.App;

/// The registry of tool-panel providers, keyed by tool id. `Global` is the process-wide
/// instance the scene page consumes; a private one lets a test exercise a host against its
/// own providers.
class ViewportToolPanelRegistry
{
	public static ViewportToolPanelRegistry Global = new .() ~ delete _;

	/// Borrowed, static lifetime.
	private List<IViewportToolPanelProvider> mProviders = new .() ~ delete _;

	public int Count => mProviders.Count;

	/// Idempotent on the same provider; a second provider for an already-registered tool id
	/// is ignored, first wins, so a double-registered registrar cannot swap a page's panel.
	public void Register(IViewportToolPanelProvider provider)
	{
		if (provider == null)
			return;
		for (let existing in mProviders)
		{
			if (existing === provider)
				return;
			if (existing.ToolId == provider.ToolId)
				return;
		}
		mProviders.Add(provider);
	}

	/// The provider for a tool id, or null when that tool has no panel.
	public IViewportToolPanelProvider FindByToolId(StringView toolId)
	{
		for (let provider in mProviders)
		{
			if (provider.ToolId == toolId)
				return provider;
		}
		return null;
	}
}
