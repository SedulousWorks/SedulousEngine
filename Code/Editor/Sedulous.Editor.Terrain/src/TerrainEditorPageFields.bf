using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Terrain;

/// The right pane: the reference slots, the paint layer list with its per layer maps and
/// tiling, the blend grid and the stats. Rebuilt whole on every structural edit.
extension TerrainEditorPage
{
	/// Safe from inside a UI event: defers the rebuild through the mutation queue.
	private void RebuildFieldsDeferred()
	{
		let ctx = (mContent != null) ? mContent.Context : null;
		if (ctx == null)
		{
			RebuildFields();
			return;
		}
		ctx.MutationQueue.QueueAction(new [=this]() => { RebuildFields(); });
	}

	private void RebuildFields()
	{
		if ((mFields == null) || (mAsset == null))
			return;
		mFields.RemoveAllViews();
		ClearAndDeleteItems(mReferenceRows);

		AddLabel("References", 13.0f);
		AddReference("Heightfield", "HeightfieldAsset", "heightfield", new [=this]() => mAsset.HeightfieldId,
			new [=this](g) => { mAsset.HeightfieldId = g; });
		AddReference("Weights", "SplatmapAsset", "weights", new [=this]() => mAsset.WeightsId,
			new [=this](g) => { mAsset.WeightsId = g; });
		if (mAsset.WeightsId.IsNil)
		{
			AddLabel("Create weights:", 11.0f);
			AddButton("512", new [=this]() => { CreateSplatmap(512); });
			AddButton("1024", new [=this]() => { CreateSplatmap(1024); });
			AddButton("2048", new [=this]() => { CreateSplatmap(2048); });
		}

		AddLabel("Base layer", 13.0f);
		AddReference("Base albedo", "TextureAsset", "baseAlbedo", new [=this]() => mAsset.BaseAlbedoId,
			new [=this](g) => { mAsset.BaseAlbedoId = g; });
		AddReference("Base normal", "TextureAsset", "baseNormal", new [=this]() => mAsset.BaseNormalId,
			new [=this](g) => { mAsset.BaseNormalId = g; });
		AddReference("Base ORM", "TextureAsset", "baseOrm", new [=this]() => mAsset.BaseOrmId,
			new [=this](g) => { mAsset.BaseOrmId = g; });
		AddReference("Base height", "TextureAsset", "baseHeight", new [=this]() => mAsset.BaseHeightId,
			new [=this](g) => { mAsset.BaseHeightId = g; });

		// The paint layers are a section list: the header's add icon, and each layer a section
		// with its maps, its tiling and its remove icon. A layer's index is its weight channel,
		// so the order is not the user's to change.
		let layers = new PropertyGrid();
		let layerList = new ContainerListEditor("Paint layers", "Paint layers");
		layerList.ElementsAsSections = true;
		for (let albedo in mAsset.PaletteAlbedoIds)
			layerList.SlotNames.Add(mContext.AssetNameFor(albedo, .. new .()));
		layerList.OnAdd = new [=this]() => { AddLayer(); };
		layers.AddProperty(layerList);
		for (int i < mAsset.PaletteAlbedoIds.Count)
		{
			let idx = i;
			let section = LayerSection(i, .. scope .());
			layers.SetCategoryHeaderActions(section, ContainerListEditor.ElementActions(i, mAsset.PaletteAlbedoIds.Count, null,
				new [=this](index) => { RemoveLayer(index); }));
			layers.AddProperty(MakeReference("Albedo", "TextureAsset", "palette", section,
				new [=this, =idx]() => (idx < mAsset.PaletteAlbedoIds.Count) ? mAsset.PaletteAlbedoIds[idx] : Guid(),
				new [=this, =idx](g) =>
				{
					if (idx < mAsset.PaletteAlbedoIds.Count)
						mAsset.PaletteAlbedoIds[idx] = g;
				}));
			layers.AddProperty(MakeMapReference(i, "Normal", .Normal, "paletteNormal", section));
			layers.AddProperty(MakeMapReference(i, "ORM", .Orm, "paletteOrm", section));
			layers.AddProperty(MakeMapReference(i, "Height", .Height, "paletteHeight", section));
			layers.AddProperty(MakeMapReference(i, "Mask", .Mask, "paletteMask", section));
			if (i < mAsset.PaletteTileScales.Count)
			{
				let mergeKey = new $"tile{i}";
				layers.AddProperty(new FloatEditor("Tile", mAsset.PaletteTileScales[i], 0.1, 8192.0, 1.0, 2,
					new [=this, =idx, =mergeKey](v) =>
					{
						if (idx < mAsset.PaletteTileScales.Count)
						{
							mAsset.PaletteTileScales[idx] = (float)v;
							CommitEdit(mergeKey);
						}
					} ~ delete mergeKey, section));
			}
		}
		var layersStyle = LayoutStyle();
		layersStyle.Width = SizeSpec.Match();
		mFields.AddView(layers, layersStyle);

		let grid = new PropertyGrid();
		grid.AddProperty(new BoolEditor("Cast Shadows", mAsset.CastShadows, new [=this](v) =>
			{
				mAsset.CastShadows = v;
				CommitEdit("castShadows");
			}, "Terrain"));
		grid.AddProperty(new FloatEditor("Height blend", mAsset.HeightBlendContrast, 0.0, 1.0, 0.05, 2, new [=this](v) =>
			{
				mAsset.HeightBlendContrast = (float)v;
				CommitEdit("heightBlend");
			}, "Terrain"));
		grid.AddProperty(new FloatEditor("Base tile", mAsset.BaseTileScale, 0.1, 8192.0, 1.0, 2, new [=this](v) =>
			{
				mAsset.BaseTileScale = (float)v;
				CommitEdit("baseTile");
			}, "Base"));
		var gridStyle = LayoutStyle();
		gridStyle.Width = SizeSpec.Match();
		mFields.AddView(grid, gridStyle);

		AddLabel("Stats", 13.0f);
		let product = mTerrainProxy.Get;
		if (product != null)
		{
			let lines = scope List<String>();
			defer { ClearAndDeleteItems!(lines); }
			TerrainStats.Lines(product, lines);
			for (let line in lines)
				AddLabel(line, 12.0f);
		}
		else
			AddLabel("(not cooked yet - Save to preview)", 12.0f);
	}

	private void AddLabel(StringView text, float fontSize)
	{
		let label = new Label(text);
		label.FontSize.Value = fontSize;
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		mFields.AddView(label, style);
	}

	/// CONSUMES the click delegate.
	private void AddButton(StringView text, delegate void() onClick)
	{
		let button = new Button(text);
		button.FontSize.Value = 12.0f;
		button.OnClick.Add(new [=onClick](btn) => { onClick(); } ~ delete onClick);
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		mFields.AddView(button, style);
	}

	/// Paint layer `index`'s section.
	public static void LayerSection(int index, String outCategory)
	{
		outCategory.Clear();
		outCategory.AppendF("Layer {}", index + 1);
	}

	/// An asset row for `assetTypeName`: picks, takes a dropped asset of the type, clears; the
	/// chosen id lands through `apply`, commits under `mergeKey`, re-points the preview and
	/// rebuilds the pane. CONSUMES `current` and `apply`; the caller owns the row.
	private ResourceRefEditor MakeReference(StringView label, StringView assetTypeName, StringView mergeKey,
		StringView category, delegate Guid() current, delegate void(Guid id) apply)
	{
		let key = new String(mergeKey);
		let row = new ResourceRefEditor(label, "(none)", category, scope StringView[](assetTypeName));
		row.BindAsset(mContext, current, new [=this, =apply, =key](picked) =>
			{
				apply(picked);
				CommitEdit(key);
				PointComponentAtTerrain(mTerrainProxy.Get);
				RebuildFieldsDeferred();
			} ~ { delete apply; delete key; });
		return row;
	}

	/// A labelled asset slot on the pane itself. CONSUMES `current` and `apply`.
	private void AddReference(StringView label, StringView assetTypeName, StringView mergeKey,
		delegate Guid() current, delegate void(Guid id) apply)
	{
		let row = MakeReference(label, assetTypeName, mergeKey, "", current, apply);
		mReferenceRows.Add(row);

		let line = new FlexLayout();
		line.Direction = .Horizontal;
		line.Spacing = 6.0f;
		let text = new Label(label);
		text.FontSize.Value = 12.0f;
		var fixedWidth = LayoutStyle();
		fixedWidth.Width = SizeSpec.Fixed(Unit.Dp(110));
		fixedWidth.AlignSelf = .Center;
		line.AddView(text, fixedWidth);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		line.AddView(row.EditorView, grow);
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		mFields.AddView(line, style);
	}

	private ResourceRefEditor MakeMapReference(int index, StringView mapLabel, PaletteMap map, StringView mergeKey,
		StringView category)
	{
		let idx = index;
		let kind = map;
		return MakeReference(mapLabel, "TextureAsset", mergeKey, category,
			new [=this, =idx, =kind]() => TerrainAssetEdit.MapId(mAsset, kind, idx),
			new [=this, =idx, =kind](g) => { SetPaletteMap(kind, idx, g); });
	}
}
