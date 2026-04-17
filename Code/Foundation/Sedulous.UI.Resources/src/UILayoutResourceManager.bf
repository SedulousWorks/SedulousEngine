namespace Sedulous.UI.Resources;

using System;
using System.IO;
using Sedulous.Resources;
using System.Collections;

/// Loads UILayoutResource from UI XML files.
public class UILayoutResourceManager : ResourceManager<UILayoutResource>
{
	protected override Result<UILayoutResource, ResourceLoadError> LoadFromFile(StringView path)
	{
		let xmlText = new String();
		if (File.ReadAllText(path, xmlText) case .Err)
		{
			delete xmlText;
			return .Err(.NotFound);
		}

		let resource = new UILayoutResource();
		resource.XmlSource = xmlText;
		resource.Name.Set(path);
		resource.AddRef();
		return .Ok(resource);
	}

	protected override Result<UILayoutResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
	{
		let xmlText = new String();
		let bytes = scope List<uint8>();
		bytes.Count = (.)memory.Length;
		if (memory.TryRead(bytes) case .Err)
		{
			delete xmlText;
			return .Err(.ReadError);
		}
		xmlText.Append((char8*)bytes.Ptr, bytes.Count);

		let resource = new UILayoutResource();
		resource.XmlSource = xmlText;
		resource.AddRef();
		return .Ok(resource);
	}

	public override void Unload(UILayoutResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}
}
