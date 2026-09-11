using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Resource;

namespace Sedulous.UI.Resource;

/// Builds a cooked UI theme record into a runtime theme.
class UIThemeFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<UITheme>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => Build(instance);

	public Object DecodeStage(Instance instance) => Build(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object Build(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		defer delete stored;

		let record = stored as UIThemeResource;
		if (record == null)
			return null;

		let theme = new UITheme();
		theme.StyleSheet.Set(record.StyleSheet);
		return theme;
	}
}
