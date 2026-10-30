<!--
  Preferences (Documentation/Specs/editor-gui.md, 5.1, layer 12): the user's own settings, a tab per
  category. Appearance previews as it changes; Save keeps it, Cancel (or closing) puts it back.
  The accents' segments, the preview resolutions' rows, the shortcuts' rows and a tab per category
  other parts of the editor contribute are made by code.
-->
<Panel class="preferences">
    <TabView id="pref-tabs" class="pref-tabs">
        <TabPage title="Appearance">
            <Panel class="dialog-body form">
                <Label class="form-label" text="Theme"/>
                <Panel class="form-field">
                    <Panel class="segmented"><Button id="pref-dark" class="segment" name="pref-scheme" toggle="true" text="Dark"/><Button id="pref-light" class="segment" name="pref-scheme" toggle="true" text="Light"/></Panel>
                </Panel>
                <Label class="form-label" text="Accent"/>
                <Panel class="form-field">
                    <Panel id="pref-accents" class="segmented"/>
                    <TextField id="pref-accent" class="pref-accent" placeholder="#rrggbb"/>
                    <Label class="form-help" text="One of these, or any colour white text reads on, as #rrggbb."/>
                </Panel>
                <Label class="form-label" text="Density"/>
                <Panel class="form-field">
                    <Panel class="segmented"><Button id="pref-density-compact" class="segment" name="pref-density" toggle="true" text="Compact"/><Button id="pref-density-default" class="segment" name="pref-density" toggle="true" text="Default"/><Button id="pref-density-comfortable" class="segment" name="pref-density" toggle="true" text="Comfortable"/></Panel>
                </Panel>
                <Label class="form-label" text="Motion"/>
                <Panel class="form-field"><CheckBox id="pref-motion" text="Reduce motion"/></Panel>
                <Label class="form-label" text="UI scale"/>
                <Panel class="form-field">
                    <Panel class="pref-scale"><Slider id="pref-scale" min="0.5" max="2" step="0.05"/><Label id="pref-scale-value" class="pref-scale-value"/></Panel>
                </Panel>
                <Label class="form-label" text="Scene views"/>
                <Panel class="form-field">
                    <CheckBox id="pref-auto-ortho" text="Axis views are orthographic"/>
                    <Label class="form-help" text="Snapping a view to an axis turns it orthographic; orbiting away turns it back."/>
                </Panel>
            </Panel>
        </TabPage>
        <TabPage title="Export">
            <Panel class="dialog-body form">
                <Label class="form-label" text="Templates"/>
                <Panel class="form-field">
                    <TextField id="pref-templates-root"/>
                    <Label class="form-help" text="Where export templates are installed. Empty: $SEDULOUS_TEMPLATES_DIR, else the editor's own folder."/>
                </Panel>
            </Panel>
        </TabPage>
        <TabPage title="Agent access">
            <Panel class="dialog-body form">
                <Label class="form-label" text="MCP"/>
                <Panel class="form-field"><CheckBox id="pref-mcp-enabled" text="Serve the open project to agents"/></Panel>
                <Label class="form-label" text="Port"/>
                <Panel class="form-field"><TextField id="pref-mcp-port" class="pref-port"/></Panel>
                <Label class="form-label" text="Token"/>
                <Panel class="form-field">
                    <TextField id="pref-mcp-token" placeholder="made on first enable"/>
                    <Label class="form-help" text="On 127.0.0.1 only; an agent presents the token, which is also written to the user data folder's mcp-token. Applies to the open project on Save."/>
                </Panel>
            </Panel>
        </TabPage>
        <TabPage title="Game preview">
            <Panel class="dialog-body pref-previews-page">
                <Label class="form-help" text="Sizes the Game tab offers on this machine, after the project's own and its export presets'."/>
                <Panel id="pref-previews" class="pref-previews"/>
                <Button id="pref-preview-add" class="pref-preview-add" text="Add a resolution"/>
            </Panel>
        </TabPage>
        <TabPage title="Shortcuts">
            <Panel class="dialog-body pref-shortcuts-page">
                <Label class="form-help" text="Click a shortcut and press the new keys (Esc cancels, Del clears). One another action holds is refused on Save, naming it."/>
                <Panel id="pref-shortcuts" class="pref-shortcuts"/>
            </Panel>
        </TabPage>
    </TabView>
    <Panel class="dialog-buttons"><Spacer/><Button id="pref-cancel" text="Cancel"/><Button id="pref-save" class="primary" text="Save"/></Panel>
</Panel>
