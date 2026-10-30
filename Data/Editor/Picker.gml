<!--
  The picker (Documentation/Specs/editor-gui.md, 5.2, layer 5): the kit's picker, one for paths,
  groups and components (an asset slot's is AssetPicker.gml). A search over the rows, the rows under their sections (favourites first), an
  empty or no-match state saying what is so, and the foot's hint; a close at the search's end keeping
  the value, as Esc does. Code fills it.
-->
<Panel class="dialog picker">
    <Panel class="picker-search">
        <Panel class="search"><Image class="search-icon" src="Editor/Icons/search.svg"/><TextField id="picker-search" class="search-field"/></Panel>
        <Button id="picker-close" class="icon-button" icon="Editor/Icons/close.svg" tooltip="Close (Esc): the value stays"/>
    </Panel>
    <ListView id="picker-list" class="picker-list"/>
    <Panel id="picker-state" class="state-box picker-empty">
        <Image id="picker-state-icon" class="state-icon" src="Editor/Icons/folder-open.svg"/>
        <Label id="picker-state-title" class="state-title"/>
        <Label id="picker-state-text" class="state-text"/>
        <Button id="picker-state-verb" class="ghost"/>
    </Panel>
    <Panel class="picker-foot"><Label id="picker-hint" class="picker-hint"/></Panel>
</Panel>
