<!--
  The project manager (Documentation/Specs/editor-gui.md, 5.1, layer 13): the window's whole screen
  while no project is open. New Project and Open Folder first, then every recent project as a row
  or a tile, each with its own Open and menu: one click per action, no selection. Code fills the
  projects and the status line by id.
-->
<Panel class="manager">
    <Panel class="manager-column">
        <Panel class="manager-header">
            <Image class="manager-logo" src="Assets/branding/sedulous-logo.svg"/>
            <Label id="manager-engine" class="home-meta"/>
        </Panel>
        <Panel class="manager-actions">
            <Button id="manager-new" class="primary with-icon" icon="Editor/Icons/plus.svg" text="New Project..."/>
            <Button id="manager-open" class="with-icon" icon="Editor/Icons/folder-open.svg" text="Open Folder..."/>
        </Panel>
        <Panel class="manager-list-head">
            <Label class="home-heading" text="Recent projects"/>
            <Spacer/>
            <Panel class="segmented"><Button id="manager-list" class="segment" name="manager-view" toggle="true" text="List"/><Button id="manager-grid" class="segment" name="manager-view" toggle="true" text="Grid"/></Panel>
        </Panel>
        <Label id="manager-status" class="manager-status"/>
        <ScrollView class="manager-scroll"><Panel id="manager-projects" class="manager-projects"/></ScrollView>
    </Panel>
</Panel>
