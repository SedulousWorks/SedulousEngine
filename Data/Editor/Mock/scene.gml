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
                <TreeItem text="Level 1" expanded="true">
                    <TreeItem text="Sun"/>
                    <TreeItem text="Sky"/>
                    <TreeItem text="Player" expanded="true">
                        <TreeItem text="Camera"/>
                        <TreeItem text="Model"/>
                        <TreeItem text="Footsteps"/>
                    </TreeItem>
                    <TreeItem text="Ground"/>
                    <TreeItem text="Crates" expanded="true">
                        <TreeItem text="Crate"/>
                        <TreeItem text="Crate 2"/>
                        <TreeItem text="Crate 3"/>
                    </TreeItem>
                    <TreeItem text="Barrel"/>
                    <TreeItem text="Lamp"/>
                    <TreeItem text="Trigger"/>
                </TreeItem>
            </TreeView>
        </Panel>
        <Panel class="viewport">
            <Panel class="viewport-hud viewport-hud-start">
                <Label class="hud-text" text="Perspective"/>
            </Panel>
            <Panel class="viewport-hud viewport-hud-end">
                <Label class="hud-text mono" text="60 fps  16.7 ms"/>
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
