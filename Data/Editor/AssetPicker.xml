<!--
  The asset picker (Raptor's editor-gui spec, ruling 24): an asset slot's pick, shaped as
  the assets browser. The search and the tiles or list toggles; the project's groups a tree at the
  left (Favourites and All first); what the chosen group holds at the right, under a line saying
  where and how many; the state when there is nothing to show; the foot's hint. Its close at the
  bar's end keeps the value, as Esc does; a slot's own clear sets it to nothing. Code fills it.
-->
<Panel class="dialog picker asset-picker">
    <Panel class="picker-search asset-picker-bar">
        <Panel class="search"><Image class="search-icon" src="Editor/Icons/search.svg"/><TextField id="asset-picker-search" class="search-field"/></Panel>
        <Button id="asset-picker-tiles" class="icon-button" icon="Editor/Icons/tiles.svg" tooltip="Tiles"/>
        <Button id="asset-picker-list" class="icon-button" icon="Editor/Icons/list.svg" tooltip="List"/>
        <Button id="asset-picker-close" class="icon-button" icon="Editor/Icons/close.svg" tooltip="Close (Esc): the value stays"/>
    </Panel>
    <Panel class="asset-picker-body">
        <TreeView id="asset-picker-groups" class="asset-picker-groups tree"/>
        <Panel class="asset-picker-items">
            <Label id="asset-picker-where" class="asset-picker-where"/>
            <ListView id="asset-picker-items" class="asset-picker-list"/>
            <Label id="asset-picker-state" class="asset-picker-state"/>
        </Panel>
    </Panel>
    <Panel class="picker-foot"><Label id="asset-picker-hint" class="picker-hint"/></Panel>
</Panel>
