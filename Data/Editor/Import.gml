<!--
  Import (Documentation/Specs/editor-gui.md, 5.2, layer 7): one window for one file or many. Where
  they go (a click picks another group); the files, when there are several, each kept or not with
  its state; the chosen file's importer, options and what it would create, each kept or not and
  named; the line saying what Import does or why it waits. Code fills the files and the detail.
-->
<Panel class="dialog-body import">
    <Panel class="form import-into">
        <Label class="form-label" text="Into"/>
        <Panel class="form-field"><Button id="import-group" class="with-icon group-field" icon="Editor/Icons/folder.svg" tooltip="Pick the group"/></Panel>
    </Panel>
    <Panel class="import-split">
        <ScrollView id="import-files-scroll" class="import-files"><Panel id="import-files" class="import-files-body"/></ScrollView>
        <ScrollView class="import-detail"><Panel id="import-detail" class="import-detail-body"/></ScrollView>
    </Panel>
    <Label id="import-why" class="form-help import-why"/>
    <Panel class="dialog-buttons"><Spacer/><Button id="import-cancel" text="Cancel"/><Button id="import-run" class="primary" text="Import"/></Panel>
</Panel>
