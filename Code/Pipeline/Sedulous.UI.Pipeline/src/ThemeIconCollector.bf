using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Pipeline.Core;
using Sedulous.UI.Resource;

namespace Sedulous.UI.Pipeline;

/// A stylesheet's view of the cook: `@icon name "{guid}"` reads the vector image the guid names
/// and records it, so the cooked theme carries every icon it draws; a reference that names
/// none is recorded as missing. Images resolve at runtime (textures stream), so none here.
///
/// With no context it reads nothing and only records the references, which is what a
/// dependency scan wants.
class ThemeIconCollector : IResourceProvider
{
	/// BORROWED; null for a scan.
	private AssetBuildContext mContext;

	public List<Guid> References = new .() ~ delete _;
	public List<String> Missing = new .() ~ DeleteContainerAndItems!(_);
	/// Parallel, as the cooked theme stores them.
	public List<String> IconIds = new .() ~ DeleteContainerAndItems!(_);
	public List<String> IconSvgs = new .() ~ DeleteContainerAndItems!(_);

	public this(AssetBuildContext context)
	{
		mContext = context;
	}

	public bool LoadText(StringView path, String outText)
	{
		if (!(Guid.Parse(path) case .Ok(let id)) || id.IsNil)
		{
			Missing.Add(new .(path));
			return false;
		}
		for (int i < IconIds.Count)
		{
			if (IconIds[i] == path)
			{
				outText.Set(IconSvgs[i]);
				return true;
			}
		}
		References.Add(id);
		let svg = scope String();
		if ((mContext == null) || (ReadVectorImage(mContext, id, svg) case .Err) || svg.IsEmpty)
		{
			Missing.Add(new .(path));
			return false;
		}
		outText.Set(svg);
		IconIds.Add(new .(path));
		IconSvgs.Add(new .(svg));
		return true;
	}

	public ImageData LoadImage(StringView path) => null;

	/// The SVG a vector image asset carries: its cooked product when the cook has made it,
	/// else its linked source file (a headless or source database cook). NotFound when `id`
	/// names no vector image.
	public static Result<void, ErrorCode> ReadVectorImage(AssetBuildContext context, Guid id, String outSvg)
	{
		if (context.Database != null)
		{
			if (let instance = context.Database.GetInstance(id))
			{
				let object = instance.ReadObject();
				defer delete object;
				if (let cooked = object as UIVectorImageResource)
				{
					outSvg.Set(cooked.Svg);
					return .Ok;
				}
			}
		}
		if (context.SourceDatabase != null)
		{
			if (let instance = context.SourceDatabase.GetInstance(id))
			{
				let object = instance.ReadObject();
				defer delete object;
				if (let asset = object as UIVectorImageAsset)
					return AssetSource.ReadText(context, asset.FileName.Value, outSvg);
			}
		}
		return .Err(.NotFound);
	}
}
