using System;
using internal Sedulous.Profiler.GUI;

namespace Sedulous.Profiler.GUI;

// The profiler views' default sheet, written against the theme's tokens as the toolkit's is, so they
// follow dark, light and contrast; a theme restyles them by setting `--profiler-*` over it. A name's
// eight hues are light enough for dark text on them in either scheme.

static
{
	/// The views' sheet (an application puts it after the theme in its user agent sheet).
	public static StringView ProfilerSheetCSS() => ProfilerSheetDetail.cCss;
}

/// What ProfilerSheet.bf keeps out of the public surface: the sheet's text.
internal static class ProfilerSheetDetail
{
	public const String cCss = """
		framestrip, counterplot { color: var(--text-dim); font-size: var(--font-small); }
		framestrip::plot, counterplot::plot { background-color: var(--profiler-plot, var(--surface-sunken)); }
		framestrip::on-time { background-color: var(--profiler-on-time, #3f9c6b); }
		framestrip::over { background-color: var(--profiler-over, #c99a2e); }
		framestrip::far-over, framestrip::clipped { background-color: var(--profiler-far-over, #c8503f); }
		framestrip::chosen, counterplot::chosen { background-color: var(--profiler-chosen, var(--accent)); }
		framestrip::share { background-color: var(--profiler-share, #00000066); }
		framestrip::budget { background-color: var(--profiler-budget, var(--text-dim)); }
		framestrip::chosen-box, counterplot::chosen-box { background-color: var(--profiler-chosen-box, var(--accent-strong)); }
		framestrip::chosen-fill, counterplot::chosen-fill { background-color: var(--profiler-chosen-fill, var(--accent-subtle)); opacity: 0.5; }
		framestrip::scale, counterplot::range { color: var(--text-dim); }
		counterplot::name { color: var(--text); }
		counterplot::bar { background-color: var(--profiler-counter, #6f86b8); }
		profiletimeline { color: var(--text); font-size: var(--font-small); }
		profiletimeline::ruler, profiletimeline::header { background-color: var(--profiler-ruler, var(--surface-header)); }
		profiletimeline::ruler, profiletimeline::frame, profiletimeline::fit { color: var(--text-dim); }
		profiletimeline::frame { color: var(--text-strong); }
		profiletimeline::fit { color: var(--accent-strong); }
		profiletimeline::tick, profiletimeline::frame-edge { background-color: var(--text-dim); }
		profiletimeline::separator { background-color: var(--separator); }
		profiletimeline::lane-name { color: var(--text-strong); }
		profiletimeline::gpu-name { color: var(--profiler-gpu, #7fb4e8); }
		profiletimeline::fold { background-color: var(--icon-dim); }
		profiletimeline::bar { color: var(--profiler-bar-text, #10131a); }
		profiletimeline::hover { background-color: var(--profiler-hover, var(--text)); opacity: 0.7; }
		profiletimeline::chosen { background-color: var(--profiler-chosen-edge, var(--text-strong)); }
		profiletimeline::hatch { background-color: var(--profiler-hatch, #8a8f9a); opacity: 0.35; }
		profiletimeline::activity { background-color: var(--profiler-activity, #6f86b8); opacity: 0.45; }
		profiletimeline::span { background-color: var(--profiler-span, var(--accent)); opacity: 0.1; }
		profiletimeline::span-edge { background-color: var(--profiler-span-edge, var(--accent)); }
		profiletimeline::span-head { background-color: var(--profiler-span-head, var(--accent)); opacity: 0.35; color: var(--text-strong); }
		framestrip::hue-0, counterplot::hue-0, profiletimeline::hue-0 { background-color: var(--profiler-hue-0, #e0a458); }
		framestrip::hue-1, counterplot::hue-1, profiletimeline::hue-1 { background-color: var(--profiler-hue-1, #7fc8a9); }
		framestrip::hue-2, counterplot::hue-2, profiletimeline::hue-2 { background-color: var(--profiler-hue-2, #8fb0e8); }
		framestrip::hue-3, counterplot::hue-3, profiletimeline::hue-3 { background-color: var(--profiler-hue-3, #d98fb0); }
		framestrip::hue-4, counterplot::hue-4, profiletimeline::hue-4 { background-color: var(--profiler-hue-4, #b8c96f); }
		framestrip::hue-5, counterplot::hue-5, profiletimeline::hue-5 { background-color: var(--profiler-hue-5, #c6a6e8); }
		framestrip::hue-6, counterplot::hue-6, profiletimeline::hue-6 { background-color: var(--profiler-hue-6, #6fc4d1); }
		framestrip::hue-7, counterplot::hue-7, profiletimeline::hue-7 { background-color: var(--profiler-hue-7, #e88f7f); }
		""";
}
