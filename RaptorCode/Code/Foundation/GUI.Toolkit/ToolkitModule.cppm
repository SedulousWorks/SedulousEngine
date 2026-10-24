// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - `foundation.gui.toolkit`: editor widgets: tool and status bars, the property grid, colour,
// curves, gradients, the timeline, node graphs. Docking is not here (GUI.Docking), nor the code
// editor (GUI.Code).
// foundation.ui's counterpart: UI.Toolkit less docking and the code editor. Round three of the GUI's
// evolution (Specs/gui-lab-evolution-3.md): T, after its survey.

module;
#include "Core/Prelude.h"

export module foundation.gui.toolkit;

export import :sheet;    // the default sheet, over the theme's tokens
export import :tool_bar;   // T0: tool bars over the command model
export import :status_bar; // T0: status bars of registered items and messages
export import :property_source; // T1: what a property grid reads and edits through
export import :property_editor;  // T1: a grid's editors and how it chooses them
export import :property_editors; // T1: the editors of bools, numbers, text, enums and flags
export import :property_grid;    // T1: the grid of a source's properties
export import :reflected_source; // T3: core reflection as a property source
export import :time_axis;        // T5: one time axis and its ruler
export import :timeline_source;  // T5: what a dopesheet reads and edits through
export import :curve_source;     // T5: what a curve view reads and edits through
export import :curve_view;       // T5: a source's curves on one canvas
export import :gradient_view;    // T5: a gradient's stops, edited as a value
export import :dopesheet;        // T5: a timeline's channels as rows of keys
export import :curve_editors;    // T5: the grid's curve and gradient editors, and the defaults
export import :graph_source;     // T6: what a graph view reads and edits through
export import :graph_node_picker; // T6: the kinds of node a graph view adds, with a search
export import :graph_view;       // T6: a graph source's nodes on a canvas
export import :breadcrumb_bar;   // T7: where a view is, as segments to navigate by

export namespace foundation::gui
{
    /// Registers the toolkit's element types (ElementTypes::Register), once: a host calls it at
    /// start-up beside RegisterGuiElements, so markup and scripts can make them.
    void RegisterToolkitElements();
}
