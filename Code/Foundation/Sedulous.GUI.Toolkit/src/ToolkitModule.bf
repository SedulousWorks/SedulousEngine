using System;

namespace Sedulous.GUI;

// GUI.Toolkit: editor widgets: tool and status bars, the property grid, colour, curves, gradients,
// the timeline, node graphs, the breadcrumb bar. Docking is not here, nor the code editor (GUI.Code).
// foundation.ui's counterpart: UI.Toolkit less docking and the code editor.
//
// ToolkitSheet.bf: the default sheet, over the theme's tokens. ToolBar.bf: tool bars over the command
// model. StatusBar.bf: status bars of registered items and messages. PropertySource.bf: what a
// property grid reads and edits through. PropertyEditor.bf: a grid's editors and how it chooses them.
// PropertyEditors.bf: the editors of bools, numbers, text, enums and flags. PropertyGrid.bf: the grid
// of a source's properties. ReflectedSource.bf: the GUI's reflection as a property source.
// TimeAxis.bf: one time axis and its ruler. TimelineSource.bf: what a dopesheet reads and edits
// through. CurveSource.bf: what a curve view reads and edits through. CurveView.bf: a source's curves
// on one canvas. GradientView.bf: a gradient's stops, edited as a value. Dopesheet.bf: a timeline's
// channels as rows of keys. CurveEditors.bf: the grid's curve and gradient editors, and the defaults.
// GraphSource.bf: what a graph view reads and edits through. GraphNodePicker.bf: the kinds of node a
// graph view adds, with a search. GraphView.bf: a graph source's nodes on a canvas. BreadcrumbBar.bf:
// where a view is, as segments to navigate by. Its widgets' reflection is their [GuiReflect] and
// [GuiProperty] attributes: the elements markup places, their sources given in code.

static
{
	private static bool sToolkitElementsRegistered = false;

	/// Registers the toolkit's element types (ElementTypes.Register), once: a host calls it at
	/// start-up beside RegisterGuiElements, so markup and scripts can make them.
	public static void RegisterToolkitElements()
	{
		if (sToolkitElementsRegistered)
			return;
		sToolkitElementsRegistered = true;
		ElementTypes.Register(ToolButton.StaticGuiType);
		ElementTypes.Register(ToolMenuButton.StaticGuiType);
		ElementTypes.Register(ToolBar.StaticGuiType);
		ElementTypes.Register(StatusItem.StaticGuiType);
		ElementTypes.Register(StatusBar.StaticGuiType);
		ElementTypes.Register(PropertyGrid.StaticGuiType);
		ElementTypes.Register(TimeRuler.StaticGuiType);
		ElementTypes.Register(CurveView.StaticGuiType);
		ElementTypes.Register(GradientView.StaticGuiType);
		ElementTypes.Register(Dopesheet.StaticGuiType);
		ElementTypes.Register(GraphView.StaticGuiType);
		ElementTypes.Register(BreadcrumbBar.StaticGuiType);
	}
}
