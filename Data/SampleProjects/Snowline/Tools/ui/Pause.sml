<screen mode="modal" transition="fade" default-focus="resume-btn">

  <!-- The pause menu (Snowline.as): the run holds still under it. Escape, Start or B resumes. -->
  <Flex direction="vertical" justify="center" align="center" padding="32">
    <Panel padding="22" style="background: rounded-rect(#10182AE6, radius=16);">
      <Flex direction="vertical" align="center" spacing="10">
        <Label text="Paused" font-size="40" style="text-color: #FFFFFF;"/>
        <Spacer spacer-height="4"/>
        <Flex direction="vertical" spacing="8" width="300">
          <Button id="resume-btn" text="Resume" height="44" font-size="22" style="background: state-list(normal=rounded-rect(#1C2740, radius=10, border=#5A6E96, border-width=2), hover=rounded-rect(#26345A, radius=10, border=#B8C8E8, border-width=3), pressed=rounded-rect(#304070, radius=10, border=#FFD966, border-width=4), focused=rounded-rect(#1C2740, radius=10, border=#FFD966, border-width=4)); text-color: #FFFFFF;"/>
          <Button id="restart-btn" text="Restart run" height="44" font-size="22" style="background: state-list(normal=rounded-rect(#1C2740, radius=10, border=#5A6E96, border-width=2), hover=rounded-rect(#26345A, radius=10, border=#B8C8E8, border-width=3), pressed=rounded-rect(#304070, radius=10, border=#FFD966, border-width=4), focused=rounded-rect(#1C2740, radius=10, border=#FFD966, border-width=4)); text-color: #FFFFFF;"/>
          <Button id="courses-btn" text="Courses" height="44" font-size="22" style="background: state-list(normal=rounded-rect(#1C2740, radius=10, border=#5A6E96, border-width=2), hover=rounded-rect(#26345A, radius=10, border=#B8C8E8, border-width=3), pressed=rounded-rect(#304070, radius=10, border=#FFD966, border-width=4), focused=rounded-rect(#1C2740, radius=10, border=#FFD966, border-width=4)); text-color: #FFFFFF;"/>
        </Flex>
        <Spacer spacer-height="6"/>
        <!-- The controls, keyboard and pad. -->
        <Flex direction="vertical" align="center" spacing="4">
          <Flex direction="horizontal" align="center" width="480">
            <Label text="" width="240"/>
            <Label text="Keyboard" width="120" font-size="13" style="text-color: #8FA3C8;"/>
            <Label text="Gamepad" width="120" font-size="13" style="text-color: #8FA3C8;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="480">
            <Label text="Carve, and spin in the air" width="240" font-size="15" style="text-color: #B8C8E8;"/>
            <Label text="A / D" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="Left stick" width="120" font-size="16" style="text-color: #FFE38A;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="480">
            <Label text="Jump" width="240" font-size="15" style="text-color: #B8C8E8;"/>
            <Label text="Space" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="A" width="120" font-size="16" style="text-color: #FFE38A;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="480">
            <Label text="Tuck" width="240" font-size="15" style="text-color: #B8C8E8;"/>
            <Label text="Left Shift" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="X or RB" width="120" font-size="16" style="text-color: #FFE38A;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="480">
            <Label text="Grab, in the air" width="240" font-size="15" style="text-color: #B8C8E8;"/>
            <Label text="E" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="B" width="120" font-size="16" style="text-color: #FFE38A;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="480">
            <Label text="Pause" width="240" font-size="15" style="text-color: #B8C8E8;"/>
            <Label text="Escape" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="Start" width="120" font-size="16" style="text-color: #FFE38A;"/>
          </Flex>
        </Flex>
        <Spacer spacer-height="8"/>
        <Label text="Escape, Start or B to ride on" font-size="15" style="text-color: #8FA3C8;"/>
      </Flex>
    </Panel>
  </Flex>

</screen>
