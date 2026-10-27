<!--
  Preferences (Documentation/Specs/editor-gui.md, 5.1, layer 12): the user's own settings, a tab per
  category. Appearance previews as it changes; Save keeps it, Cancel (or closing) puts it back.
  The accents' segments are made by code from the editor's list.
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
            </Panel>
        </TabPage>
    </TabView>
    <Panel class="dialog-buttons"><Spacer/><Button id="pref-cancel" class="ghost" text="Cancel"/><Button id="pref-save" class="primary" text="Save"/></Panel>
</Panel>
