<!--
  Create Asset (Documentation/Specs/editor-gui.md, 5.2, layer 5): the group a new asset goes in
  (a click picks another) and its name, checked as it is typed: the line under the name says why
  Create waits, or what it will make.
-->
<Panel class="dialog-body asset-create">
    <Panel class="form">
        <Label class="form-label" text="Group"/>
        <Panel class="form-field"><Button id="asset-create-group" class="with-icon group-field" icon="Editor/Icons/folder.svg" tooltip="Pick the group"/></Panel>
        <Label class="form-label" text="Name"/>
        <Panel class="form-field"><TextField id="asset-create-name"/><Label id="asset-create-why" class="form-help"/></Panel>
    </Panel>
    <Panel class="dialog-buttons"><Spacer/><Button id="asset-create-cancel" class="ghost" text="Cancel"/><Button id="asset-create-create" class="primary" text="Create"/></Panel>
</Panel>
