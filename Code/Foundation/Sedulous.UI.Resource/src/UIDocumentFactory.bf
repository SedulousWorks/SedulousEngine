using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Resource;

namespace Sedulous.UI.Resource;

/// Builds a cooked UI document record into a runtime document.
class UIDocumentFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<UIDocument>();

	/// The whole build is a string copy out of the stored record: nothing global is touched
	/// and no device is needed, so it runs entirely on a worker.
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

		let record = stored as UIDocumentResource;
		if (record == null)
			return null;

		let document = new UIDocument();
		document.Markup.Set(record.Markup);
		return document;
	}
}
