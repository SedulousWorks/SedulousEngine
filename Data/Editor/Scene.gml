<!--
  The scene page (Raptor's editor-gui spec, 5.3, layers 2 and 5): its bar (the editing controls,
  each an action) over its own hierarchy, viewport and inspector, as the mock draws it
  (Editor/Mock/scene.gml). A prefab is marked as one.
  Code puts the viewport in its pane (under the state a scene that did not load shows), binds the
  bar to the actions, the hierarchy to the scene and the inspector to its selection.
-->
<Panel class="page scene-page">
    <ToolBar id="scene-bar" class="page-toolbar">
        <ToolButton id="scene-save" icon="Editor/Icons/save.svg"/>
        <ToolButton id="scene-undo" icon="Editor/Icons/undo.svg"/>
        <ToolButton id="scene-redo" icon="Editor/Icons/redo.svg"/>
        <Separator/>
        <ToolButton id="scene-select" name="scene-transform" toggle="true" icon="Editor/Icons/select.svg"/>
        <ToolButton id="scene-move" name="scene-transform" toggle="true" icon="Editor/Icons/move.svg"/>
        <ToolButton id="scene-rotate" name="scene-transform" toggle="true" icon="Editor/Icons/rotate.svg"/>
        <ToolButton id="scene-scale" name="scene-transform" toggle="true" icon="Editor/Icons/scale.svg"/>
        <Separator/>
        <ToolButton id="scene-space" toggle="true" icon="Editor/Icons/world.svg"/>
        <ToolMenuButton id="scene-snap" toggle="true" split="true" icon="Editor/Icons/magnet.svg"/>
        <ToolButton id="scene-vertex-snap" toggle="true" icon="Editor/Icons/target.svg"/>
        <Spacer/>
        <ToolButton id="scene-frame" icon="Editor/Icons/frame-selection.svg"/>
        <Separator/>
        <Label id="scene-kind" class="badge page-kind" text="Prefab" tooltip="This page edits a prefab: one root, saved to every instance"/>
    </ToolBar>
    <Splitter id="scene-body" class="page-body" axis="horizontal" weights="0.2 0.56 0.24">
        <Panel id="scene-hierarchy" class="panel page-pane">
            <Panel class="panel-toolbar">
                <Panel class="search">
                    <Image class="search-icon" src="Editor/Icons/search.svg"/>
                    <TextField id="hierarchy-search" class="search-field" placeholder="Search the scene"/>
                    <Button id="hierarchy-clear" class="slot-button" icon="Editor/Icons/close.svg" tooltip="Clear the search"/>
                </Panel>
                <ToolButton id="hierarchy-add" class="icon-button" icon="Editor/Icons/plus.svg"/>
            </Panel>
            <TreeView id="hierarchy-tree" class="panel-body tree"/>
        </Panel>
        <Panel id="scene-viewport" class="viewport">
            <!-- The HUD's zones (layer 5, part 2): the view's chips at the top start; the stats and
                 the view gizmo (code adds it) at the top end; the zoom readout and the tool's status
                 at the bottom start. Code fills the chips' menus and what each shows. -->
            <Panel class="hud-zone hud-top-start">
                <Panel class="hud-bar">
                    <ToolMenuButton id="chip-projection" class="hud-chip" text="Perspective" tooltip="Projection and the axis views"/>
                    <ToolMenuButton id="chip-shading" class="hud-chip" text="Lit" tooltip="Shading, debug views and effects"/>
                    <ToolMenuButton id="chip-overlays" class="hud-chip" text="Overlays" tooltip="What the editor draws over the scene"/>
                </Panel>
            </Panel>
            <Panel id="hud-top-end" class="hud-zone hud-top-end">
                <Label id="hud-stats" class="hud-stats mono"/>
            </Panel>
            <Panel class="hud-zone hud-bottom-start">
                <Panel id="hud-zoom" class="hud-zoom">
                    <Label id="hud-zoom-focus"/>
                    <Label id="hud-zoom-cell"/>
                    <Panel id="hud-zoom-bar" class="hud-zoom-bar"><Label id="hud-zoom-length"/></Panel>
                </Panel>
                <Panel id="hud-status" class="hud-status">
                    <Image id="hud-status-icon" class="hud-status-icon"/>
                    <Label id="hud-status-mode"/>
                    <Label id="hud-status-space" class="hud-dim"/>
                    <Label id="hud-status-snap" class="hud-dim"/>
                    <Label id="hud-status-selection" class="hud-dim"/>
                </Panel>
            </Panel>
            <Panel id="scene-state" class="state-box failed scene-state">
                <Image class="state-icon" src="Editor/Icons/warning.svg"/>
                <Label class="state-title" text="This scene did not load"/>
                <Label id="scene-state-text" class="state-text" text="Its source could not be read; the Console says why. It is not saved over while it shows this."/>
            </Panel>
        </Panel>
        <Panel id="scene-inspector" class="panel page-pane">
            <Panel class="inspector-head">
                <Image id="inspector-icon" class="type-icon" src="Editor/Icons/cube.svg"/>
                <TextField id="inspector-name" class="name-field"/>
                <Label id="inspector-kind" class="inspector-kind"/>
            </Panel>
            <Panel class="panel-toolbar">
                <Panel class="search">
                    <Image class="search-icon" src="Editor/Icons/search.svg"/>
                    <TextField id="inspector-search" class="search-field" placeholder="Search properties"/>
                </Panel>
                <Button id="inspector-add" class="icon-button" icon="Editor/Icons/plus.svg" tooltip="Add a component"/>
            </Panel>
            <Label id="inspector-note" class="form-help inspector-note" text="Simulating: the values follow the run; edits wait until it stops."/>
            <Panel id="inspector-state" class="state-box inspector-state">
                <Image class="state-icon" src="Editor/Icons/cube.svg"/>
                <Label class="state-title" text="Nothing selected"/>
                <Label class="state-text" text="Select an entity in the hierarchy or the viewport to see its components."/>
            </Panel>
            <PropertyGrid id="inspector-grid" class="panel-body"/>
        </Panel>
    </Splitter>
</Panel>
