using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Samples.UISandbox;

/// The curve canvas, seeded with an ease in and out shape so the tangents are visible before
/// anything is touched.
///
/// The status line below it reads back the SELECTED key on every edit, which is the only way to
/// tell a tangent drag apart from a position drag by looking.
static class CurveEditorTab
{
	public static void Build(TabView tabView)
	{
		let demo = SandboxViews.VFlex(8.0f);
		demo.Padding = .(12, 8);
		tabView.AddTab("Curve Editor", demo);

		let help = new Label();
		help.SetText("""
			Left-click empty space: add key.  Left-click + drag key: move.  Right-click key: delete.
			Left-click + drag the coloured handles on the selected key: edit tangent.  Right-click handle: cycle TangentMode (Mirrored / Free / Flat).
			""");
		demo.AddView(help, SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Wrap()));

		let curve = new CurveCanvas();
		curve.MaxKeys = 12;

		ChannelDescriptor channel = .();
		channel.Name = "easeOut";
		channel.StrokeColor = Color.Rgb(120, 220, 160);
		channel.DefaultValue = 0.0f;
		channel.DisplayMin = 0.0f;
		channel.DisplayMax = 1.0f;
		channel.Interpolation = .Hermite;

		ChannelDescriptor[1] channels = .(channel);
		curve.SetChannels(channels);

		CurveCanvas.Key[3] seed = .(
			.(0.0f, 0.0f, 0.0f, 1.5f, .Mirrored),
			.(0.5f, 0.5f, 1.5f, 1.5f, .Mirrored),
			.(1.0f, 1.0f, 1.5f, 0.0f, .Mirrored));
		curve.SetKeys(0, seed);

		var canvasStyle = SandboxViews.Grow(1.0f);
		canvasStyle.Width = SizeSpec.Match();
		demo.AddView(curve, canvasStyle);

		let status = new Label();
		status.SetText("Selected key: (none)");
		demo.AddView(status, SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Wrap()));

		// Every edit path lands on one of these three, so the readout follows a drag, an add
		// and a delete alike.
		curve.OnKeyChanged.Add(new (channelIndex, keyIndex) => Refresh(curve, status));
		curve.OnKeyAdded.Add(new (channelIndex, keyIndex) => Refresh(curve, status));
		curve.OnKeyRemoved.Add(new (channelIndex, keyIndex) => Refresh(curve, status));
	}

	private static void Refresh(CurveCanvas curve, Label status)
	{
		let channel = curve.SelectedChannel;
		let index = curve.SelectedKeyIndex;
		if ((channel < 0) || (index < 0) || (index >= curve.GetKeyCount(channel)))
		{
			status.SetText("Selected key: (none)");
			return;
		}

		let key = curve.GetKey(channel, index);
		status.SetText(scope $"Key #{index}  t={key.Time:0.00}  v={key.Value:0.00}  tIn={key.TangentIn:0.00}  tOut={key.TangentOut:0.00}  mode={key.Mode}");
	}
}
