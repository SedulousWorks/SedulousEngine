// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - primary module interface unit for `foundation.gui`.
//
// A fresh, eepp-derived retained-mode UI framework built bottom-up on the our
// VG/Fonts stack. Distinct from the Sedulous-derived foundation.ui port:
// eepp is progressively sliced onto our infra, not lifted wholesale.
// Platform-agnostic core; a separate foundation.gui.shell bridge feeds its abstract
// input/clipboard seams.
//
// One named module composed of partitions (one per subsystem), re-exported here so
// consumers write a single `import foundation.gui;`. Add `export import :partition;`
// lines per subsystem partition.

export module foundation.gui;

export import :rect;
export import :diagnostic;
export import :transform2d;
export import :thickness;
export import :layout_style;

// Scene-graph core (Phase 1: tree)
export import :transformable;
export import :event;
export import :clipboard;
export import :mutation_queue;
export import :reactive;
export import :frame_stats;
export import :debug_overlay;
export import :node;

// Scene coordinator + actions (Phase 3)
export import :action;
export import :action_manager;
export import :actions;
export import :keymap;
export import :navigation;
export import :popup_placement;
export import :event_dispatcher;
export import :commands;
export import :data_model;
export import :accessibility;
export import :scene_root;
export import :element_types;
export import :gui_script;

// Drawing / render seam (Phase 2)
export import :draw_context;
export import :drawable;
export import :image_drawable;
export import :svg_drawable;
export import :picture_baker;
export import :node_box;

// Text (Phase 4)
export import :text;
export import :text_runs;
export import :text_layout;
export import :text_segmentation;
export import :undo_stack;
export import :input_filter;
export import :text_edit_model;
export import :text_editing_keys;

// Widget base (Phase 5)
export import :ui_node;
export import :ui_widget;

// Controls (Phase 7)
export import :label;
export import :button_base;
export import :button;
export import :check_box;
export import :radio;
export import :toggle_switch;
export import :range_value;
export import :range_widget;
export import :slider;
export import :progress_bar;
export import :panel;
export import :text_edit_base;
export import :text_field;
export import :text_area;
export import :number_field;
export import :editable_label;
export import :disclosure;
export import :expander;
export import :drag_preview;
export import :scroll_bar;
export import :scroll_view;
export import :image;
export import :separator;
export import :splitter;
export import :list_box;
export import :item_view;
export import :list_view;
export import :table_view;
export import :tree_view;
export import :tab_bar;
export import :tab_view;
export import :window;
export import :message_box;
export import :combo_box;
export import :menu;
export import :menu_bar;
export import :tooltip;
export import :color_picker;
export import :toast; // T7 of round three: notices that leave by themselves

// MVC data layer (Phase 8: models + model-backed views)
export import :variant;
export import :model_index;
export import :model;
export import :string_list_model;
export import :table_model;
export import :tree_model;
export import :sorting_proxy_model;

// Markup (Phase 8: declarative XML widget-tree loading)
export import :markup;
export import :style_check; // E1: what a sheet names that nothing takes

// CSS styling (Phase 6)
export import :resource_provider;
export import :parse_util;
export import :style_selector;
export import :media_query;
export import :style_rule;
export import :style_sheet;
export import :css_parser;
export import :css_values;
export import :style_value;
export import :style_properties;
export import :style_applier;
export import :easing;
export import :motion;
export import :style_interpolation;
export import :style_animation;
export import :tween;
export import :list_model;
export import :style_manager;
export import :theme;
