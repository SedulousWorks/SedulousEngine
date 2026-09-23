using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain;

/// The splat brush's floating panel: the base swatch, one swatch per palette layer plus
/// the eraser and smooth slots as a segmented toggle, then radius, strength, spacing and
/// airbrush. Swatches show the layer's albedo thumbnail when the context has thumbnails;
/// a scene with no palette gets four numbered slots.
class SplatPanelProvider : IViewportToolPanelProvider
{
	public StringView ToolId => "terrain.splat";
	public ToolPanelPlacement Placement => .Float;

	public View CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
	{
		let t = tool as TerrainSplatTool;
		if (t == null)
			return null;
		let thumbs = (context.EditorContext != null) ? context.EditorContext.Thumbnails : null;
		let layers = new LayerSet();
		LayerSet.Resolve(context.Scene, layers);
		let useThumbs = (layers.Count > 0) && (thumbs != null);
		let fallbackIcon = EditorIcons.Texture;
		let editorContext = context.EditorContext;
		let layerNames = new List<String>();
		for (let id in layers.Ids)
			layerNames.Add(SwatchAssetName(editorContext, id, .. new .()));

		let root = ToolPanelWidgets.MakePanelRoot();
		if (useThumbs)
		{
			root.AddView(ToolPanelWidgets.MakeRow("Base (erase to reveal)", 11.0f));
			let baseSwatch = new LayerSwatch(thumbs, layers.BaseId, fallbackIcon, 24.0f);
			SwatchAssetName(editorContext, layers.BaseId, baseSwatch.TooltipText);
			root.AddView(baseSwatch);
		}

		root.AddView(ToolPanelWidgets.MakeRow("Paint layer", 12.0f));
		let paletteCount = (layers.Count > 0) ? (int32)layers.Count : 4;
		let toggle = new SegmentedToggle();
		toggle.Build(paletteCount + 2,
			new [=useThumbs, =thumbs, =layers, =fallbackIcon, =paletteCount](i) =>
			{
				if (i >= paletteCount)
				{
					let label = new Label((i == paletteCount) ? "E" : "S");
					label.FontSize.Value = 12.0f;
					return label;
				}
				if (useThumbs)
					return new LayerSwatch(thumbs, layers.Ids[i], fallbackIcon, 24.0f);
				let label = new Label(scope $"{i}");
				label.FontSize.Value = 12.0f;
				return label;
			},
			new [=t, =paletteCount](i) =>
			{
				if (i == paletteCount)
					t.SetEraser(true);
				else if (i == paletteCount + 1)
					t.SetSmooth(true);
				else
					t.SetPaletteIndex((uint32)i);
			},
			new [=t, =paletteCount]() =>
			{
				return t.IsEraser ? paletteCount : (t.IsSmooth ? paletteCount + 1 : (int32)t.PaletteIndex);
			},
			new [=paletteCount, =layerNames, =layers](i, outTooltip) =>
			{
				if (i == paletteCount)
					outTooltip.Set("Eraser (reveals base)");
				else if (i == paletteCount + 1)
					outTooltip.Set("Smooth (feathers painted seams)");
				else if ((i >= 0) && (i < layerNames.Count))
					outTooltip.Set(layerNames[i]);
				else
					outTooltip.Set("Paint layer");
			} ~ { ClearAndDeleteItems!(layerNames); delete layerNames; delete layers; });
		root.AddView(toggle);

		let grid = new PropertyGrid();
		let radius = ToolPanelWidgets.AddFloat(grid, "Radius", t.Radius, 0.5, 128.0, 1.0, 1, new [=t](v) => { t.SetRadius((float)v); });
		ToolPanelWidgets.AddFloat(grid, "Strength", t.Strength, 0.0, 1.0, 0.05, 2, new [=t](v) => { t.SetStrength((float)v); });
		ToolPanelWidgets.AddFloat(grid, "Stamp spacing", t.Spacing, 0.05, 1.0, 0.05, 2, new [=t](v) => { t.SetSpacing((float)v); });
		grid.AddProperty(new BoolEditor("Airbrush", t.IsAirbrush, new [=t](v) => { t.SetAirbrush(v); }));
		delete t.OnRadiusChanged;
		t.OnRadiusChanged = new [=radius](r) => { radius.SetValue(r); };
		ToolPanelWidgets.AddGrid(root, grid);
		return root;
	}

	/// The albedo asset's name for a swatch tooltip.
	private static void SwatchAssetName(EditorContext context, Guid id, String outName)
	{
		if (id.IsNil)
		{
			outName.Append("(no albedo)");
			return;
		}
		if ((context != null) && (context.Project != null))
		{
			if (let inst = context.Project.SourceDb.GetInstance(id))
			{
				outName.Append(inst.Name);
				return;
			}
		}
		outName.Append("(missing)");
	}
}
