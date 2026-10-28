<!--
  The scene page (Raptor's editor-gui spec, 5.3, layer 2): its bar over its own hierarchy,
  viewport and inspector, as the mock draws it (Editor/Mock/scene.gml). A prefab is marked as one.
  Code puts the viewport in its pane (under the state a scene that did not load shows) and binds the
  bar to the actions; the hierarchy and the inspector fill their panes in the next layers.
-->
<Panel class="page scene-page">
    <ToolBar id="scene-bar" class="page-toolbar">
        <ToolButton id="scene-save" icon="Editor/Icons/save.svg"/>
        <ToolButton id="scene-undo" icon="Editor/Icons/undo.svg"/>
        <ToolButton id="scene-redo" icon="Editor/Icons/redo.svg"/>
        <Spacer/>
        <Label id="scene-kind" class="badge page-kind" text="Prefab" tooltip="This page edits a prefab: one root, saved to every instance"/>
    </ToolBar>
    <Splitter id="scene-body" class="page-body" axis="horizontal" weights="0.2 0.56 0.24">
        <Panel id="scene-hierarchy" class="panel page-pane"/>
        <Panel id="scene-viewport" class="viewport">
            <Panel id="scene-state" class="state-box failed scene-state">
                <Image class="state-icon" src="Editor/Icons/warning.svg"/>
                <Label class="state-title" text="This scene did not load"/>
                <Label id="scene-state-text" class="state-text" text="Its source could not be read; the Console says why. It is not saved over while it shows this."/>
            </Panel>
        </Panel>
        <Panel id="scene-inspector" class="panel page-pane"/>
    </Splitter>
</Panel>
