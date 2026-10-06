<screen mode="modal" transition="fade" default-focus="course-0">

  <!-- The title (Snowline.as fills it from the save): a card per course, its picture
       (thumbnails.py) with its name and the best medal and time won on it, or what unlocks it.
       A card is one button holding its picture and labels: one rounded body with the picture
       inset in it, rounded to match; its frame lights when it is focused or hovered; a locked card
       is disabled and dims. Quit, under the cards, ends the game. -->
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel padding="24" style="background: rounded-rect(#10182AE6, radius=16);">
      <Flex direction="vertical" align="center" spacing="6">
        <Label text="Snowline" font-size="72" style="text-color: #FFFFFF;"/>
        <Label text="Down the mountain against the clock" font-size="20" style="text-color: #B8C8E8;"/>
        <Spacer spacer-height="16"/>

        <Flex direction="horizontal" align="start" spacing="24">

          <ContentButton id="course-0" width="320" padding="8" style="background: state-list(normal=rounded-rect(#1C2740, radius=10, border=#5A6E96, border-width=2), hover=rounded-rect(#26345A, radius=10, border=#B8C8E8, border-width=3), pressed=rounded-rect(#304070, radius=10, border=#FFD966, border-width=4), focused=rounded-rect(#1C2740, radius=10, border=#FFD966, border-width=5), disabled=rounded-rect(#0E1424, radius=10, border=#3A4A6A, border-width=2));">
            <Flex direction="vertical" align="start" spacing="4">
              <ImageView source="e07b7d47-d4b6-3641-a840-4836beac6cf9" width="304" height="171" corner-radius="6"/>
              <Spacer spacer-height="4"/>
              <Label text="Meadow" font-size="22" style="text-color: #FFFFFF;"/>
              <Label id="course-0-best" text="" font-size="14" style="text-color: #E0E8F8;"/>
            </Flex>
          </ContentButton>

          <ContentButton id="course-1" width="320" padding="8" style="background: state-list(normal=rounded-rect(#1C2740, radius=10, border=#5A6E96, border-width=2), hover=rounded-rect(#26345A, radius=10, border=#B8C8E8, border-width=3), pressed=rounded-rect(#304070, radius=10, border=#FFD966, border-width=4), focused=rounded-rect(#1C2740, radius=10, border=#FFD966, border-width=5), disabled=rounded-rect(#0E1424, radius=10, border=#3A4A6A, border-width=2));">
            <Flex direction="vertical" align="start" spacing="4">
              <ImageView source="2e1ef716-6c07-7f44-8f32-b76c1284c924" width="304" height="171" corner-radius="6"/>
              <Spacer spacer-height="4"/>
              <Label text="Forest" font-size="22" style="text-color: #FFFFFF;"/>
              <Label id="course-1-best" text="" font-size="14" style="text-color: #E0E8F8;"/>
            </Flex>
          </ContentButton>

          <ContentButton id="course-2" width="320" padding="8" style="background: state-list(normal=rounded-rect(#1C2740, radius=10, border=#5A6E96, border-width=2), hover=rounded-rect(#26345A, radius=10, border=#B8C8E8, border-width=3), pressed=rounded-rect(#304070, radius=10, border=#FFD966, border-width=4), focused=rounded-rect(#1C2740, radius=10, border=#FFD966, border-width=5), disabled=rounded-rect(#0E1424, radius=10, border=#3A4A6A, border-width=2));">
            <Flex direction="vertical" align="start" spacing="4">
              <ImageView source="c7df8ef9-9f04-a240-b3fe-1c31e2bd79ed" width="304" height="171" corner-radius="6"/>
              <Spacer spacer-height="4"/>
              <Label text="Ridge" font-size="22" style="text-color: #FFFFFF;"/>
              <Label id="course-2-best" text="" font-size="14" style="text-color: #E0E8F8;"/>
            </Flex>
          </ContentButton>

        </Flex>

        <Spacer spacer-height="12"/>
        <Button id="quit-btn" text="Quit" width="200" height="40" font-size="20" style="background: state-list(normal=rounded-rect(#1C2740, radius=10, border=#5A6E96, border-width=2), hover=rounded-rect(#26345A, radius=10, border=#B8C8E8, border-width=3), pressed=rounded-rect(#304070, radius=10, border=#FFD966, border-width=4), focused=rounded-rect(#1C2740, radius=10, border=#FFD966, border-width=4)); text-color: #FFFFFF;"/>
        <Spacer spacer-height="8"/>
        <Label text="Arrows or stick to choose, Enter or A to ride. In a run, Escape or Start to pause." font-size="15" style="text-color: #8FA3C8;"/>
      </Flex>
    </Panel>

  </Flex>

</screen>
