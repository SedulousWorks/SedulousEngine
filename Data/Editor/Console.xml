<!--
  The Console (Documentation/Specs/editor-gui.md, 5.2, layer 1): the editor's log. Its levels as
  chips that show or hide their lines (Debug holds the trace lines too), a search, Clear,
  then the lines; code fills the list and the chips' counts.
-->
<Panel class="panel console">
    <Panel class="panel-toolbar">
        <Button id="console-debug" class="chip checked debug" text="Debug"/>
        <Button id="console-info" class="chip checked" text="Info"/>
        <Button id="console-warnings" class="chip checked warning" text="Warnings"/>
        <Button id="console-errors" class="chip checked error" text="Errors"/>
        <Spacer/>
        <Panel class="search">
            <Image class="search-icon" src="Editor/Icons/search.svg"/>
            <TextField id="console-search" class="search-field" placeholder="Search the log"/>
            <Button id="console-clear-search" class="slot-button" icon="Editor/Icons/close.svg" tooltip="Clear the search"/>
        </Panel>
        <Button id="console-clear" class="icon-button" icon="Editor/Icons/trash.svg" tooltip="Clear the console"/>
    </Panel>
    <ListView id="console-list" class="log" selection-mode="multi"/>
    <Label id="console-empty" class="console-empty" text="No messages yet."/>
</Panel>
