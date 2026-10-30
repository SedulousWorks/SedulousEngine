<!--
  The Profiler page (X7 of Documentation/Specs/editor-gui.md), a tab in the page area: its bar
  (record, follow the newest, open and save a capture, what it shows, the budget, stop on a
  spike), the frame strip with the counters under it on the same frames, the frames chosen's
  timeline across the full width, and under it the scope table beside the chosen scope's detail.
  Code gives the views their focus and adds a plot per counter.
-->
<Panel class="page profiler-page">
    <ToolBar class="page-toolbar">
        <ToolButton id="profiler-record" toggle="true" text="Record" shows-text="true" icon="Editor/Icons/target.svg"
                    tooltip="Record the editor process: every page, preview and Play-in-editor run in one frame"/>
        <ToolButton id="profiler-live" toggle="true" text="Live" shows-text="true" icon="Editor/Icons/play.svg"
                    tooltip="Show the editor's own recording, following its newest frame"/>
        <Separator/>
        <ToolButton id="profiler-open" icon="Editor/Icons/folder-open.svg"
                    tooltip="Open a capture from &lt;user-data&gt;/profiles (a player's F9 or --profile-capture)"/>
        <ToolButton id="profiler-save" icon="Editor/Icons/save.svg"
                    tooltip="Save the recording to &lt;user-data&gt;/profiles (.aeprofile, and .json for Perfetto)"/>
        <Separator/>
        <Label id="profiler-source" class="profiler-source" text=""/>
        <Spacer/>
        <Label class="profiler-bar-label" text="Budget"/>
        <ComboBox id="profiler-budget" class="profiler-combo" items="30 fps|60 fps|120 fps|None" selected="1"
                  tooltip="The frame's budget: the strip colours each frame against it"/>
        <Separator/>
        <ToolButton id="profiler-spike" toggle="true" text="Stop on spike" shows-text="true" icon="Editor/Icons/warning.svg"
                    tooltip="Stop recording when a frame takes longer than this, that frame chosen"/>
        <ComboBox id="profiler-spike-ms" class="profiler-combo" items="25 ms|33 ms|50 ms|100 ms" selected="2"/>
    </ToolBar>
    <Panel class="profiler-strip-area">
        <Panel class="profiler-strip-bar">
            <Label id="profiler-frame" class="profiler-strong" text=""/>
            <Label id="profiler-frame-times" class="profiler-dim mono" text=""/>
            <Spacer/>
            <Button id="profiler-longest" class="profiler-small" text="Longest" tooltip="Choose the longest frame held"/>
            <Button id="profiler-median" class="profiler-small" text="Median" tooltip="Choose the frame of the median time"/>
        </Panel>
        <FrameStrip id="profiler-strip"/>
        <Panel id="profiler-counters" class="profiler-counters"/>
    </Panel>
    <Splitter class="page-body" axis="vertical" weights="0.58 0.42">
        <ProfileTimeline id="profiler-timeline" class="profiler-timeline"/>
        <Splitter class="profiler-lower" axis="horizontal" weights="0.64 0.36">
            <Panel class="panel profiler-table-pane">
                <Panel class="panel-toolbar">
                    <Label id="profiler-scope-note" class="profiler-dim" text=""/>
                    <Spacer/>
                    <Panel class="search">
                        <Image class="search-icon" src="Editor/Icons/search.svg"/>
                        <TextField id="profiler-filter" class="search-field" placeholder="Filter scopes"/>
                    </Panel>
                </Panel>
                <ScopeTable id="profiler-table" class="profiler-table"/>
            </Panel>
            <Panel class="panel profiler-detail-pane">
                <Panel class="panel-toolbar">
                    <Label class="profiler-strong" text="Scope"/>
                    <Spacer/>
                    <Button id="profiler-zoom-longest" class="profiler-small" text="Zoom to longest"
                            tooltip="The chosen scope's longest call in the frames chosen, on the timeline"/>
                </Panel>
                <ScopeDetail id="profiler-detail" class="profiler-detail"/>
            </Panel>
        </Splitter>
    </Splitter>
</Panel>
