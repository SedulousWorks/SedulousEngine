using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.UI.Resource;

/// Registration for the UI resource types.
///
/// Which factories a host wants stays the application's business, as everywhere else.
[SerializableRegistry]
static class UIResources
{
	/// The manager does not take ownership, so the caller keeps the factories alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, UIDocumentFactory documents,
		UIThemeFactory themes)
	{
		manager.AddFactory(documents);
		manager.AddFactory(themes);
	}
}
