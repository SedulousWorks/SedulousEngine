<!--
  Export Templates (Documentation/Specs/editor-gui.md, 5.2, layer 6): the player builds this
  editor exports with, the editor's and not a project's. The templates on the left, the selected
  one's details on the right with what can be done to it, and the ways to add one below. Code fills
  the list and the detail rows.
-->
<Panel class="dialog-body templates">
    <Panel class="templates-split">
        <ListView id="templates-list" class="templates-list"/>
        <Panel id="templates-empty" class="state-box templates-side">
            <Image class="state-icon" src="Editor/Icons/folder-open.svg"/>
            <Label class="state-title" text="No templates"/>
            <Label class="state-text" text="Install one from a folder, or create one from a build."/>
        </Panel>
        <Panel id="templates-detail" class="templates-detail templates-side">
            <Panel class="templates-head">
                <Image id="templates-icon" class="templates-icon"/>
                <Panel class="templates-title"><Label id="templates-name" class="templates-name"/><Label id="templates-id" class="templates-id mono"/></Panel>
            </Panel>
            <Panel id="templates-fields" class="form templates-fields"/>
            <Panel class="templates-verbs"><Button id="templates-reveal" text="Reveal Folder"/><Button id="templates-remove" class="ghost danger" text="Remove..."/></Panel>
        </Panel>
    </Panel>
    <Panel class="dialog-buttons"><Button id="templates-install" text="Install from Folder..."/><Button id="templates-create" text="Create from Build..."/><Spacer/><Button id="templates-close" class="primary" text="Close"/></Panel>
</Panel>
