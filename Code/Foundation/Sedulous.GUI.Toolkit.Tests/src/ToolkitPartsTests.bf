using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// The toolkit's sheet reaches the parts its widgets draw: a sheet styles a widget's `tag::part`
/// only for the parts its CollectStyleParts names, and the ruler, the dopesheet, the curve view, the
/// graph view, the gradient strip and a property's preview named none, so each drew its colours from
/// code whatever the theme said.
class ToolkitPartsTests
{
	private static bool Styled(UINode widget, params StringView[] parts)
	{
		var all = true;
		for (let part in parts)
		{
			let has = widget.GetPartStyle(part).HasBackground;
			if (!has)
				Console.WriteLine("not styled: {}", part);
			all = all && has;
		}
		return all;
	}

	[Test]
	public static void TheSheetReachesEveryPartTheTimelineCurveGraphAndGradientViewsDraw()
	{
		let root = NewRoot(800.0f, 600.0f);
		defer root.ReleaseRef();
		let ruler = new TimeRuler();
		let sheet = new Dopesheet();
		let curves = new CurveView();
		let graph = new GraphView();
		let gradient = new GradientView();
		let preview = new PropertyValuePreview();
		for (let node in scope Node[](ruler, sheet, curves, graph, gradient, preview))
		{
			root.AddChild(node);
			node.ReleaseRef(); // the root's keeps it
		}
		let styles = scope StyleManager();
		let css = scope StyleSheet();
		let theme = scope String()..AppendF("{}\n{}", Theme.DefaultThemeCSS, ToolkitSheetCSS()); // its tokens under it, as an application puts them
		CSSParser.Parse(theme, css);
		styles.UserAgentSheet = css;
		styles.ApplyTree(root);

		Test.Assert(Styled(ruler, "tick", "marker", "marker-chosen", "playhead"));
		Test.Assert(Styled(sheet, "labels", "separator", "key", "summary", "selected", "playhead", "selection-box"));
		Test.Assert(Styled(curves, "grid", "selected", "playhead", "selection-box"));
		Test.Assert(Styled(graph, "grid", "grid-major", "node-link", "link-selected", "link-highlight", "link-drag", "link-refused", "selection-box"));
		Test.Assert(gradient.Strip != null);
		Test.Assert(Styled(gradient.Strip, "selected"));
		Test.Assert(Styled(preview, "curve"));
	}
}
