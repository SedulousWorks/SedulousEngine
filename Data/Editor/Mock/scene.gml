<!--
  The scene page: its tool bar over its own hierarchy, viewport and inspector. A page carries its
  hierarchy and inspector, so two scene pages side by side each show their own scene.
-->
<Panel class="page scene-page">
    <ToolBar class="page-toolbar">
        <ToolButton command="mock.save" icon="Editor/Icons/save.svg"/>
        <ToolButton command="mock.undo" icon="Editor/Icons/undo.svg"/>
        <ToolButton command="mock.redo" icon="Editor/Icons/redo.svg"/>
        <Separator/>
        <ToolButton name="mock-tool" toggle="true" checked="true" icon="Editor/Icons/select.svg" tooltip="Select (Q)"/>
        <ToolButton name="mock-tool" toggle="true" icon="Editor/Icons/move.svg" tooltip="Move (W)"/>
        <ToolButton name="mock-tool" toggle="true" icon="Editor/Icons/rotate.svg" tooltip="Rotate (E)"/>
        <ToolButton name="mock-tool" toggle="true" icon="Editor/Icons/scale.svg" tooltip="Scale (R)"/>
        <Separator/>
        <ToolButton command="mock.space" toggle="true" icon="Editor/Icons/world.svg"/>
        <ToolButton command="mock.grid" toggle="true" icon="Editor/Icons/grid.svg"/>
        <ToolButton command="mock.snap" toggle="true" icon="Editor/Icons/magnet.svg"/>
        <Spacer/>
        <ToolButton command="mock.play" icon="Editor/Icons/play.svg"/>
        <ToolButton command="mock.pause" icon="Editor/Icons/pause.svg"/>
        <ToolButton command="mock.stop" icon="Editor/Icons/stop.svg"/>
        <Spacer/>
        <ToolMenuButton text="Lit" shows-text="true" icon="Editor/Icons/sun.svg">
            <MenuItem command="mock.view-lit"/>
            <MenuItem command="mock.view-unlit"/>
            <MenuItem command="mock.view-wire"/>
        </ToolMenuButton>
        <ToolButton command="mock.frame" icon="Editor/Icons/frame-selection.svg"/>
    </ToolBar>
    <Splitter class="page-body" axis="horizontal" weights="0.2 0.56 0.24">
        <Panel class="panel page-pane">
            <Panel class="panel-toolbar">
                <Panel class="search">
                    <Image class="search-icon" src="Editor/Icons/search.svg"/>
                    <TextField class="search-field" placeholder="Search the scene"/>
                </Panel>
                <Button class="icon-button" icon="Editor/Icons/plus.svg" tooltip="Create entity (Ctrl+Shift+N)"/>
            </Panel>
            <TreeView id="hierarchy-tree" class="panel-body tree">
                <TreeItem text="Level 1" icon="Editor/Icons/Types/SceneDocument.svg" expanded="true">
                    <TreeItem text="Sun" icon="Editor/Icons/Types/LightComponent.svg" icon-class="cat-rendering"/>
                    <TreeItem text="Sky" icon="Editor/Icons/Types/EnvironmentSettings.svg" icon-class="cat-rendering"/>
                    <TreeItem text="Player" icon="Editor/Icons/Types/CharacterComponent.svg" icon-class="cat-physics" expanded="true">
                        <TreeItem text="Camera" icon="Editor/Icons/Types/CameraComponent.svg" icon-class="cat-rendering"/>
                        <TreeItem text="Model" icon="Editor/Icons/Types/MeshComponent.svg" icon-class="cat-rendering"/>
                        <TreeItem text="Footsteps" icon="Editor/Icons/Types/AudioSourceComponent.svg" icon-class="cat-audio"/>
                    </TreeItem>
                    <TreeItem text="Ground" icon="Editor/Icons/Types/ColliderComponent.svg" icon-class="cat-physics"/>
                    <TreeItem text="Crates" icon="Editor/Icons/Types/PrefabDocument.svg" expanded="true">
                        <TreeItem text="Crate" icon="Editor/Icons/Types/MeshComponent.svg" icon-class="cat-rendering"/>
                        <TreeItem text="Crate 2" icon="Editor/Icons/Types/MeshComponent.svg" icon-class="cat-rendering"/>
                        <TreeItem text="Crate 3" icon="Editor/Icons/Types/MeshComponent.svg" icon-class="cat-rendering"/>
                    </TreeItem>
                    <TreeItem text="Barrel" icon="Editor/Icons/Types/RigidBodyComponent.svg" icon-class="cat-physics"/>
                    <TreeItem text="Lamp" icon="Editor/Icons/Types/LightComponent.svg" icon-class="cat-rendering"/>
                    <TreeItem text="Trigger" icon="Editor/Icons/Types/ScriptComponent.svg" icon-class="cat-scripting"/>
                </TreeItem>
            </TreeView>
        </Panel>
        <Panel class="viewport">
            <!-- The HUD's fixed zones (catalog 2.6), so nothing collides in the corners: the view's
                 menus and a tool's panel at the top start; the stats and the view gizmo at the top
                 end; the tool's status at the bottom start; the camera preview at the bottom end. -->
            <Panel class="hud-zone hud-top-start">
                <Panel class="hud-bar">
                    <Button class="hud-chip" text="Perspective" tooltip="Projection and view"/>
                    <Button class="hud-chip" text="Lit" tooltip="Shading"/>
                    <Button class="hud-chip" text="Overlays" tooltip="Grid, gizmos, markers"/>
                </Panel>
                <Panel id="tool-panel" class="hud-panel">
                    <Panel class="hud-panel-head">
                        <Image class="row-icon cat-terrain" src="Editor/Icons/Types/TerrainComponent.svg"/>
                        <Label class="hud-panel-title" text="Sculpt"/>
                        <Spacer/>
                        <Button class="slot-button" icon="Editor/Icons/close.svg" tooltip="Close the tool (Esc)"/>
                    </Panel>
                    <Panel class="segmented">
                        <Button class="segment" name="sculpt" toggle="true" checked="true" text="Raise"/>
                        <Button class="segment" name="sculpt" toggle="true" text="Lower"/>
                        <Button class="segment" name="sculpt" toggle="true" text="Smooth"/>
                        <Button class="segment" name="sculpt" toggle="true" text="Flatten"/>
                    </Panel>
                    <Panel class="hud-row"><Label class="hud-name" text="Radius"/><Panel class="slider-field"><Slider value="8" min="1" max="128"/><NumberField value="8" min="1" max="128"/></Panel></Panel>
                    <Panel class="hud-row"><Label class="hud-name" text="Strength"/><Panel class="slider-field"><Slider value="0.4" min="0" max="1"/><NumberField value="0.4" min="0" max="1" step="0.01"/></Panel></Panel>
                    <Label class="hud-help" text="Drag to raise. Shift lowers, Ctrl smooths."/>
                </Panel>
            </Panel>
            <Panel class="hud-zone hud-top-end">
                <Label class="hud-stats mono" text="60 fps  16.7 ms"/>
                <Panel class="view-gizmo" tooltip="Click an axis to look along it">
                    <Label class="axis axis-y" text="Y"/>
                    <Panel class="axis-row"><Label class="axis axis-z" text="Z"/><Panel class="axis-centre"/><Label class="axis axis-x" text="X"/></Panel>
                </Panel>
            </Panel>
            <Panel class="hud-zone hud-bottom-start">
                <Panel class="hud-status">
                    <Image class="hud-status-icon" src="Editor/Icons/move.svg"/>
                    <Label text="Move"/>
                    <Label class="hud-dim" text="World"/>
                    <Label class="hud-dim" text="Snap 0.5 m"/>
                    <Label class="hud-dim" text="Crate"/>
                </Panel>
            </Panel>
            <Panel class="hud-zone hud-bottom-end">
                <Panel class="camera-preview">
                    <Panel class="camera-preview-view"/>
                    <Panel class="camera-preview-foot"><Image class="row-icon cat-rendering" src="Editor/Icons/Types/CameraComponent.svg"/><Label text="Camera"/></Panel>
                </Panel>
            </Panel>
        </Panel>
        <Panel class="panel page-pane">
            <Panel class="inspector-head">
                <Image id="inspector-icon" class="type-icon" src="Editor/Icons/cube.svg"/>
                <TextField id="inspector-name" class="name-field" text="Crate"/>
                <Label id="inspector-kind" class="inspector-kind" text="Entity"/>
                <Button class="icon-button" icon="Editor/Icons/more.svg" tooltip="More"/>
            </Panel>
            <Panel class="panel-toolbar">
                <Panel class="search">
                    <Image class="search-icon" src="Editor/Icons/search.svg"/>
                    <TextField class="search-field" placeholder="Search properties"/>
                </Panel>
                <Button id="add-component" class="icon-button" icon="Editor/Icons/plus.svg" tooltip="Add component (Ctrl+Shift+A)"/>
            </Panel>
            <PropertyGrid id="inspector-grid" class="panel-body"/>
        </Panel>
    </Splitter>
</Panel>
