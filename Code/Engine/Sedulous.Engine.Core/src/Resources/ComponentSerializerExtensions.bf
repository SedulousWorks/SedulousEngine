namespace Sedulous.Engine.Core;

using System;
using Sedulous.Resources;

/// Extends IComponentSerializer with resource-related serialization methods.
/// Available when Sedulous.Engine.Core is imported.
extension IComponentSerializer
{
	/// Serializes a ResourceRef (Guid + path) as a nested object.
	public void ResourceRef(StringView name, ref Sedulous.Resources.ResourceRef value) mut
	{
		BeginObject(name);

		var id = value.Id;
		Guid("_id", ref id);

		let path = (value.Path != null) ? value.Path : scope:: String();
		String("path", path);

		if (IsReading)
		{
			value.Id = id;
			if (value.Path == null)
				value.Path = new String(path);
			else
				value.Path.Set(path);
		}

		EndObject();
	}
}
