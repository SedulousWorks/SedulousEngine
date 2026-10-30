<!--
  New Project (Documentation/Specs/editor-gui.md, 5.1, layer 13): a name and the folder it is made
  in. Create waits for both; the project is made in a folder of its name there.
-->
<Panel class="dialog-body new-project">
    <Panel class="form">
        <Label class="form-label" text="Name"/>
        <Panel class="form-field"><TextField id="new-project-name" placeholder="Project name"/></Panel>
        <Label class="form-label" text="In"/>
        <Panel class="form-field">
            <Panel class="new-project-folder"><TextField id="new-project-parent" placeholder="The folder it is made in"/><Button id="new-project-browse" text="Browse..."/></Panel>
            <Label id="new-project-where" class="form-help"/>
        </Panel>
    </Panel>
    <Panel class="dialog-buttons"><Spacer/><Button id="new-project-cancel" text="Cancel"/><Button id="new-project-create" class="primary" text="Create" enabled="false"/></Panel>
</Panel>
