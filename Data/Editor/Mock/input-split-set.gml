<!--
  The input map page, design B with a set chosen: the set's rows on the right, its name and
  priority, then its actions as the grid's list, its Add adding an action to this set (the tree's bar
  adds sets only: an add there would guess which set). An action's row names it and its kind, and
  opens it (as choosing it in the tree). The same map as input-split.gml's.
-->
<Panel class="page input-page mock">
    <ToolBar class="page-toolbar">
        <ToolButton command="mock.save" icon="Editor/Icons/save.svg"/>
        <ToolButton command="mock.undo" icon="Editor/Icons/undo.svg"/>
        <ToolButton command="mock.redo" icon="Editor/Icons/redo.svg"/>
        <ToolButton icon="Editor/Icons/revert.svg" tooltip="Discard Changes"/>
        <Separator/>
        <ToolButton icon="Editor/Icons/cook.svg" tooltip="Cook This Asset"/>
        <ToolButton icon="Editor/Icons/rebuild.svg" tooltip="Rebuild This Asset"/>
        <Spacer/>
        <Label class="badge page-kind" text="Input Map"/>
    </ToolBar>
    <Splitter class="page-body" axis="horizontal" weights="0.32 0.68">
        <Panel class="panel page-pane input-pane">
            <Panel class="panel-toolbar">
                <ToolButton icon="Editor/Icons/plus.svg" text="Set" shows-text="true" tooltip="Add a set"/>
                <ToolButton icon="Editor/Icons/trash.svg" tooltip="Remove the chosen set or action"/>
                <Spacer/>
            </Panel>
            <Panel class="search-row"><Panel class="search"><Image class="search-icon" src="Editor/Icons/search.svg"/><TextField class="search-field" placeholder="Find an action or an input"/></Panel></Panel>
            <TreeView class="panel-body tree">
                <TreeItem text="Gameplay" icon="Editor/Icons/Types/InputMapAsset.svg" icon-class="cat-scripting" expanded="true">
                    <TreeItem text="Move   2D" icon="Editor/Icons/move.svg"/>
                    <TreeItem text="Jump   Button" icon="Editor/Icons/play.svg"/>
                    <TreeItem text="Look   2D" icon="Editor/Icons/move.svg"/>
                </TreeItem>
                <TreeItem text="Menus" icon="Editor/Icons/Types/InputMapAsset.svg" icon-class="cat-scripting" expanded="true">
                    <TreeItem text="Navigate   2D" icon="Editor/Icons/move.svg"/>
                    <TreeItem text="Confirm   Button" icon="Editor/Icons/play.svg"/>
                    <TreeItem text="Back   Button" icon="Editor/Icons/play.svg"/>
                </TreeItem>
            </TreeView>
        </Panel>
        <Panel class="panel page-pane">
            <Panel class="kit-scroll">
                <Panel class="kit-grid input-sheet">
                    <Panel class="component-header"><Image class="row-arrow" src="Editor/Icons/chevron-down.svg"/><Label class="component-name" text="Set"/></Panel>
                    <Panel class="prop-row"><Label class="prop-name" text="Name"/><TextField text="Gameplay"/></Panel>
                    <Panel class="prop-row"><Label class="prop-name" text="Priority"/><NumberField value="0" step="1"/></Panel>
                    <Panel class="prop-row list-head"><Image class="row-arrow" src="Editor/Icons/chevron-down.svg"/><Label class="prop-name" text="Actions"/><Label class="list-count" text="3"/><Spacer/>
                        <Button class="slot-button" icon="Editor/Icons/plus.svg" tooltip="Add an action to Gameplay"/></Panel>
                    <Panel class="list-item"><Image class="grip" src="Editor/Icons/grip.svg" tooltip="Drag to reorder"/><Label class="list-index" text="1"/><Label class="input-source" text="Move"/><Label class="badge accent" text="2D axis"/><Label class="input-summary" text="Keys (four), Gamepad stick"/>
                        <Button class="slot-button" icon="Editor/Icons/open.svg" tooltip="Open Move"/><Button class="slot-button" icon="Editor/Icons/minus.svg" tooltip="Remove"/></Panel>
                    <Panel class="list-item"><Image class="grip" src="Editor/Icons/grip.svg"/><Label class="list-index" text="2"/><Label class="input-source" text="Jump"/><Label class="badge" text="Button"/><Label class="input-summary" text="Space, Gamepad A"/>
                        <Button class="slot-button" icon="Editor/Icons/open.svg" tooltip="Open Jump"/><Button class="slot-button" icon="Editor/Icons/minus.svg" tooltip="Remove"/></Panel>
                    <Panel class="list-item"><Image class="grip" src="Editor/Icons/grip.svg"/><Label class="list-index" text="3"/><Label class="input-source" text="Look"/><Label class="badge accent" text="2D axis"/><Label class="input-summary" text="Mouse movement, Right Stick"/>
                        <Button class="slot-button" icon="Editor/Icons/open.svg" tooltip="Open Look"/><Button class="slot-button" icon="Editor/Icons/minus.svg" tooltip="Remove"/></Panel>
                </Panel>
            </Panel>
        </Panel>
    </Splitter>
</Panel>
