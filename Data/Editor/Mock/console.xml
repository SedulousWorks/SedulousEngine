<!-- The console: level filters, a search, and the log. -->
<Panel class="panel">
    <Panel class="panel-toolbar">
        <Button class="chip checked" text="Info  128"/>
        <Button class="chip checked warning" text="Warnings  3"/>
        <Button class="chip checked error" text="Errors  1"/>
        <Spacer/>
        <Panel class="search">
            <Image class="search-icon" src="Editor/Icons/search.svg"/>
            <TextField class="search-field" placeholder="Search the log"/>
        </Panel>
        <Button class="icon-button" icon="Editor/Icons/trash.svg" tooltip="Clear the console"/>
    </Panel>
    <ListView class="log" row-height="22"
              items="Opened Level 1|Cooked 40 assets in 2.1 s|Shader cache warmed: 212 pipelines|Agent connected on 127.0.0.1:7405|Saved Level 1|Texture Brick has no mipmaps: generated 9 levels|Script Player.as compiled">
        <template>
            <Panel class="log-row">
                <Label class="log-time mono" text="12:04:{{index}}"/>
                <Label class="log-text" text="{{item}}"/>
            </Panel>
        </template>
    </ListView>
</Panel>
