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

		AddLabel("References", 13.0f);
		AddReferenceButton(scope $"Heightfield: {AssetName(mAsset.HeightfieldId, .. scope .())}", "HeightfieldAsset", "heightfield",
			new [=this](g) => { mAsset.HeightfieldId = g; });
		AddReferenceButton(scope $"Weights: {AssetName(mAsset.WeightsId, .. scope .())}", "SplatmapAsset", "weights",
			new [=this](g) => { mAsset.WeightsId = g; });
		if (mAsset.WeightsId.IsNil)
		{
			AddLabel("Create weights:", 11.0f);
			AddButton("512", new [=this]() => { CreateSplatmap(512); });
			AddButton("1024", new [=this]() => { CreateSplatmap(1024); });
			AddButton("2048", new [=this]() => { CreateSplatmap(2048); });
		}

		AddLabel("Base layer", 13.0f);
		AddReferenceButton(scope $"Base albedo: {AssetName(mAsset.BaseAlbedoId, .. scope .())}", "TextureAsset", "baseAlbedo",
			new [=this](g) => { mAsset.BaseAlbedoId = g; });
		AddReferenceButton(scope $"Base normal: {AssetName(mAsset.BaseNormalId, .. scope .())}", "TextureAsset", "baseNormal",
			new [=this](g) => { mAsset.BaseNormalId = g; });
		AddReferenceButton(scope $"Base ORM: {AssetName(mAsset.BaseOrmId, .. scope .())}", "TextureAsset", "baseOrm",
			new [=this](g) => { mAsset.BaseOrmId = g; });
		AddReferenceButton(scope $"Base height: {AssetName(mAsset.BaseHeightId, .. scope .())}", "TextureAsset", "baseHeight",
			new [=this](g) => { mAsset.BaseHeightId = g; });

		AddLabel(scope $"Paint layers ({mAsset.PaletteAlbedoIds.Count})", 13.0f);
		for (int i < mAsset.PaletteAlbedoIds.Count)
		{
			let idx = i;
			AddReferenceButton(scope $"Layer {i} albedo: {AssetName(mAsset.PaletteAlbedoIds[i], .. scope .())}", "TextureAsset", "palette",
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

	/// A button opening the picker for `assetTypeName`; CONSUMES `apply`, which lands the
	/// pick on the asset before the edit commits under `mergeKey`.
	private void AddReferenceButton(StringView text, StringView assetTypeName, StringView mergeKey, delegate void(Guid id) apply)
	{
		let typeName = new String(assetTypeName);
		let key = new String(mergeKey);
		AddButton(text, new [=this, =typeName, =key, =apply]() =>
			{
				PickReference(typeName, key, apply);
			} ~ { delete typeName; delete key; delete apply; });
	}

	private void AddMapButton(int index, StringView mapLabel, PaletteMap map, StringView mergeKey)
	{
		let idx = index;
		let kind = map;
		let id = TerrainAssetEdit.MapId(mAsset, map, index);
		AddReferenceButton(scope $"Layer {index} {mapLabel}: {AssetName(id, .. scope .())}", "TextureAsset", mergeKey,
			new [=this, =idx, =kind](g) => { SetPaletteMap(kind, idx, g); });
	}

	/// Opens the asset picker; a pick applies, commits, re-points the preview and rebuilds
	/// the pane. `apply` is BORROWED from the button that owns it.
	private void PickReference(StringView assetTypeName, StringView mergeKey, delegate void(Guid id) apply)
	{
		let ctx = (mContent != null) ? mContent.Context : null;
		if (ctx == null)
			return;
		let key = new String(mergeKey);
		let dialog = new AssetPickerDialog(mContext, scope StringView[](assetTypeName));
		dialog.OnPicked = new [=this, =apply, =key](picked) =>
			{
				apply(picked);
				CommitEdit(key);
				PointComponentAtTerrain(mTerrainProxy.Get);
				RebuildFieldsDeferred();
			} ~ delete key;
		dialog.Show(ctx);
	}
}
