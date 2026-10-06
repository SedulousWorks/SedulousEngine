<screen mode="overlay">

  <!-- The results of a run (Snowline.as fills it): the rows come in one at a time, then the final
       time, the medal it earned and the score. Jump skips to the end, then rides again. -->
  <Flex direction="vertical" justify="center" align="center">
    <Panel padding="28" style="background: rounded-rect(#10182AE6, radius=16);">
      <Flex direction="vertical" align="center" spacing="8">
        <Label text="Finish" font-size="24" style="text-color: #B8C8E8;"/>

        <!-- The tally rows. -->
        <Flex id="row-ride" direction="horizontal" justify="space-between" align="center" width="380" visibility="hidden">
          <Label text="Ride" font-size="19" style="text-color: #B8C8E8;"/>
          <Label id="value-ride" text="" font-size="19" style="text-color: #FFFFFF;"/>
        </Flex>
        <Flex id="row-gates" direction="horizontal" justify="space-between" align="center" width="380" visibility="hidden">
          <Label text="Gates" font-size="19" style="text-color: #B8C8E8;"/>
          <Label id="value-gates" text="" font-size="19" style="text-color: #FFFFFF;"/>
        </Flex>
        <Flex id="row-gems" direction="horizontal" justify="space-between" align="center" width="380" visibility="hidden">
          <Label text="Gems" font-size="19" style="text-color: #7FDFFF;"/>
          <Label id="value-gems" text="" font-size="19" style="text-color: #FFFFFF;"/>
        </Flex>
        <Flex id="row-tricks" direction="horizontal" justify="space-between" align="center" width="380" visibility="hidden">
          <Label text="Tricks" font-size="19" style="text-color: #FFE38A;"/>
          <Label id="value-tricks" text="" font-size="19" style="text-color: #FFFFFF;"/>
        </Flex>
        <Flex id="row-bonus" direction="horizontal" justify="space-between" align="center" width="380" visibility="hidden">
          <Label text="Time bonus" font-size="19" style="text-color: #B8C8E8;"/>
          <Label id="value-bonus" text="" font-size="19" style="text-color: #FFFFFF;"/>
        </Flex>
        <Panel width="380" height="2" style="background: rounded-rect(#3A4A6A, radius=1);"/>

        <!-- The final time beside the medal it earned: one disc per medal, the earned one shown. -->
        <Flex direction="horizontal" align="center" spacing="18">
          <Panel width="64" height="64">
            <Panel id="medal-none" width="64" height="64" visibility="hidden" style="background: rounded-rect(#00000000, radius=32, border=#4A5A7A, border-width=3);"/>
            <Panel id="medal-bronze" width="64" height="64" visibility="hidden" style="background: rounded-rect(#C27A3E, radius=32, border=#E8A56A, border-width=4);"/>
            <Panel id="medal-silver" width="64" height="64" visibility="hidden" style="background: rounded-rect(#AEB8C6, radius=32, border=#E4EAF2, border-width=4);"/>
            <Panel id="medal-gold" width="64" height="64" visibility="hidden" style="background: rounded-rect(#E2A81E, radius=32, border=#FFE07A, border-width=4);"/>
          </Panel>
          <Flex direction="vertical" align="start" spacing="2">
            <Label id="final-time" text="" font-size="48" style="text-color: #FFFFFF;"/>
            <Label id="final-medal" text="" font-size="18" style="text-color: #E0E8F8;"/>
          </Flex>
        </Flex>

        <Flex id="row-score" direction="horizontal" justify="space-between" align="center" width="380" visibility="hidden">
          <Label text="Score" font-size="22" style="text-color: #B8C8E8;"/>
          <Label id="final-score" text="" font-size="30" style="text-color: #FFFFFF;"/>
        </Flex>
        <Label id="final-best" text="" font-size="18" style="text-color: #FFD966;"/>

        <Spacer spacer-height="6"/>
        <Label id="final-prompt" text="Jump to skip" font-size="17" style="text-color: #8FA3C8;"/>
      </Flex>
    </Panel>
  </Flex>

</screen>
