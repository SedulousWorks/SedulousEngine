<screen mode="modal" transition="fade" default-focus="resume-btn">

  <!-- The pause menu over a level that holds still (Lamplight.as). -->
  <Flex direction="vertical" justify="center" align="center">
    <Panel padding="24" style="background: rounded-rect(#0C0907E8, radius=16);">
      <Flex direction="vertical" align="stretch" spacing="10" width="580">
        <Label text="Paused" font-size="36" style="text-color: #F0D8A8;"/>
        <Button id="resume-btn" text="Resume" height="44" font-size="22" style="background: state-list(normal=rounded-rect(#1E1610, radius=10, border=#6A5030, border-width=2), hover=rounded-rect(#2C2016, radius=10, border=#D8B070, border-width=3), pressed=rounded-rect(#3A2A1A, radius=10, border=#F0C070, border-width=4), focused=rounded-rect(#1E1610, radius=10, border=#F0C070, border-width=4), disabled=rounded-rect(#100C08, radius=10, border=#3A2C1E, border-width=2)); text-color: #F0E0C0;"/>
        <Button id="restart-btn" text="Start the level over" height="44" font-size="22" style="background: state-list(normal=rounded-rect(#1E1610, radius=10, border=#6A5030, border-width=2), hover=rounded-rect(#2C2016, radius=10, border=#D8B070, border-width=3), pressed=rounded-rect(#3A2A1A, radius=10, border=#F0C070, border-width=4), focused=rounded-rect(#1E1610, radius=10, border=#F0C070, border-width=4), disabled=rounded-rect(#100C08, radius=10, border=#3A2C1E, border-width=2)); text-color: #F0E0C0;"/>
        <Button id="title-btn" text="Leave to the title" height="44" font-size="22" style="background: state-list(normal=rounded-rect(#1E1610, radius=10, border=#6A5030, border-width=2), hover=rounded-rect(#2C2016, radius=10, border=#D8B070, border-width=3), pressed=rounded-rect(#3A2A1A, radius=10, border=#F0C070, border-width=4), focused=rounded-rect(#1E1610, radius=10, border=#F0C070, border-width=4), disabled=rounded-rect(#100C08, radius=10, border=#3A2C1E, border-width=2)); text-color: #F0E0C0;"/>
        <Spacer spacer-height="6"/>
        <!-- The controls, keyboard and pad. -->
        <Flex direction="vertical" align="center" spacing="4">
          <Flex direction="horizontal" align="center" width="560">
            <Label text="" width="300"/>
            <Label text="Keyboard" width="120" font-size="13" style="text-color: #A89878;"/>
            <Label text="Gamepad" width="140" font-size="13" style="text-color: #A89878;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Move" width="300" font-size="15" style="text-color: #D8C8A8;"/>
            <Label text="W A S D" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="Left stick" width="140" font-size="16" style="text-color: #F0C070;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Sneak: slow and silent" width="300" font-size="15" style="text-color: #D8C8A8;"/>
            <Label text="C" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="B" width="140" font-size="16" style="text-color: #F0C070;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Run: fast and loud" width="300" font-size="15" style="text-color: #D8C8A8;"/>
            <Label text="Left Shift" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="Left stick press" width="140" font-size="16" style="text-color: #F0C070;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Use: open, put out, hold to pick a lock" width="300" font-size="15" style="text-color: #D8C8A8;"/>
            <Label text="F" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="A" width="140" font-size="16" style="text-color: #F0C070;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Throw a pebble" width="300" font-size="15" style="text-color: #D8C8A8;"/>
            <Label text="G" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="X" width="140" font-size="16" style="text-color: #F0C070;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Turn the view" width="300" font-size="15" style="text-color: #D8C8A8;"/>
            <Label text="Q / E" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="LB / RB" width="140" font-size="16" style="text-color: #F0C070;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Pause" width="300" font-size="15" style="text-color: #D8C8A8;"/>
            <Label text="Escape" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="Start" width="140" font-size="16" style="text-color: #F0C070;"/>
          </Flex>
        </Flex>
      </Flex>
    </Panel>
  </Flex>

</screen>
