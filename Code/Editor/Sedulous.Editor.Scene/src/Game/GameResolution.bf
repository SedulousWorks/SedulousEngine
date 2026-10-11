using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Scene;

/// One entry of the Game tab's resolution dropdown.
class GameResolutionChoice
{
	/// "project", "export:<preset>", "preset:<name>" or "panel".
	public String Key = new .() ~ delete _;
	public String Label = new .() ~ delete _;
	/// Nought for the panel's own size.
	public uint32 Width;
	public uint32 Height;
	/// An export preset held its own way (a phone-facing Web preset says Landscape): the Game tab
	/// previews it so; otherwise the project's orientation applies.
	public bool OverridesOrientation = false;
	public ScreenOrientation Orientation = .Any;
}

/// What the Game tab draws at, and how it shows a game: pure, so a test reads it.
static class GameResolution
{
	public const String cProjectKey = "project";
	public const String cPanelKey = "panel";

	/// The Game tab's phone preview: a phone held upright, 9 by 19.5.
	public const uint32 cPhonePreviewWidth = 720;
	public const uint32 cPhonePreviewHeight = 1560;

	/// The game on a `width` x `height` target (the panel, or the previewed phone's screen), as
	/// the player puts it in its window: its render resolution (0 x 0: none) fitted by `fit`,
	/// turned a quarter when `orientation` is not the target's shape, and then at the target's
	/// pixels turned when it has no resolution of its own.
	public static ContentFit GameFitOn(uint32 width, uint32 height, uint32 renderWidth, uint32 renderHeight, FitMode fit,
		ScreenOrientation orientation)
	{
		let w = (float)width;
		let h = (float)height;
		let turn = ContentFit.TurnFor(orientation, w, h);
		let swaps = (turn == .Quarter) || (turn == .ThreeQuarter);
		let sized = (renderWidth > 0) && (renderHeight > 0);
		let content = sized ? Float2(renderWidth, renderHeight) : (swaps ? Float2(h, w) : Float2(w, h));
		return ContentFit(.(0, 0, w, h), content, sized ? fit : .Stretch, turn);
	}

	/// The orientation's name for a label, empty for Any.
	public static StringView OrientationLabel(ScreenOrientation orientation)
	{
		switch (orientation)
		{
		case .Landscape: return "landscape";
		case .Portrait: return "portrait";
		case .Any: return "";
		}
	}

	/// The dropdown's entries, in order: the project's own render resolution (the default); each
	/// export preset that draws at its own size or is held its own way, as that platform would;
	/// the user's preview presets; then the panel's own size. `presets` and `previews` may be
	/// null.
	public static void Collect(ProjectSettings settings, ExportPresetSet presets, GamePreviewSettings previews,
		List<GameResolutionChoice> outChoices)
	{
		let project = new GameResolutionChoice();
		project.Key.Set(cProjectKey);
		if ((settings != null) && settings.HasRenderResolution)
		{
			project.Width = settings.RenderWidth;
			project.Height = settings.RenderHeight;
			project.Label.AppendF("Project {}x{}", project.Width, project.Height);
		}
		else
		{
			project.Label.Set("Project (panel size)");
		}
		outChoices.Add(project);

		if (presets != null)
		{
			for (let preset in presets.Presets)
			{
				// A preset that draws at its own size, or is held its own way; one that changes
				// neither looks as the project does.
				let ownSize = preset.OverridesRender && (preset.RenderWidth > 0) && (preset.RenderHeight > 0);
				let held = preset.OverridesOrientation ? OrientationLabel(preset.Orientation) : StringView();
				if (!ownSize && held.IsEmpty)
					continue;
				let choice = new GameResolutionChoice();
				choice.Key.AppendF("export:{}", preset.Name);
				choice.Width = ownSize ? preset.RenderWidth : project.Width;
				choice.Height = ownSize ? preset.RenderHeight : project.Height;
				if (choice.Width > 0)
					choice.Label.AppendF("{} {}x{}", preset.Name, choice.Width, choice.Height);
				else
					choice.Label.AppendF("{} (panel size)", preset.Name);
				if (!held.IsEmpty)
				{
					choice.Label.AppendF(", {}", held);
					choice.OverridesOrientation = true;
					choice.Orientation = preset.Orientation;
				}
				outChoices.Add(choice);
			}
		}

		if (previews != null)
		{
			for (let preset in previews.Presets)
			{
				if ((preset.Width == 0) || (preset.Height == 0))
					continue;
				let choice = new GameResolutionChoice();
				choice.Key.AppendF("preset:{}", preset.Name);
				choice.Label.AppendF("{} {}x{}", preset.Name, preset.Width, preset.Height);
				choice.Width = preset.Width;
				choice.Height = preset.Height;
				outChoices.Add(choice);
			}
		}

		let panel = new GameResolutionChoice();
		panel.Key.Set(cPanelKey);
		panel.Label.Set("Fit to panel");
		outChoices.Add(panel);
	}

	/// What the choices were built from: a rebuild only when it changes.
	public static void Signature(List<GameResolutionChoice> choices, ProjectSettings settings, String outSignature)
	{
		for (let choice in choices)
			outSignature.AppendF("{}={}x{}@{};", choice.Key, choice.Width, choice.Height, (int)choice.Orientation);
		if (settings != null)
			outSignature.AppendF("fit={};orientation={}", (int)settings.RenderFit, (int)settings.Orientation);
	}
}
