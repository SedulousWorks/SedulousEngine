<!--
  The editor mock's frame (Documentation/Specs/editor-gui.md, 3.6): the menu bar, the dock and the
  status bar, static, for judging the design. The dock's panels are the other files here; the Look
  menu stands in for Preferences' appearance inputs.
-->
<Panel id="frame" class="frame">
    <MenuBar id="menubar">
        <Menu text="File">
            <MenuItem command="mock.new-scene"/>
            <MenuItem command="mock.open"/>
            <MenuSeparator/>
            <MenuItem command="mock.save"/>
            <MenuItem command="mock.save-all"/>
            <MenuSeparator/>
            <MenuItem command="mock.exit"/>
        </Menu>
        <Menu text="Edit">
            <MenuItem command="mock.undo"/>
            <MenuItem command="mock.redo"/>
            <MenuSeparator/>
            <MenuItem command="mock.preferences"/>
        </Menu>
        <Menu text="View">
            <MenuItem command="mock.view-assets"/>
            <MenuItem command="mock.view-console"/>
            <MenuItem command="mock.view-profiler"/>
            <MenuSeparator/>
            <MenuItem command="mock.palette"/>
            <MenuItem command="mock.side-by-side"/>
        </Menu>
        <Menu text="Scene">
            <MenuItem command="mock.play"/>
            <MenuItem command="mock.frame"/>
            <MenuItem command="mock.grid" checkable="true"/>
            <MenuItem command="mock.snap" checkable="true"/>
        </Menu>
        <Menu text="Look">
            <MenuItem command="look.dark" checkable="true"/>
            <MenuItem command="look.light" checkable="true"/>
            <MenuSeparator/>
            <Menu text="Density">
                <MenuItem command="look.compact" checkable="true"/>
                <MenuItem command="look.default" checkable="true"/>
                <MenuItem command="look.comfortable" checkable="true"/>
            </Menu>
            <Menu text="Accent">
                <MenuItem command="look.azure" checkable="true"/>
                <MenuItem command="look.violet" checkable="true"/>
                <MenuItem command="look.teal" checkable="true"/>
                <MenuItem command="look.magenta" checkable="true"/>
            </Menu>
            <MenuSeparator/>
            <MenuItem command="look.motion" checkable="true"/>
        </Menu>
        <Menu text="Help">
            <MenuItem command="mock.toast"/>
            <MenuItem command="mock.dialog"/>
            <MenuItem command="mock.asset-picker"/>
            <MenuItem command="mock.entity-picker"/>
            <MenuSeparator/>
            <MenuItem command="mock.about"/>
        </Menu>
    </MenuBar>
    <Panel id="frame-dock" class="frame-dock"/>
    <StatusBar id="statusbar">
        <StatusItem id="status-message" title="Message"><Label class="message" text="Saved Level 1"/></StatusItem>
        <StatusItem id="status-job" zone="end" title="Jobs"><Label text="Cooking 12 of 40"/></StatusItem>
        <StatusItem id="status-agent" zone="end" title="Agent"><Label text="Agent connected"/></StatusItem>
    </StatusBar>
</Panel>
