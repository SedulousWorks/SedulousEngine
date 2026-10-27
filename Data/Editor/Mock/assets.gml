<!-- The assets browser: groups, a breadcrumb, a search and the assets as tiles. -->
<Panel class="panel">
    <Panel class="panel-toolbar">
        <BreadcrumbBar id="assets-crumbs" class="crumbs"/>
        <Spacer/>
        <Panel class="search beside-crumbs">
            <Image class="search-icon" src="Editor/Icons/search.svg"/>
            <TextField class="search-field" placeholder="Search assets"/>
        </Panel>
        <Button class="icon-button" icon="Editor/Icons/filter.svg" tooltip="Filter by type"/>
        <Button class="icon-button checked" icon="Editor/Icons/tiles.svg" tooltip="Tiles"/>
        <Button class="icon-button" icon="Editor/Icons/list.svg" tooltip="List"/>
    </Panel>
    <Panel class="assets-body">
        <TreeView id="assets-groups" class="assets-groups tree">
            <TreeItem text="Content" expanded="true">
                <TreeItem text="Levels"/>
                <TreeItem text="Models" expanded="true">
                    <TreeItem text="Props"/>
                    <TreeItem text="Characters"/>
                </TreeItem>
                <TreeItem text="Materials"/>
                <TreeItem text="Textures"/>
                <TreeItem text="Audio"/>
                <TreeItem text="GUI"/>
            </TreeItem>
        </TreeView>
        <ListView class="asset-tiles" layout="grid" cell-width="96" cell-height="92" selection-mode="multi"
                  items="Level 1|Level 2|Crate|Barrel|Ground|Rock|Brick|Metal|Sky|Hero|Run|Jump|Footstep|Theme|Menu|Player">
            <template>
                <Panel class="asset-tile">
                    <Panel class="asset-thumb"><Image class="asset-glyph" src="Editor/Icons/cube.svg"/></Panel>
                    <Label class="asset-name" text="{{item}}"/>
                </Panel>
            </template>
        </ListView>
    </Panel>
</Panel>
