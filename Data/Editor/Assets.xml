<!--
  The Assets panel (Documentation/Specs/editor-gui.md, 5.2, layer 7): the project's content as the
  mock draws it. A toolbar (where it is, a search over every group, a filter by type, tiles or a
  list) over the group tree and what the group holds; a state in its place when there is nothing
  to show. Code fills the tree, the breadcrumb and the content.
-->
<Panel class="panel assets">
    <Panel class="panel-toolbar">
        <BreadcrumbBar id="assets-crumbs" class="crumbs"/>
        <Spacer/>
        <Panel class="search beside-crumbs">
            <Image class="search-icon" src="Editor/Icons/search.svg"/>
            <TextField id="assets-search" class="search-field" placeholder="Search assets"/>
            <Button id="assets-clear-search" class="slot-button" icon="Editor/Icons/close.svg" tooltip="Clear the search"/>
        </Panel>
        <Button id="assets-types" class="icon-button" icon="Editor/Icons/filter.svg" tooltip="Filter by type"/>
        <Button id="assets-tiles" class="icon-button" icon="Editor/Icons/tiles.svg" tooltip="Tiles"/>
        <Button id="assets-list" class="icon-button" icon="Editor/Icons/list.svg" tooltip="List"/>
    </Panel>
    <Panel class="assets-body">
        <TreeView id="assets-groups" class="assets-groups tree"/>
        <ListView id="assets-content" class="asset-tiles" selection-mode="multi"/>
        <Panel id="assets-state" class="state-box assets-state">
            <Image id="assets-state-icon" class="state-icon" src="Editor/Icons/folder-open.svg"/>
            <Label id="assets-state-title" class="state-title"/>
            <Label id="assets-state-text" class="state-text"/>
            <Button id="assets-state-verb" class="ghost"/>
        </Panel>
    </Panel>
</Panel>
