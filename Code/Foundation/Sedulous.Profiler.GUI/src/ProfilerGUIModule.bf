using System;
using Sedulous.GUI;

namespace Sedulous.Profiler.GUI;

// Profiler.GUI: the profiler's views on the GUI (X7 of Raptor's editor-gui spec): the frame strip, the
// counters, the timeline, the scope table and a scope's detail, each reading an IProfileSource through
// one focus, so they work on the live store and on a capture alike. Profiler.UI's counterpart;
// Profiler.UI stays for the in-game overlay until X8.
//
// ProfileFocus.bf: what a page looks at, held once. ProfilerWidget.bf: what every view shares.
// FrameStrip.bf: the frames side by side (the strip, the counters' plots) on one frame axis.
// ProfileTimeline.bf: the frames chosen on one time axis, a lane per thread and the GPU's.
// ScopeTable.bf: the frames chosen's scopes as a call tree or a flat list. ScopeDetail.bf: the name
// chosen, apart: its callers, its children, its calls' spread.
// ProfilerSheet.bf: the views' default sheet. Their reflection is their [GuiReflect] attributes: the
// elements markup places, their focus and axis given in code.

static
{
	private static bool sProfilerElementsRegistered = false;

	/// Registers the profiler's element types (ElementTypes.Register), once: a host calls it at
	/// start-up beside RegisterGuiElements.
	public static void RegisterProfilerElements()
	{
		if (sProfilerElementsRegistered)
			return;
		sProfilerElementsRegistered = true;
		ElementTypes.Register(FrameStrip.StaticGuiType);
		ElementTypes.Register(CounterPlot.StaticGuiType);
		ElementTypes.Register(ProfileTimeline.StaticGuiType);
		ElementTypes.Register(ScopeTable.StaticGuiType);
		ElementTypes.Register(ScopeDetail.StaticGuiType);
	}
}
