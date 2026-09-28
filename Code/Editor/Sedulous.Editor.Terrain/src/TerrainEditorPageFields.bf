using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Terrain;

/// The right pane: reference buttons that open the asset picker, the paint layer list with
/// its per layer maps, the blend grid and the stats. Rebuilt whole on every structural edit.
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

		AddLabel(scope $"Paint layers ({mAsset.PaletteAlbedoIds.Count})", 13.0f);
		for (int i < mAsset.PaletteAlbedoIds.Count)
		{
			let idx = i;
			AddReference(scope $"Layer {i} albedo", "TextureAsset", "palette",
				new [=this, =idx]() => (idx < mAsset.PaletteAlbedoIds.Count) ? mAsset.PaletteAlbedoIds[idx] : Guid(),
				new [=this, =idx](g) =>
				{
					if (idx < mAsset.PaletteAlbedoIds.Count)
						mAsset.PaletteAlbedoIds[idx] = g;
				});
			AddMapButton(i, "normal", .Normal, "paletteNormal");
			AddMapButton(i, "ORM", .Orm, "paletteOrm");
			AddMapButton(i, "height", .Height, "paletteHeight");
			AddMapButton(i, "mask", .Mask, "paletteMask");
			AddButton("  Remove layer", new [=this, =idx]() => { RemoveLayer(idx); });
		}
		AddButton("+ Add paint layer", new [=this]() => { AddLayer(); });

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
		for (int i < mAsset.PaletteTileScales.Count)
		{
			let idx = i;
			let mergeKey = new $"tile{i}";
			grid.AddProperty(new FloatEditor(scope $"Layer {i} tile", mAsset.PaletteTileScales[i], 0.1, 8192.0, 1.0, 2,
				new [=this, =idx, =mergeKey](v) =>
				{
					if (idx < mAsset.PaletteTileScales.Count)
					{
						mAsset.PaletteTileScales[idx] = (float)v;
						CommitEdit(mergeKey);
					}
				} ~ delete mergeKey, "Paint layers"));
		}
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

	/// A labelled asset slot for `assetTypeName`: picks, takes a dropped asset of the type,
	/// clears; the chosen id lands through `apply`, commits under `mergeKey`, re-points the
	/// preview and rebuilds the pane. CONSUMES `current` and `apply`.
	private void AddReference(StringView label, StringView assetTypeName, StringView mergeKey,
		delegate Guid() current, delegate void(Guid id) apply)
	{
		let key = new String(mergeKey);
		let row = new ResourceRefEditor(label, "(none)", "", scope StringView[](assetTypeName));
		row.BindAsset(mContext, current, new [=this, =apply, =key](picked) =>
			{
				apply(picked);
				CommitEdit(key);
				PointComponentAtTerrain(mTerrainProxy.Get);
				RebuildFieldsDeferred();
			} ~ { delete apply; delete key; });
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

	private void AddMapButton(int index, StringView mapLabel, PaletteMap map, StringView mergeKey)
	{
		let idx = index;
		let kind = map;
		AddReference(scope $"Layer {index} {mapLabel}", "TextureAsset", mergeKey,
			new [=this, =idx, =kind]() => TerrainAssetEdit.MapId(mAsset, kind, idx),
			new [=this, =idx, =kind](g) => { SetPaletteMap(kind, idx, g); });
	}
}
