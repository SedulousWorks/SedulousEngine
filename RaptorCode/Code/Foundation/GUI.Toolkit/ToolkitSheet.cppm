// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :sheet partition
//
// The toolkit's default sheet (round three's ruling 4): its widgets styled through the theme's
// tokens, so they follow dark, light and contrast; a theme or an application restyles them by
// setting `--toolbar-*` and the rest, over this sheet, not a fork of it.

module;
#include "Core/Prelude.h"

export module foundation.gui.toolkit:sheet;

import foundation.core;

namespace core = foundation::core;

export namespace foundation::gui
{
    /// The toolkit's default sheet, written against the theme's tokens (an application puts it after
    /// the theme in its user agent sheet).
    [[nodiscard]] inline core::StringView ToolkitSheetCSS() noexcept
    {
        return core::StringView(u8R"(
            toolbar { background-color: var(--toolbar-background, var(--chrome-raised)); }
            toolbutton, toolmenubutton, toolbar > overflow {
                background-color: transparent; color: var(--toolbar-text, var(--text));
                padding: var(--toolbar-button-padding, 4px); border-radius: var(--toolbar-button-radius, var(--radius-small));
            }
            toolbutton:hover, toolmenubutton:hover, toolbar > overflow:hover {
                background-color: var(--toolbar-button-hover, var(--control-hover));
            }
            toolbutton:active, toolmenubutton:active, toolbar > overflow:active {
                background-color: var(--toolbar-button-pressed, var(--control-raised));
            }
            toolbutton:checked, toolmenubutton:checked { background-color: var(--toolbar-button-checked, var(--selection)); }
            toolbutton:disabled, toolmenubutton:disabled { opacity: var(--disabled-opacity); }
            toolbutton:focus-visible, toolmenubutton:focus-visible, toolbar > overflow:focus-visible {
                box-shadow: 0 0 0 var(--focus-width) var(--focus-ring);
            }
            toolbutton > icon, toolmenubutton > icon { width: var(--toolbar-icon, 16px); height: var(--toolbar-icon, 16px); }
            toolbutton > text, toolmenubutton > text { padding: 0 2px; }
            statusbar { background-color: var(--statusbar-background, var(--chrome)); color: var(--statusbar-text, var(--text-dim));
                        font-size: var(--font-small); }
            statusbar label { color: var(--statusbar-text, var(--text-dim)); }
            statusbar label.message { color: var(--statusbar-message, var(--text)); }
            propertygrid { background-color: var(--propertygrid-background, var(--surface)); color: var(--text); }
            propertycategory { background-color: var(--propertygrid-category, var(--surface-header)); color: var(--text-strong);
                               font-weight: bold; }
            propertyrow:hover { background-color: var(--propertygrid-row-hover, var(--row-hover)); }
            propertyname { color: var(--propertygrid-name, var(--text-dim)); }
            propertyrowcontent.changed > propertyname { color: var(--propertygrid-changed-name, var(--text-strong)); font-weight: bold; }
            propertyrowcontent::marker { background-color: var(--propertygrid-changed, var(--accent)); }
            propertyeditor.unknown label { color: var(--text-dim); font-style: italic; }
            propertyeditor.flags button { background-color: var(--propertygrid-flags, var(--control)); color: var(--text-strong);
                                          padding: var(--space-s); text-align: start; }
            propertyeditor.floats > label.component { color: var(--propertygrid-component, var(--text-dim)); font-size: var(--font-small); }
            propertyeditor.list > label.count { color: var(--text-dim); }
            propertyeditor.list > button.add { background-color: var(--propertygrid-add, var(--control)); color: var(--text-strong);
                                               padding: 2px 10px; border-radius: var(--radius-small); }
            propertycolorpopup { background-color: var(--propertygrid-popup, var(--surface-raised)); border-radius: var(--radius-small);
                                 box-shadow: 0 4px 12px var(--shadow-color); }
            propertyflagslist { background-color: var(--propertygrid-popup, var(--surface-raised)); border-radius: var(--radius-small);
                                box-shadow: 0 4px 12px var(--shadow-color); }
            timeruler { background-color: var(--timeline-ruler, var(--surface-header)); color: var(--text-dim); font-size: var(--font-small); }
            timeruler::tick { background-color: var(--timeline-tick, var(--text-dim)); }
            timeruler::playhead { background-color: var(--timeline-playhead, var(--accent)); }
            curveview { background-color: var(--curveview-background, var(--surface-sunken)); color: var(--text-dim);
                        font-size: var(--font-small); }
            curveview::grid { background-color: var(--curveview-grid, var(--separator)); }
            curveview::selected { background-color: var(--curveview-selected, var(--text-strong)); }
            curveview::playhead { background-color: var(--timeline-playhead, var(--accent)); }
            curveview::selection-box { background-color: var(--curveview-selection-box, var(--selection)); opacity: 0.5; }
            curveview:focus-visible { box-shadow: inset 0 0 0 var(--focus-width) var(--focus-ring); }
            gradientview { color: var(--text); }
            gradientstrip { color: var(--gradient-stop-edge, var(--text-dim)); }
            gradientstrip::selected { background-color: var(--gradient-stop-selected, var(--accent)); }
            gradientview:focus-visible { box-shadow: 0 0 0 var(--focus-width) var(--focus-ring); }
            propertyviewpopup { background-color: var(--propertygrid-popup, var(--surface-raised)); border-radius: var(--radius-small);
                                box-shadow: 0 4px 12px var(--shadow-color); }
            propertypreview { background-color: var(--propertygrid-preview, var(--surface-sunken)); border-radius: var(--radius-small);
                              color: var(--text-dim); }
            propertypreview::curve { background-color: var(--propertygrid-curve, var(--accent)); }
            propertypreview:focus-visible { box-shadow: 0 0 0 var(--focus-width) var(--focus-ring); }
            dopesheet { background-color: var(--dopesheet-background, var(--surface-sunken)); color: var(--text); font-size: var(--font-small); }
            dopesheet::labels { background-color: var(--dopesheet-labels, var(--surface-header)); }
            dopesheet::separator { background-color: var(--dopesheet-separator, var(--separator)); }
            dopesheet::key { background-color: var(--dopesheet-key, var(--text)); }
            dopesheet::summary { background-color: var(--dopesheet-summary, var(--text-dim)); }
            dopesheet::selected { background-color: var(--dopesheet-selected, var(--accent)); }
            dopesheet::playhead { background-color: var(--timeline-playhead, var(--accent)); }
            dopesheet::selection-box { background-color: var(--dopesheet-selection-box, var(--selection)); opacity: 0.5; }
            dopesheet:focus-visible { box-shadow: inset 0 0 0 var(--focus-width) var(--focus-ring); }
            graphview { background-color: var(--graphview-background, var(--surface-sunken)); color: var(--text); font-size: var(--font-small); }
            graphview::grid { background-color: var(--graphview-grid, var(--separator)); opacity: 0.35; }
            graphview::grid-major { background-color: var(--graphview-grid-major, var(--separator)); opacity: 0.8; }
            graphview::selection-box { background-color: var(--graphview-selection-box, var(--selection)); opacity: 0.5; }
            graphview:focus-visible { box-shadow: inset 0 0 0 var(--focus-width) var(--focus-ring); }
            graphnode {
                background-color: var(--graphnode-background, var(--surface-raised)); border: var(--border-width) solid var(--graphnode-border, var(--border));
                border-radius: var(--graphnode-radius, var(--radius));
            }
            graphview::node-link { background-color: var(--graphview-node-link, var(--text-dim)); }
            graphview::link-selected { background-color: var(--graphview-link-selected, var(--text-strong)); }
            graphview::link-highlight { background-color: var(--graphview-link-highlight, var(--accent-strong)); }
            graphview::link-drag { background-color: var(--graphview-link-drag, var(--text-strong)); }
            graphview::link-refused { background-color: var(--graphview-link-refused, var(--surface-raised)); }
            graphnode.selected { border-color: var(--graphnode-selected, var(--accent)); }
            graphnode.highlighted { box-shadow: 0 0 0 2px var(--graphnode-highlight, var(--accent-strong)); }
            graphnode.target { border-color: var(--graphnode-target, var(--accent-strong)); }
            graphnode.refused { opacity: 0.5; }
            graphpin.refused label { opacity: 0.4; }
            graphframe { border: var(--border-width) solid transparent; border-radius: var(--radius); }
            graphframe.selected { border-color: var(--graphframe-selected, var(--accent)); }
            graphframe editablelabel.title { color: var(--graphframe-title, var(--text-strong)); }
            graphframe editablelabel.body { color: var(--graphframe-body, var(--text)); white-space: pre-wrap; }
            graphnodepicker {
                background-color: var(--graphnodepicker-background, var(--surface-raised)); border: var(--border-width) solid var(--border);
                border-radius: var(--radius); font-size: var(--font-small); color: var(--text);
            }
            graphpickerrow { border-radius: var(--radius-small); }
            graphpickerrow.category { padding: 1px 4px; }
            graphpickerrow.category label { color: var(--text-dim); }
            graphpickerrow.current { background-color: var(--graphnodepicker-current, var(--selection)); }
            graphnodeheader label { color: var(--graphnode-title, #ffffff); }
            graphnodeheader label.subtitle { opacity: 0.75; }
            graphpin label { color: var(--graphpin-text, var(--text)); }
            breadcrumbbar { color: var(--breadcrumb-text, var(--text-dim)); }
            crumb, crumboverflow {
                background-color: transparent; color: var(--breadcrumb-text, var(--text-dim));
                padding: 2px 4px; border-radius: var(--radius-small);
            }
            crumb:hover, crumboverflow:hover { background-color: var(--breadcrumb-hover, var(--control-hover)); color: var(--text-strong); }
            crumb:active, crumboverflow:active { background-color: var(--breadcrumb-pressed, var(--control-raised)); }
            crumb.current, crumb.current:hover, crumb.current:active {
                background-color: transparent; color: var(--breadcrumb-current, var(--text-strong));
            }
            crumb:focus-visible, crumboverflow:focus-visible { box-shadow: 0 0 0 var(--focus-width) var(--focus-ring); }
            crumbseparator { background-color: transparent; color: var(--breadcrumb-separator, var(--text-dim)); opacity: 0.7;
                             border-radius: var(--radius-small); }
            crumbseparator.menu:hover { background-color: var(--breadcrumb-hover, var(--control-hover)); opacity: 1; }
            breadcrumbbar > textfield.path { padding: 0 4px; }
            toolbar > separator { thickness: 1px; margin: 3px 3px; background-color: var(--toolbar-separator, var(--separator)); }
        )");
    }
}
