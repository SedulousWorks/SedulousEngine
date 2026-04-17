namespace Sedulous.UI.Resources;

using System;
using System.IO;
using Sedulous.Resources;
using System.Collections;

/// Loads ThemeResource from theme XML files.
public class ThemeResourceManager : ResourceManager<ThemeResource>
{
	protected override Result<ThemeResource, ResourceLoadError> LoadFromFile(StringView path)
	{
		let xmlText = scope String();
		if (File.ReadAllText(path, xmlText) case .Err)
			return .Err(.NotFound);

		let theme = ThemeXmlParser.Parse(xmlText);
		if (theme == null)
			return .Err(.InvalidFormat);

		let resource = new ThemeResource();
		resource.Theme = theme;
		resource.Name.Set(path);
		resource.AddRef();
		return .Ok(resource);
	}

	protected override Result<ThemeResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
	{
		let xmlText = scope String();
		let bytes = scope List<uint8>();
		bytes.Count = (.)memory.Length;
		if (memory.TryRead(bytes) case .Err)
			return .Err(.ReadError);
		xmlText.Append((char8*)bytes.Ptr, bytes.Count);

		let theme = ThemeXmlParser.Parse(xmlText);
		if (theme == null)
			return .Err(.InvalidFormat);

		let resource = new ThemeResource();
		resource.Theme = theme;
		resource.AddRef();
		return .Ok(resource);
	}

	public override void Unload(ThemeResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}
}
