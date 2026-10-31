<!--
  The scene page: its tool bar over its own hierarchy, viewport and inspector. A page carries its
  hierarchy and inspector, so two scene pages side by side each show their own scene.
-->
<Panel class="page scene-page mock">
    <!-- The bar keeps the editing controls (ruling 22): the transform tools as one choice, the
         space, Snap with its increments, Vertex Snap; Simulate; the scene tools by category; Frame. -->
    <ToolBar class="page-toolbar">
        <ToolButton command="mock.save" icon="Editor/Icons/save.svg"/>
        <ToolButton command="mock.undo" icon="Editor/Icons/undo.svg"/>
        <ToolButton command="mock.redo" icon="Editor/Icons/redo.svg"/>
        <Separator/>
        <ToolButton command="mock.tool-select" name="mock-tool" toggle="true" icon="Editor/Icons/select.svg"/>
        <ToolButton command="mock.tool-move" name="mock-tool" toggle="true" checked="true" icon="Editor/Icons/move.svg"/>
        <ToolButton command="mock.tool-rotate" name="mock-tool" toggle="true" icon="Editor/Icons/rotate.svg"/>
        <ToolButton command="mock.tool-scale" name="mock-tool" toggle="true" icon="Editor/Icons/scale.svg"/>
        <Separator/>
        <ToolButton command="mock.space" toggle="true" icon="Editor/Icons/world.svg"/>
        <ToolMenuButton command="mock.snap" toggle="true" split="true" icon="Editor/Icons/magnet.svg">
            <Menu text="Move">
                <MenuItem text="0.1 m" checkable="true"/>
                <MenuItem text="0.25 m" checkable="true"/>
                <MenuItem text="0.5 m" checkable="true" checked="true"/>
                <MenuItem text="1 m" checkable="true"/>
                <MenuItem text="2 m" checkable="true"/>
                <MenuItem text="The grid's cell" checkable="true"/>
            </Menu>
            <Menu text="Rotate">
                <MenuItem text="5&#176;" checkable="true"/>
                <MenuItem text="15&#176;" checkable="true" checked="true"/>
                <MenuItem text="45&#176;" checkable="true"/>
                <MenuItem text="90&#176;" checkable="true"/>
            </Menu>
            <Menu text="Scale">
                <MenuItem text="0.1" checkable="true"/>
                <MenuItem text="0.25" checkable="true" checked="true"/>
                <MenuItem text="0.5" checkable="true"/>
            </Menu>
        </ToolMenuButton>
        <ToolButton command="mock.vertex-snap" toggle="true" icon="Editor/Icons/target.svg"/>
        <Spacer/>
        <ToolButton command="mock.play" icon="Editor/Icons/play.svg"/>
        <ToolButton command="mock.pause" icon="Editor/Icons/pause.svg"/>
        <ToolButton command="mock.stop" icon="Editor/Icons/stop.svg"/>
        <Spacer/>
        <ToolMenuButton id="mock-terrain-tools" text="Terrain" icon="Editor/Icons/Types/TerrainComponent.svg" tooltip="Terrain tools">
            <MenuItem command="mock.terrain-sculpt"/>
            <MenuItem command="mock.terrain-paint"/>
            <MenuItem command="mock.terrain-holes"/>
        </ToolMenuButton>
        <ToolMenuButton text="Vegetation" icon="Editor/Icons/Types/TerrainVegetationComponent.svg" tooltip="Vegetation tools">
            <MenuItem command="mock.vegetation-paint"/>
            <MenuItem command="mock.vegetation-props"/>
        </ToolMenuButton>
        <ToolButton command="mock.spline" toggle="true" icon="Editor/Icons/Types/SplineComponent.svg"/>
        <Separator/>
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
                <!-- The view's controls (ruling 22), each chip saying what is on. -->
                <Panel class="hud-bar">
                    <ToolMenuButton id="chip-projection" class="hud-chip" text="Perspective" tooltip="Projection and the axis views">
                        <MenuItem text="Perspective" checkable="true" checked="true"/>
                        <MenuItem text="Orthographic" checkable="true"/>
                        <MenuSeparator/>
                        <MenuItem text="Top"/>
                        <MenuItem text="Bottom"/>
                        <MenuItem text="Front"/>
                        <MenuItem text="Back"/>
                        <MenuItem text="Right"/>
                        <MenuItem text="Left"/>
                    </ToolMenuButton>
                    <ToolMenuButton id="chip-shading" class="hud-chip" text="Lit" tooltip="Shading, debug views and effects">
                        <MenuItem text="Lit" checkable="true" checked="true"/>
                        <MenuItem text="Unlit" checkable="true"/>
                        <Menu text="Debug View">
                            <MenuItem text="Normals" checkable="true"/>
                            <MenuItem text="Roughness" checkable="true"/>
                            <MenuItem text="Metallic" checkable="true"/>
                            <MenuItem text="Shadow Cascades" checkable="true"/>
                            <MenuItem text="Light Clusters" checkable="true"/>
                            <MenuItem text="Overbright" checkable="true"/>
                        </Menu>
                        <MenuItem command="mock.textures"/>
                        <MenuSeparator/>
                        <Menu text="Effects">
                            <MenuItem text="Bloom" checkable="true" checked="true"/>
                            <MenuItem text="Ambient Occlusion" checkable="true" checked="true"/>
                            <MenuItem text="Reflections (SSR)" checkable="true" checked="true"/>
                            <MenuItem text="Global Illumination (SSGI)" checkable="true" checked="true"/>
                            <MenuItem text="Anti-aliasing" checkable="true" checked="true"/>
                            <MenuSeparator/>
                            <MenuItem text="Frustum Culling" checkable="true" checked="true"/>
                        </Menu>
                        <Menu text="MSAA">
                            <MenuItem text="Off" checkable="true" checked="true"/>
                            <MenuItem text="2x" checkable="true"/>
                            <MenuItem text="4x" checkable="true"/>
                        </Menu>
                    </ToolMenuButton>
                    <ToolMenuButton id="chip-overlays" class="hud-chip" text="Overlays" tooltip="What the editor draws over the scene">
                        <MenuItem text="Grid" checkable="true" checked="true"/>
                        <Menu text="Grid Plane">
                            <MenuItem text="XZ (ground)" checkable="true" checked="true"/>
                            <MenuItem text="XY" checkable="true"/>
                            <MenuItem text="YZ" checkable="true"/>
                        </Menu>
                        <MenuItem text="Entity Markers" checkable="true"/>
                        <MenuItem text="Colliders" checkable="true"/>
                        <MenuItem text="LOD Tint" checkable="true"/>
                        <MenuSeparator/>
                        <MenuItem text="Stats" checkable="true" checked="true"/>
                    </ToolMenuButton>
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
