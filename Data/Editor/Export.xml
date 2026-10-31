<!--
  Export (Documentation/Specs/editor-gui.md, 5.2, layer 6): the project's export presets on the
  left, the selected one on the right under a card naming the template it exports with, its
  settings on the property grid. Code fills the list, the card and the grid.
-->
<Panel class="dialog-body export">
    <Panel class="export-split">
        <Panel class="export-presets">
            <Panel class="export-presets-head">
                <Label class="export-heading" text="Presets"/><Spacer/>
                <Button id="export-add" class="icon-button" icon="Editor/Icons/plus.svg" tooltip="Add a preset for this platform"/>
                <Button id="export-duplicate" class="icon-button" icon="Editor/Icons/copy.svg" tooltip="Duplicate the preset"/>
                <Button id="export-remove" class="icon-button" icon="Editor/Icons/trash.svg" tooltip="Remove the preset"/>
            </Panel>
            <ListView id="export-list" class="export-list"/>
            <Label id="export-where" class="form-help"/>
        </Panel>
        <Panel class="export-preset">
            <Panel class="export-card">
                <Image id="export-card-icon" class="export-card-icon"/>
                <Panel class="export-card-text"><Label id="export-card-title" class="export-card-title"/><Label id="export-card-detail" class="export-card-detail"/></Panel>
            </Panel>
            <PropertyGrid id="export-grid" class="export-grid"/>
            <Panel class="export-files"><Button id="export-add-files" text="Add Files..." tooltip="Pick files to copy beside the player"/></Panel>
        </Panel>
    </Panel>
    <Panel class="dialog-buttons"><Button id="export-templates" text="Export Templates..."/><Spacer/><Button id="export-close" text="Close"/><Button id="export-all" text="Export All"/><Button id="export-run" class="primary" text="Export"/></Panel>
</Panel>
