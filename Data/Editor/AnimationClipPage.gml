<!--
  The animation clip page (Raptor's editor-gui spec, 5.4, layer 10): the preview pages'
  shape. The kit's bar (Save, Undo, Redo, Discard Changes, Cook and Rebuild this asset, each an
  action over the page; its kind at the end) over the preview beside the grid. The preview's bar:
  Frame, the kit's transport (Restart, Play showing Pause while it plays, Stop, each an action over
  the page) and where it is, then the preview's own choices: Travel (the preview walks by the clip's
  root motion; off, it plays in place), and the skeleton and skinned mesh it plays on, kept per
  clip. Under the preview the ruler on the clip's time: a drag scrubs, and the clip's events are its
  markers, one dragged moving its time. The grid has the clip's rows (Looping, its root motion, its
  events) and its facts read only. An asset that did not read says so in place of the grid.
  Code puts the viewport in its stage, the slots after `preview-own`, and fills the rest.
-->
<Panel class="page preview-page clip-page">
    <ToolBar id="page-bar" class="page-toolbar">
        <ToolButton id="page-save" icon="Editor/Icons/save.svg"/>
        <ToolButton id="page-undo" icon="Editor/Icons/undo.svg"/>
        <ToolButton id="page-redo" icon="Editor/Icons/redo.svg"/>
        <ToolButton id="page-discard" icon="Editor/Icons/revert.svg"/>
        <Separator/>
        <ToolButton id="page-cook" icon="Editor/Icons/cook.svg"/>
        <ToolButton id="page-rebuild" icon="Editor/Icons/rebuild.svg"/>
        <Separator id="page-own"/>
        <Spacer/>
        <Label id="page-kind" class="badge page-kind"/>
    </ToolBar>
    <Splitter id="page-body" class="page-body" axis="horizontal" weights="0.62 0.38">
        <Panel class="panel page-pane preview-pane">
            <Panel id="preview-bar" class="panel-toolbar preview-bar">
                <ToolButton id="preview-frame" icon="Editor/Icons/frame-selection.svg" tooltip="Frame it (F)"/>
                <Separator/>
                <ToolButton id="clip-restart" icon="Editor/Icons/restart.svg"/>
                <ToolButton id="clip-play" toggle="true" icon="Editor/Icons/play.svg" checked-icon="Editor/Icons/pause.svg"/>
                <ToolButton id="clip-stop" icon="Editor/Icons/stop.svg"/>
                <Label id="clip-state" class="transport-state clip-time" text=""/>
                <Separator/>
                <ToolButton id="clip-travel" toggle="true" text="Travel" shows-text="true" tooltip="Walk by the clip's root motion (off: it plays in place, as the clip is cooked); this page's alone"/>
                <Separator id="preview-own"/>
                <Spacer/>
            </Panel>
            <Panel id="preview-stage" class="preview-stage"/>
            <Panel id="preview-empty" class="state-box preview-empty">
                <Image class="state-icon" src="Editor/Icons/animation.svg"/>
                <Label id="preview-empty-title" class="state-title" text="No preview"/>
                <Label id="preview-empty-text" class="state-text" text="The preview needs the editor's renderer."/>
            </Panel>
            <TimeRuler id="clip-ruler" class="clip-ruler"/>
        </Panel>
        <Panel class="panel page-pane">
            <Panel id="page-state" class="state-box failed page-state">
                <Image class="state-icon" src="Editor/Icons/warning.svg"/>
                <Label class="state-title" text="This asset did not read"/>
                <Label class="state-text" text="Its source could not be read; the Console says why. It is not saved over while it shows this."/>
            </Panel>
            <PropertyGrid id="page-grid" class="panel-body"/>
        </Panel>
    </Splitter>
</Panel>
