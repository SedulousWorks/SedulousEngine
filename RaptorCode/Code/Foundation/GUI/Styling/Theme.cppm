// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :theme partition
//
// A theme is a stylesheet at the user-agent origin: built-in CSS that styles the standard widget
// tags and their parts (slider::fill, window::title, scrollbar::thumb, checkbox::mark, ...). The
// built-in one is written in tokens (E13 of Specs/gui-lab-evolution-2.md), custom properties on
// :root that every widget inherits, in three layers:
//   1. Base tokens: the palette (surfaces, controls, the accent and the text on it, text, borders,
//      the focus ring, selection, danger, success, warning) and the metrics (radii, a spacing
//      scale, font sizes, border and focus widths, motion's durations and easing). A theme that
//      sets only these restyles everything consistently.
//   2. Derived states (hover, pressed, disabled), mixed from the base with color-mix() unless a
//      theme sets its own.
//   3. Widget tokens: each part reads a token of its own, falling back to a base one
//      (`button { background-color: var(--button-background, var(--accent)) }`), so a theme can
//      change one control alone, its art too (a border-image or an SVG).
// Light and high contrast are @media (prefers-color-scheme) and (prefers-contrast) blocks of the
// same sheet, chosen by the host's flags (GUIContext::SetColorScheme). A game ships its own theme
// as a sheet (overriding tokens, or importing this one), set with SetUserAgentSheet.

module;
#include "Core/Prelude.h"

export module foundation.gui:theme;

import foundation.core; // StringView

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// The built-in theme: tokens, dark by default, light and high contrast by media query.
    [[nodiscard]] inline core::StringView DefaultThemeCSS()
    {
        return core::StringView(u8R"(
            /* 1. Base tokens (dark). */
            :root {
                --accent: #33507a; --on-accent: #f4f7fb; --accent-strong: #4a90d9; --selection: #2f5f9e; --focus-ring: #4f9cff;
                --surface: #14161c; --surface-sunken: #14161a; --surface-raised: #1d2129; --surface-header: #252a35;
                --control: #20242b; --control-raised: #23262e; --chrome: #1a1d24; --chrome-raised: #22262f;
                --track: #2b2f37; --scrollbar: #1e2128; --thumb: #4a505c;
                --text: #d2d8e0; --text-dim: #c2c9d4; --text-strong: #f0f4f8; --text-title: #e6ebf2;
                --border: #343b49; --outline: #8a93a2; --separator: #3a3f4b; --grip: #5a6274;
                --danger: #c0392b; --success: #3fa06a; --warning: #d9a03a; --shadow-color: rgba(0, 0, 0, 0.5);
                --window-close-text: #aab3c2;
                --radius-small: 3px; --radius: 6px; --radius-large: 10px;
                --space-xs: 2px; --space-s: 4px; --space-m: 6px; --space-l: 9px; --space-xl: 14px;
                --font-small: 12px; --font-body: 16px; --font-title: 20px; --font-heading: 28px;
                --border-width: 1px; --focus-width: 2px;
                --motion-fast: 0.15s; --motion-slow: 0.3s; --easing: ease;
                /* 2. Derived states. */
                --control-hover: color-mix(in srgb, var(--control-raised) 94%, white);
                --chrome-hover: color-mix(in srgb, var(--chrome-raised) 90%, white);
                --overlay-hover: rgba(255, 255, 255, 0.18);
                --row-hover: rgba(255, 255, 255, 0.07);
                --disabled-opacity: 0.45;
            }
            /* 3. Widgets, each part through a token of its own. */
            .panel    { background-color: var(--panel-background, var(--surface)); }
            label, listboxitem, menuitem, menusubmenu, checkbox, radio, switch, expanderheader { color: var(--label-text, var(--text)); }
            button    { background-color: var(--button-background, var(--accent)); color: var(--button-text, var(--on-accent));
                        padding: var(--button-padding, var(--space-l)); text-align: center; transition: opacity var(--motion-fast); }
            button:hover  { opacity: 0.9; }
            button:active { opacity: 0.78; }
            tab           { background-color: var(--tab-background, var(--control-raised)); color: var(--tab-text, var(--text-dim));
                            padding: var(--space-m) 10; column-gap: var(--space-m); text-align: start; }
            tab:hover     { background-color: var(--tab-hover-background, var(--control-hover)); }
            tab:checked   { background-color: var(--tab-checked-background, var(--accent)); color: var(--tab-checked-text, var(--on-accent)); }
            tab.dragging  { background-color: var(--tab-dragging-background, #4a6fa5); color: var(--tab-dragging-text, #ffffff); cursor: grabbing; }
            tab > close   { padding: var(--space-xs); border-radius: var(--radius-small); }
            tab > close:hover { background-color: var(--overlay-hover); }
            tablist       { color: var(--text-dim); padding: var(--space-m) 8; }
            tablist:hover { background-color: var(--control-hover); }
            closeall      { color: var(--text-dim); padding: var(--space-m) 8; }
            closeall:hover { background-color: var(--control-hover); }
            textfield, textarea { background-color: var(--field-background, var(--control)); color: var(--field-text, var(--text-strong));
                                  padding: var(--space-m); cursor: text; }
            numberfield { background-color: var(--field-background, var(--control)); color: var(--field-text, var(--text-strong));
                          padding: var(--space-m); cursor: text; }
            spinbutton::arrow { background-color: var(--spinbutton-arrow); }
            listbox   { background-color: var(--list-background, var(--surface-sunken)); }
            listbox::selection { background-color: var(--list-selection, var(--selection)); }
            listview  { background-color: var(--list-background, var(--surface-sunken)); color: var(--list-text, var(--text)); }
            listview::selection { background-color: var(--list-selection, var(--selection)); }
            tableview { background-color: var(--list-background, var(--surface-sunken)); color: var(--list-text, var(--text)); }
            tableview::selection { background-color: var(--list-selection, var(--selection)); }
            tableheader { background-color: var(--table-header-background, var(--control-raised)); }
            tableheadercell { color: var(--table-header-text, var(--text-dim)); }
            treeview  { background-color: var(--list-background, var(--surface-sunken)); color: var(--list-text, var(--text)); }
            treeview::selection { background-color: var(--list-selection, var(--selection)); }
            listboxitem:hover, listviewrow:hover, tablerow:hover, treerow:hover { background-color: var(--list-hover, var(--row-hover)); }
            combobox  { background-color: var(--combobox-background, var(--control)); color: var(--combobox-text, var(--text-strong));
                        padding: var(--space-s); }
            scrollview { background-color: var(--scrollview-background, var(--surface-sunken)); }
            scrollbar  { background-color: var(--scrollbar-background, var(--scrollbar)); }
            scrollbar::thumb { background-color: var(--scrollbar-thumb, var(--thumb)); }
            window, messagebox { background-color: var(--window-background, var(--surface-raised)); color: var(--window-text, var(--text));
                                 border: var(--border-width) solid var(--window-border, var(--border)); border-radius: var(--radius-large);
                                 box-shadow: 0 14px 36px var(--shadow-color); }
            window::title, messagebox::title { background-color: var(--window-title-background, var(--surface-header)); }
            window::grip  { background-color: var(--window-grip, var(--grip)); }
            titlebar > label { color: var(--window-title-text, var(--text-title)); }
            titlebar > close { color: var(--window-close-text, var(--outline)); padding: var(--space-s); border-radius: var(--space-s); }
            titlebar > close:hover { background-color: var(--danger); color: #ffffff; }
            .dialogmessage { white-space: normal; }
            .dialogbutton { background-color: var(--button-background, var(--accent)); color: var(--button-text, var(--on-accent));
                            border-radius: var(--radius); padding: var(--space-m) var(--space-xl); transition: opacity var(--motion-fast); }
            .dialogbutton:hover { opacity: 0.9; }
            menu       { background-color: var(--menu-background, var(--chrome)); }
            menuitem::highlight, menusubmenu::highlight { background-color: var(--menu-highlight, var(--selection)); }
            menuseparator::line { background-color: var(--menu-separator, var(--separator)); }
            splitter-handle { background-color: var(--splitter-handle, var(--separator)); }
            splitter-handle:hover, splitter-handle:active, splitter-handle:focus-visible
                { background-color: var(--splitter-handle-active, var(--accent)); }
            menubar    { background-color: var(--menubar-background, var(--chrome-raised)); }
            .menubutton          { background-color: var(--menubar-background, var(--chrome-raised)); color: var(--text); padding: var(--space-m); }
            .menubutton:hover    { background-color: var(--menubar-hover, var(--chrome-hover)); }
            .menubutton.selected { background-color: var(--menubar-selected, var(--accent)); color: var(--menubar-selected-text, var(--on-accent)); }
            tabbar     { background-color: var(--tabbar-background, var(--chrome)); }
            tabpages   { background-color: var(--tabpages-background, var(--chrome)); }
            slider::track { background-color: var(--slider-track, var(--track)); }
            slider::fill  { background-color: var(--slider-fill, var(--accent-strong)); }
            slider::thumb { background-color: var(--slider-thumb, #cfd6e0); }
            slider::focus { border-color: var(--focus-ring); }
            dragpreview { background-color: var(--dragpreview-background, #2b3444); color: var(--text-strong); border-radius: var(--radius);
                          opacity: 0.92; }
            dragpreview::effect { background-color: var(--dragpreview-effect, #8fc1ff); }
            /* A torn tab's ghost: the tab as it was, a little see-through. */
            dragpreview.tab { background-color: var(--tab-checked-background, var(--accent)); color: var(--tab-checked-text, var(--on-accent));
                              padding: var(--space-m) 10; border-radius: 0; opacity: 0.85; }
            tooltip.drophint.refused { color: var(--drop-refused, #ff8a80); }
            /* Toasts: a card per notice, its mark the severity's colour; in and out by transitions. */
            toast { background-color: var(--toast-background, var(--surface-raised)); color: var(--text);
                    border-radius: var(--radius); padding: var(--space-m) var(--space-l); width: var(--toast-width, 320px);
                    box-shadow: 0 4px 14px var(--shadow-color);
                    transition: opacity var(--motion-fast), transform var(--motion-fast); }
            /* How it comes and goes (the core's :entering and :leaving), a request's class choosing: a slide
               up (the default), `pop` (scaled in), `still` (no motion); a game's own classes add their own. */
            toast:entering, toast:leaving { opacity: 0; transform: translate(0, 8px); }
            toast.pop:entering, toast.pop:leaving { transform: scale(0.9); }
            toast.still { transition: none; }
            toast.bare { background-color: transparent; padding: 0; box-shadow: none; width: auto; }
            toastmark { width: 4px; height: 100%; min-height: 16px; border-radius: 2px; background-color: var(--toast-info, var(--accent)); }
            toast.success toastmark { background-color: var(--toast-success, var(--success)); }
            toast.warning toastmark { background-color: var(--toast-warning, var(--warning)); }
            toast.error toastmark { background-color: var(--toast-error, var(--danger)); }
            /* Its text wraps at the card, a word longer than a line (a path) broken inside it. */
            toast label.title, toast label.message { white-space: normal; overflow-wrap: break-word; }
            toast label.title { color: var(--text-strong); font-weight: bold; }
            toast label.count { color: var(--text-dim); }
            toast button.close { background-color: transparent; color: var(--text-dim); padding: 0 var(--space-s); }
            toast button.close:hover { color: var(--text-strong); }
            toast button.action { padding: var(--space-xs) var(--space-l); }
            /* The focus ring: where the keyboard is (a field shows it while it has the caret). */
            button:focus-visible, combobox:focus-visible, checkbox:focus-visible, radio:focus-visible,
            switch:focus-visible, tab:focus-visible, expanderheader:focus-visible, listbox:focus-visible,
            listview:focus-visible, treeview:focus-visible, tableview:focus-visible, editablelabel:focus-visible,
            menubar:focus-within { box-shadow: 0 0 0 var(--focus-width) var(--focus-ring); }
            textfield:focus, textarea:focus, numberfield:focus { box-shadow: 0 0 0 var(--focus-width) var(--focus-ring); }
            checkbox::box  { border-color: var(--checkbox-box, var(--outline)); }
            checkbox::mark { background-color: var(--checkbox-mark, var(--accent-strong)); }
            radio::ring { border-color: var(--radio-ring, var(--outline)); }
            radio::dot  { background-color: var(--radio-dot, var(--accent-strong)); }
            progressbar::track { background-color: var(--progress-track, var(--track)); }
            progressbar::fill  { background-color: var(--progress-fill, var(--accent-strong)); }
            /* Skins are tokens too: a theme's art for a control (a border-image), none by default, and
               a radius beside each, so a box as round as its art keeps its focus ring to it. */
            button { border-image: var(--button-skin, none); border-radius: var(--button-radius, 0); }
            button:hover { border-image: var(--button-hover-skin, var(--button-skin, none)); }
            button:active { border-image: var(--button-pressed-skin, var(--button-hover-skin, var(--button-skin, none))); }
            textfield, textarea, numberfield { border-image: var(--field-skin, none); border-radius: var(--field-radius, 0); }
            combobox { border-image: var(--combobox-skin, var(--field-skin, none)); border-radius: var(--combobox-radius, var(--field-radius, 0)); }
            window, messagebox { border-image: var(--window-skin, none); border-radius: var(--window-radius, var(--radius-large)); }
            menu { border-image: var(--menu-skin, none); border-radius: var(--menu-radius, 0); }

            /* Light: the base tokens again, and the widget tokens whose light look is not the base's. */
            @media (prefers-color-scheme: light) {
                :root {
                    --accent: #cdd8ea; --on-accent: #17202b; --accent-strong: #2f6fb0; --selection: #bcd6f4; --focus-ring: #2f7de1;
                    --surface: #dde3ec; --surface-sunken: #f2f4f8; --surface-raised: #f6f8fb; --surface-header: #e7ebf2;
                    --control: #ffffff; --control-raised: #cfd6e2; --chrome: #f2f4f8; --chrome-raised: #d0d6e0;
                    --track: #c2cad6; --scrollbar: #d5dbe4; --thumb: #a3abb8;
                    --text: #1c2530; --text-dim: #3a4453; --text-strong: #10161d; --text-title: #17202b;
                    --border: #c9d1dd; --outline: #5a6474; --separator: #c2c8d2; --grip: #9aa4b4;
                    --shadow-color: rgba(20, 30, 50, 0.25);
                    --control-hover: color-mix(in srgb, var(--control-raised) 94%, black);
                    --chrome-hover: color-mix(in srgb, var(--chrome-raised) 92%, black);
                    --overlay-hover: rgba(0, 0, 0, 0.12);
                    --row-hover: rgba(0, 0, 0, 0.06);
                    --tab-checked-background: #ffffff; --tab-checked-text: #17202b; --tab-dragging-background: #9cc0ef; --tab-dragging-text: #17202b;
                    --menu-highlight: #9cc0ef; --menubar-selected: #9cc0ef; --menubar-selected-text: #17202b;
                    --tabbar-background: #d8dee8; --tabpages-background: #e6eaf1; --slider-thumb: #3a4658;
                    --spinbutton-arrow: #5a6474; --dragpreview-background: #ffffff; --dragpreview-effect: #2f6fb0;
                    --drop-refused: #c0392b; --window-title-text: #17202b; --window-close-text: #5a6474;
                }
            }
            /* More contrast: stronger outlines, brighter text, a wider focus ring. */
            @media (prefers-contrast: more) {
                :root { --border: #9aa4b4; --outline: #c2c9d4; --separator: #8a93a2; --text-dim: var(--text); --focus-width: 3px; }
            }
            /* Less motion: a toast fades, whatever its class asks, without sliding or scaling. */
            @media (prefers-reduced-motion: reduce) {
                toast:entering, toast:leaving, toast.pop:entering, toast.pop:leaving { transform: none; }
            }
        )");
    }
}
