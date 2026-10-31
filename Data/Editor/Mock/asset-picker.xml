<!--
  The asset picker with its groups beside it (the user, 2026-10-25): the asset slot's pick, shaped
  as the assets browser is. At the left the project's groups, a tree (Favourites and All first); at
  the right what the chosen group holds of the slot's type, the current value checked; the search
  over every group while it has text (each match then says where it lives). Beside the search, tiles
  or a list for what the group holds, as the assets browser (the picker keeps the last one chosen).
  Enter picks, Esc keeps the value, None clears it. The mock shows a material slot over the Props
  group; its two view buttons switch.
-->
<Panel class="dialog picker asset-picker">
    <Panel class="picker-search asset-picker-bar">
        <Panel class="search"><Image class="search-icon" src="Editor/Icons/search.svg"/><TextField class="search-field" placeholder="Search materials"/></Panel>
        <Button id="asset-picker-tiles" class="icon-button" icon="Editor/Icons/tiles.svg" tooltip="Tiles"/>
        <Button id="asset-picker-list" class="icon-button checked" icon="Editor/Icons/list.svg" tooltip="List"/>
    </Panel>
    <Panel class="asset-picker-body">
        <TreeView id="asset-picker-groups" class="asset-picker-groups tree">
            <TreeItem text="Favourites" icon="Editor/Icons/star.svg"/>
            <TreeItem text="All Materials" icon="Editor/Icons/layers.svg"/>
            <TreeItem text="Content" icon="Editor/Icons/folder-open.svg" expanded="true">
                <TreeItem text="Materials" icon="Editor/Icons/folder-open.svg" expanded="true">
                    <TreeItem text="Props" icon="Editor/Icons/folder-open.svg"/>
                    <TreeItem text="Terrain" icon="Editor/Icons/folder.svg"/>
                    <TreeItem text="Characters" icon="Editor/Icons/folder.svg"/>
                </TreeItem>
                <TreeItem text="Models" icon="Editor/Icons/folder.svg">
                    <TreeItem text="Town" icon="Editor/Icons/folder.svg"/>
                </TreeItem>
                <TreeItem text="FX" icon="Editor/Icons/folder.svg"/>
            </TreeItem>
        </TreeView>
        <Panel id="asset-picker-rows" class="asset-picker-items">
            <Label class="asset-picker-where" text="Props  ·  5 materials"/>
            <Panel class="asset-row kit-selected"><Image class="row-icon cat-rendering" src="Editor/Icons/material.svg"/><Label class="row-name" text="Wood"/><Spacer/><Image class="badge-icon star" src="Editor/Icons/star.svg" tooltip="Favourite"/><Image class="row-trail" src="Editor/Icons/check.svg" tooltip="The current value"/></Panel>
            <Panel class="asset-row"><Image class="row-icon cat-rendering" src="Editor/Icons/material.svg"/><Label class="row-name" text="Wood_Dark"/></Panel>
            <Panel class="asset-row"><Image class="row-icon cat-rendering" src="Editor/Icons/material.svg"/><Label class="row-name" text="Wool"/></Panel>
            <Panel class="asset-row"><Image class="row-icon cat-rendering" src="Editor/Icons/material.svg"/><Label class="row-name" text="Metal_Rusty"/></Panel>
            <Panel class="asset-row"><Image class="row-icon cat-rendering" src="Editor/Icons/material.svg"/><Label class="row-name" text="Crate_Painted"/></Panel>
        </Panel>
        <Panel id="asset-picker-tiles-view" class="asset-picker-items asset-picker-tiles">
            <Label class="asset-picker-where" text="Props  ·  5 materials"/>
            <Panel class="asset-picker-grid">
                <Panel class="asset-tile kit-selected"><Panel class="asset-thumb"><Image class="asset-glyph cat-rendering" src="Editor/Icons/material.svg"/><Image class="badge-icon star" src="Editor/Icons/star.svg"/></Panel><Label class="asset-name" text="Wood"/></Panel>
                <Panel class="asset-tile"><Panel class="asset-thumb"><Image class="asset-glyph cat-rendering" src="Editor/Icons/material.svg"/></Panel><Label class="asset-name" text="Wood_Dark"/></Panel>
                <Panel class="asset-tile"><Panel class="asset-thumb"><Image class="asset-glyph cat-rendering" src="Editor/Icons/material.svg"/></Panel><Label class="asset-name" text="Wool"/></Panel>
                <Panel class="asset-tile"><Panel class="asset-thumb"><Image class="asset-glyph cat-rendering" src="Editor/Icons/material.svg"/></Panel><Label class="asset-name" text="Metal_Rusty"/></Panel>
                <Panel class="asset-tile"><Panel class="asset-thumb"><Image class="asset-glyph cat-rendering" src="Editor/Icons/material.svg"/></Panel><Label class="asset-name" text="Crate_Painted"/></Panel>
            </Panel>
        </Panel>
    </Panel>
    <Panel class="picker-foot"><Label class="picker-hint" text="Enter picks, Esc keeps Wood"/><Spacer/><Button class="ghost" text="None"/></Panel>
</Panel>
