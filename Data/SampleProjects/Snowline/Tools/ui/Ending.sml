<screen mode="modal" transition="fade">

  <!-- The ending (Snowline.as shows it after a run that wins a better medal on Ridge, the last
       course): the best medal and time on each course, their total and the medals won. Jump goes
       back to the courses. -->
  <Flex direction="vertical" justify="center" align="center" padding="32">
    <Panel padding="32" style="background: rounded-rect(#10182AF0, radius=16);">
      <Flex direction="vertical" align="center" spacing="10">
        <Label text="The mountain is yours" font-size="44" style="text-color: #FFFFFF;"/>
        <Label id="end-headline" text="" font-size="20" style="text-color: #FFE38A;"/>
        <Spacer spacer-height="10"/>
        <Flex direction="horizontal" justify="space-between" align="center" width="420">
          <Flex direction="horizontal" align="center" spacing="12">
            <Panel width="26" height="26">
              <Panel id="end-0-none" width="26" height="26" visibility="hidden" style="background: rounded-rect(#00000000, radius=13, border=#4A5A7A, border-width=2);"/>
              <Panel id="end-0-bronze" width="26" height="26" visibility="hidden" style="background: rounded-rect(#C27A3E, radius=13, border=#E8A56A, border-width=2);"/>
              <Panel id="end-0-silver" width="26" height="26" visibility="hidden" style="background: rounded-rect(#AEB8C6, radius=13, border=#E4EAF2, border-width=2);"/>
              <Panel id="end-0-gold" width="26" height="26" visibility="hidden" style="background: rounded-rect(#E2A81E, radius=13, border=#FFE07A, border-width=2);"/>
            </Panel>
            <Label text="Meadow" font-size="22" style="text-color: #FFFFFF;"/>
          </Flex>
          <Label id="end-0-best" text="" font-size="20" style="text-color: #E0E8F8;"/>
        </Flex>
        <Flex direction="horizontal" justify="space-between" align="center" width="420">
          <Flex direction="horizontal" align="center" spacing="12">
            <Panel width="26" height="26">
              <Panel id="end-1-none" width="26" height="26" visibility="hidden" style="background: rounded-rect(#00000000, radius=13, border=#4A5A7A, border-width=2);"/>
              <Panel id="end-1-bronze" width="26" height="26" visibility="hidden" style="background: rounded-rect(#C27A3E, radius=13, border=#E8A56A, border-width=2);"/>
              <Panel id="end-1-silver" width="26" height="26" visibility="hidden" style="background: rounded-rect(#AEB8C6, radius=13, border=#E4EAF2, border-width=2);"/>
              <Panel id="end-1-gold" width="26" height="26" visibility="hidden" style="background: rounded-rect(#E2A81E, radius=13, border=#FFE07A, border-width=2);"/>
            </Panel>
            <Label text="Forest" font-size="22" style="text-color: #FFFFFF;"/>
          </Flex>
          <Label id="end-1-best" text="" font-size="20" style="text-color: #E0E8F8;"/>
        </Flex>
        <Flex direction="horizontal" justify="space-between" align="center" width="420">
          <Flex direction="horizontal" align="center" spacing="12">
            <Panel width="26" height="26">
              <Panel id="end-2-none" width="26" height="26" visibility="hidden" style="background: rounded-rect(#00000000, radius=13, border=#4A5A7A, border-width=2);"/>
              <Panel id="end-2-bronze" width="26" height="26" visibility="hidden" style="background: rounded-rect(#C27A3E, radius=13, border=#E8A56A, border-width=2);"/>
              <Panel id="end-2-silver" width="26" height="26" visibility="hidden" style="background: rounded-rect(#AEB8C6, radius=13, border=#E4EAF2, border-width=2);"/>
              <Panel id="end-2-gold" width="26" height="26" visibility="hidden" style="background: rounded-rect(#E2A81E, radius=13, border=#FFE07A, border-width=2);"/>
            </Panel>
            <Label text="Ridge" font-size="22" style="text-color: #FFFFFF;"/>
          </Flex>
          <Label id="end-2-best" text="" font-size="20" style="text-color: #E0E8F8;"/>
        </Flex>
        <Panel width="420" height="2" style="background: rounded-rect(#3A4A6A, radius=1);"/>
        <Flex direction="horizontal" justify="space-between" align="center" width="420">
          <Label text="All three" font-size="20" style="text-color: #B8C8E8;"/>
          <Label id="end-total" text="" font-size="20" style="text-color: #FFFFFF;"/>
        </Flex>
        <Flex direction="horizontal" justify="space-between" align="center" width="420">
          <Label text="Medals" font-size="20" style="text-color: #B8C8E8;"/>
          <Label id="end-medals" text="" font-size="20" style="text-color: #FFFFFF;"/>
        </Flex>
        <Spacer spacer-height="14"/>
        <Label id="end-closing" text="Thanks for riding." font-size="18" style="text-color: #B8C8E8;"/>
        <Label text="Jump for the courses" font-size="16" style="text-color: #8FA3C8;"/>
      </Flex>
    </Panel>
  </Flex>

</screen>
