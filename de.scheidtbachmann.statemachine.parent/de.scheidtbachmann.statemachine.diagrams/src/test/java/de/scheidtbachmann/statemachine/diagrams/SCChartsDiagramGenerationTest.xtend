// ******************************************************************************
//
// Copyright (c) 2021 by
// Scheidt & Bachmann System Technik GmbH, 24109 Melsdorf
//
// This program and the accompanying materials are made available under the terms of the
// Eclipse Public License v2.0 which accompanies this distribution, and is available at
// https://www.eclipse.org/legal/epl-v20.html
//
// ******************************************************************************
package de.scheidtbachmann.statemachine.diagrams

import de.cau.cs.kieler.klighd.LightDiagramServices
import de.cau.cs.kieler.sccharts.text.SCTXResource
import de.cau.cs.kieler.sccharts.text.SCTXStandaloneSetup
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.nio.charset.StandardCharsets
import org.eclipse.emf.common.util.URI
import org.junit.Test

import static org.junit.Assert.*

import static extension de.scheidtbachmann.statemachine.diagrams.DiagramTests.*

class SCChartsDiagramGenerationTest {

    public static val init = DiagramTests.init

    @Test
    def generationTest01() {
        val sm = '''
            scchart ABRO {
                input signal pure A
                input signal pure B
                input signal pure R
                output signal pure O
            
                initial state ABO {
            
                    initial state WaitAB {
                        region:
            
                        initial state wA
                        go to dA if A
            
                        final state dA
            
                        region:
            
                        initial state wB
                        go to dB if B
            
                        final state dB
                    }
                    join to done do O
            
                    state done
                }
                abort to ABO if R
            }
        '''
        val smInjector = new SCTXStandaloneSetup().createInjectorAndDoEMFRegistration()
        val res = smInjector.getInstance(SCTXResource)
        res.URI = URI.createURI("test://" + System.currentTimeMillis + ".sctx")
        res.load(new ByteArrayInputStream(sm.getBytes(StandardCharsets.UTF_8)), emptyMap)
        val model = res.contents.head

        val stream = new ByteArrayOutputStream
        val result = LightDiagramServices.renderOffScreen(model, 'svg', stream)

        assertNotNull('No diagram generated.', result)
        assertTrue('Diagram generation failed: ' + result.message + result.failureTrace, result.isOK)

        // TODO: wechselberg - Disabled for the moment. Different platforms use slightly 
        // different fonts, leading to single pixel differences depending on platform.
        //CHECKSTYLEOFF LineLength This is template code that can't be arbitrarily formatted
        stream.assertEquals('''
            <?xml version="1.0" standalone="no"?>
            
            <svg 
                 version="1.1"
                 baseProfile="full"
                 xmlns="http://www.w3.org/2000/svg"
                 xmlns:xlink="http://www.w3.org/1999/xlink"
                 xmlns:ev="http://www.w3.org/2001/xml-events"
                 xmlns:klighd="http://de.cau.cs.kieler/klighd"
                 xml:space="preserve"
                 x="0px"
                 y="0px"
                 width="228px"
                 height="397px"
                 viewBox="0 0 228 397"
                 >
            <title></title>
            <desc>...</desc>
            <g stroke-linejoin="miter" stroke-dashoffset="0" stroke-dasharray="none" stroke-width="1" stroke-miterlimit="10" stroke-linecap="square">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 0 0 L 228 0 L 228 396.5350036621094 L 0 396.5350036621094 L 0 0 z"/>
            </g>
            <g transform="matrix(1, 0, 0, 1, 4, 7.052734375)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 8.5 L 0.5 380.9822692871094 C 0.5 385.40054728575575 4.081722001353653 388.9822692871094 8.5 388.9822692871094 L 215.5 388.9822692871094 C 219.91827799864635 388.9822692871094 223.5 385.40054728575575 223.5 380.9822692871094 L 223.5 8.5 C 223.5 4.081722001353653 219.91827799864635 0.5 215.5 0.5 L 8.5 0.5 C 4.081722001353653 0.5 0.5 4.081722001353653 0.5 8.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 3, 6.052734375)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 8.5 L 0.5 380.9822692871094 C 0.5 385.40054728575575 4.081722001353653 388.9822692871094 8.5 388.9822692871094 L 215.5 388.9822692871094 C 219.91827799864635 388.9822692871094 223.5 385.40054728575575 223.5 380.9822692871094 L 223.5 8.5 C 223.5 4.081722001353653 219.91827799864635 0.5 215.5 0.5 L 8.5 0.5 C 4.081722001353653 0.5 0.5 4.081722001353653 0.5 8.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 2, 5.052734375)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 8.5 L 0.5 380.9822692871094 C 0.5 385.40054728575575 4.081722001353653 388.9822692871094 8.5 388.9822692871094 L 215.5 388.9822692871094 C 219.91827799864635 388.9822692871094 223.5 385.40054728575575 223.5 380.9822692871094 L 223.5 8.5 C 223.5 4.081722001353653 219.91827799864635 0.5 215.5 0.5 L 8.5 0.5 C 4.081722001353653 0.5 0.5 4.081722001353653 0.5 8.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 1, 4.052734375)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 8.5 L 0.5 380.9822692871094 C 0.5 385.40054728575575 4.081722001353653 388.9822692871094 8.5 388.9822692871094 L 215.5 388.9822692871094 C 219.91827799864635 388.9822692871094 223.5 385.40054728575575 223.5 380.9822692871094 L 223.5 8.5 C 223.5 4.081722001353653 219.91827799864635 0.5 215.5 0.5 L 8.5 0.5 C 4.081722001353653 0.5 0.5 4.081722001353653 0.5 8.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 0, 3.052734375)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 0.5 8.5 L 0.5 380.9822692871094 C 0.5 385.40054728575575 4.081722001353653 388.9822692871094 8.5 388.9822692871094 L 215.5 388.9822692871094 C 219.91827799864635 388.9822692871094 223.5 385.40054728575575 223.5 380.9822692871094 L 223.5 8.5 C 223.5 4.081722001353653 219.91827799864635 0.5 215.5 0.5 L 8.5 0.5 C 4.081722001353653 0.5 0.5 4.081722001353653 0.5 8.5 z"/>
            </g>
            </g>
            <defs>
              <linearGradient id="gradient-0" gradientUnits="objectBoundingBox" gradientTransform="rotate(90.0)" >
                <stop offset="0" stop-color="#f8f9fd" opacity-stop="1.0" />
                <stop offset="1" stop-color="#cddcf3" opacity-stop="1.0" />
              </linearGradient>
            </defs>
            <g stroke="url(#gradient-0)">
            <g transform="matrix(1, 0, 0, 1, 0, 3.052734375)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="url(#gradient-0)">
              <path d="M 0.5 8.5 L 0.5 380.9822692871094 C 0.5 385.40054728575575 4.081722001353653 388.9822692871094 8.5 388.9822692871094 L 215.5 388.9822692871094 C 219.91827799864635 388.9822692871094 223.5 385.40054728575575 223.5 380.9822692871094 L 223.5 8.5 C 223.5 4.081722001353653 219.91827799864635 0.5 215.5 0.5 L 8.5 0.5 C 4.081722001353653 0.5 0.5 4.081722001353653 0.5 8.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 0, 3.052734375)">
            <g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#bebebe">
              <path d="M 0.5 8.5 L 0.5 380.9822692871094 C 0.5 385.40054728575575 4.081722001353653 388.9822692871094 8.5 388.9822692871094 L 215.5 388.9822692871094 C 219.91827799864635 388.9822692871094 223.5 385.40054728575575 223.5 380.9822692871094 L 223.5 8.5 C 223.5 4.081722001353653 219.91827799864635 0.5 215.5 0.5 L 8.5 0.5 C 4.081722001353653 0.5 0.5 4.081722001353653 0.5 8.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 8, 9.052734375)">
            <clipPath id="clip1">
              <path d="M -8 -9.052734375 L -8 387.4822692871094 L 220 387.4822692871094 L 220 -9.052734375 z"/>
            </clipPath>
            <g clip-path="url(#clip1)">
            <text fill-opacity="1" font-style="normal" font-family="Arial" font-weight="bold" stroke="none" fill="#730041" font-size="10pt" x="0" y="0"><tspan x="0" dy="10">input signal </tspan>
            </text>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 68, 9.052734375)">
            <clipPath id="clip2">
              <path d="M -68 -9.052734375 L -68 387.4822692871094 L 160 387.4822692871094 L 160 -9.052734375 z"/>
            </clipPath>
            <g clip-path="url(#clip2)">
            <text fill-opacity="1" font-style="normal" font-family="Arial" font-weight="normal" stroke="none" fill="#000000" font-size="10pt" x="0" y="0"><tspan x="0" dy="10">A</tspan>
            </text>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 8, 20.5517578125)">
            <clipPath id="clip3">
              <path d="M -8 -20.5517578125 L -8 375.9832458496094 L 220 375.9832458496094 L 220 -20.5517578125 z"/>
            </clipPath>
            <g clip-path="url(#clip3)">
            <text fill-opacity="1" font-style="normal" font-family="Arial" font-weight="bold" stroke="none" fill="#730041" font-size="10pt" x="0" y="0"><tspan x="0" dy="10">input signal </tspan>
            </text>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 68, 20.5517578125)">
            <clipPath id="clip4">
              <path d="M -68 -20.5517578125 L -68 375.9832458496094 L 160 375.9832458496094 L 160 -20.5517578125 z"/>
            </clipPath>
            <g clip-path="url(#clip4)">
            <text fill-opacity="1" font-style="normal" font-family="Arial" font-weight="normal" stroke="none" fill="#000000" font-size="10pt" x="0" y="0"><tspan x="0" dy="10">B</tspan>
            </text>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 8, 32.05078125)">
            <clipPath id="clip5">
              <path d="M -8 -32.05078125 L -8 364.4842224121094 L 220 364.4842224121094 L 220 -32.05078125 z"/>
            </clipPath>
            <g clip-path="url(#clip5)">
            <text fill-opacity="1" font-style="normal" font-family="Arial" font-weight="bold" stroke="none" fill="#730041" font-size="10pt" x="0" y="0"><tspan x="0" dy="10">input signal </tspan>
            </text>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 68, 32.05078125)">
            <clipPath id="clip6">
              <path d="M -68 -32.05078125 L -68 364.4842224121094 L 160 364.4842224121094 L 160 -32.05078125 z"/>
            </clipPath>
            <g clip-path="url(#clip6)">
            <text fill-opacity="1" font-style="normal" font-family="Arial" font-weight="normal" stroke="none" fill="#000000" font-size="10pt" x="0" y="0"><tspan x="0" dy="10">R</tspan>
            </text>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 8, 43.5498046875)">
            <clipPath id="clip7">
              <path d="M -8 -43.5498046875 L -8 352.9851989746094 L 220 352.9851989746094 L 220 -43.5498046875 z"/>
            </clipPath>
            <g clip-path="url(#clip7)">
            <text fill-opacity="1" font-style="normal" font-family="Arial" font-weight="bold" stroke="none" fill="#730041" font-size="10pt" x="0" y="0"><tspan x="0" dy="10">output signal </tspan>
            </text>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 74, 43.5498046875)">
            <clipPath id="clip8">
              <path d="M -74 -43.5498046875 L -74 352.9851989746094 L 154 352.9851989746094 L 154 -43.5498046875 z"/>
            </clipPath>
            <g clip-path="url(#clip8)">
            <text fill-opacity="1" font-style="normal" font-family="Arial" font-weight="normal" stroke="none" fill="#000000" font-size="10pt" x="0" y="0"><tspan x="0" dy="10">O</tspan>
            </text>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 7, 59.048828125)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 0.5 0.5 L 209.5 0.5 L 209.5 326.9822692871094 L 0.5 326.9822692871094 L 0.5 0.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 7, 59.048828125)">
            <g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#bebebe">
              <path d="M 0.5 0.5 L 209.5 0.5 L 209.5 326.9822692871094 L 0.5 326.9822692871094 L 0.5 0.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 21, 118.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 9.5 L 1.5 252.14892578125 C 1.5 256.5672037798964 5.081722001353653 260.14892578125 9.5 260.14892578125 L 180.5 260.14892578125 C 184.91827799864635 260.14892578125 188.5 256.5672037798964 188.5 252.14892578125 L 188.5 9.5 C 188.5 5.081722001353653 184.91827799864635 1.5 180.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 20, 117.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 9.5 L 1.5 252.14892578125 C 1.5 256.5672037798964 5.081722001353653 260.14892578125 9.5 260.14892578125 L 180.5 260.14892578125 C 184.91827799864635 260.14892578125 188.5 256.5672037798964 188.5 252.14892578125 L 188.5 9.5 C 188.5 5.081722001353653 184.91827799864635 1.5 180.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 19, 116.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 9.5 L 1.5 252.14892578125 C 1.5 256.5672037798964 5.081722001353653 260.14892578125 9.5 260.14892578125 L 180.5 260.14892578125 C 184.91827799864635 260.14892578125 188.5 256.5672037798964 188.5 252.14892578125 L 188.5 9.5 C 188.5 5.081722001353653 184.91827799864635 1.5 180.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 18, 115.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 9.5 L 1.5 252.14892578125 C 1.5 256.5672037798964 5.081722001353653 260.14892578125 9.5 260.14892578125 L 180.5 260.14892578125 C 184.91827799864635 260.14892578125 188.5 256.5672037798964 188.5 252.14892578125 L 188.5 9.5 C 188.5 5.081722001353653 184.91827799864635 1.5 180.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 17, 114.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 1.5 9.5 L 1.5 252.14892578125 C 1.5 256.5672037798964 5.081722001353653 260.14892578125 9.5 260.14892578125 L 180.5 260.14892578125 C 184.91827799864635 260.14892578125 188.5 256.5672037798964 188.5 252.14892578125 L 188.5 9.5 C 188.5 5.081722001353653 184.91827799864635 1.5 180.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g stroke="url(#gradient-0)">
            <g transform="matrix(1, 0, 0, 1, 17, 114.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="url(#gradient-0)">
              <path d="M 1.5 9.5 L 1.5 252.14892578125 C 1.5 256.5672037798964 5.081722001353653 260.14892578125 9.5 260.14892578125 L 180.5 260.14892578125 C 184.91827799864635 260.14892578125 188.5 256.5672037798964 188.5 252.14892578125 L 188.5 9.5 C 188.5 5.081722001353653 184.91827799864635 1.5 180.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 17, 114.88216018676758)">
            <g stroke-width="3" stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 1.5 9.5 L 1.5 252.14892578125 C 1.5 256.5672037798964 5.081722001353653 260.14892578125 9.5 260.14892578125 L 180.5 260.14892578125 C 184.91827799864635 260.14892578125 188.5 256.5672037798964 188.5 252.14892578125 L 188.5 9.5 C 188.5 5.081722001353653 184.91827799864635 1.5 180.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 24, 122.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 0.5 0.5 L 175.5 0.5 L 175.5 246.14892578125 L 0.5 246.14892578125 L 0.5 0.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 24, 122.88216018676758)">
            <g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#bebebe">
              <path d="M 0.5 0.5 L 175.5 0.5 L 175.5 246.14892578125 L 0.5 246.14892578125 L 0.5 0.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 38, 136.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 9.5 L 1.5 130.5 C 1.5 134.91827799864635 5.081722001353653 138.5 9.5 138.5 L 146.5 138.5 C 150.91827799864635 138.5 154.5 134.91827799864635 154.5 130.5 L 154.5 9.5 C 154.5 5.081722001353653 150.91827799864635 1.5 146.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 37, 135.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 9.5 L 1.5 130.5 C 1.5 134.91827799864635 5.081722001353653 138.5 9.5 138.5 L 146.5 138.5 C 150.91827799864635 138.5 154.5 134.91827799864635 154.5 130.5 L 154.5 9.5 C 154.5 5.081722001353653 150.91827799864635 1.5 146.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 36, 134.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 9.5 L 1.5 130.5 C 1.5 134.91827799864635 5.081722001353653 138.5 9.5 138.5 L 146.5 138.5 C 150.91827799864635 138.5 154.5 134.91827799864635 154.5 130.5 L 154.5 9.5 C 154.5 5.081722001353653 150.91827799864635 1.5 146.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 35, 133.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 9.5 L 1.5 130.5 C 1.5 134.91827799864635 5.081722001353653 138.5 9.5 138.5 L 146.5 138.5 C 150.91827799864635 138.5 154.5 134.91827799864635 154.5 130.5 L 154.5 9.5 C 154.5 5.081722001353653 150.91827799864635 1.5 146.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 34, 132.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 1.5 9.5 L 1.5 130.5 C 1.5 134.91827799864635 5.081722001353653 138.5 9.5 138.5 L 146.5 138.5 C 150.91827799864635 138.5 154.5 134.91827799864635 154.5 130.5 L 154.5 9.5 C 154.5 5.081722001353653 150.91827799864635 1.5 146.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g stroke="url(#gradient-0)">
            <g transform="matrix(1, 0, 0, 1, 34, 132.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="url(#gradient-0)">
              <path d="M 1.5 9.5 L 1.5 130.5 C 1.5 134.91827799864635 5.081722001353653 138.5 9.5 138.5 L 146.5 138.5 C 150.91827799864635 138.5 154.5 134.91827799864635 154.5 130.5 L 154.5 9.5 C 154.5 5.081722001353653 150.91827799864635 1.5 146.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 34, 132.88216018676758)">
            <g stroke-width="3" stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 1.5 9.5 L 1.5 130.5 C 1.5 134.91827799864635 5.081722001353653 138.5 9.5 138.5 L 146.5 138.5 C 150.91827799864635 138.5 154.5 134.91827799864635 154.5 130.5 L 154.5 9.5 C 154.5 5.081722001353653 150.91827799864635 1.5 146.5 1.5 L 9.5 1.5 C 5.081722001353653 1.5 1.5 5.081722001353653 1.5 9.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 41, 140.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 0.5 0.5 L 141.5 0.5 L 141.5 59.5 L 0.5 59.5 L 0.5 0.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 41, 140.88216018676758)">
            <g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#bebebe">
              <path d="M 0.5 0.5 L 141.5 0.5 L 141.5 59.5 L 0.5 59.5 L 0.5 0.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 55, 157.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 54, 156.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 53, 155.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 52, 154.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 51, 153.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g stroke="url(#gradient-0)">
            <g transform="matrix(1, 0, 0, 1, 51, 153.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="url(#gradient-0)">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 51, 153.88216018676758)">
            <g stroke-width="3" stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 137, 154.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 136, 153.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 135, 152.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 134, 151.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 133, 150.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 133, 150.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 133, 150.88216018676758)">
            <g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g stroke="url(#gradient-0)">
            <g transform="matrix(1, 0, 0, 1, 136, 153.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="url(#gradient-0)">
              <path d="M 0.5 17 L 0.5 17 C 0.5 26.11269837220809 7.88730162779191 33.5 17 33.5 L 17 33.5 C 26.11269837220809 33.5 33.5 26.11269837220809 33.5 17 L 33.5 17 C 33.5 7.88730162779191 26.11269837220809 0.5 17 0.5 L 17 0.5 C 7.88730162779191 0.5 0.5 7.88730162779191 0.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 136, 153.88216018676758)">
            <g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 0.5 17 L 0.5 17 C 0.5 26.11269837220809 7.88730162779191 33.5 17 33.5 L 17 33.5 C 26.11269837220809 33.5 33.5 26.11269837220809 33.5 17 L 33.5 17 C 33.5 7.88730162779191 26.11269837220809 0.5 17 0.5 L 17 0.5 C 7.88730162779191 0.5 0.5 7.88730162779191 0.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 41, 140.88216018676758)">
            <g stroke-width="2" stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 44 30 C 54 30 61 30 68 30 C 75 30 82 30 92 30"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 125, 167.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0 0 L 3.200000047683716 3 L 0 6 L 8 3 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 125, 167.88216018676758)">
            <g stroke-linejoin="round" stroke-width="2" stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 0 0 L 3.200000047683716 3 L 0 6 L 8 3 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 105, 155.23323440551758)">
            <clipPath id="clip9">
              <path d="M -105 -155.23323440551758 L -105 241.3017692565918 L 123 241.3017692565918 L 123 -155.23323440551758 z"/>
            </clipPath>
            <g clip-path="url(#clip9)">
            <text fill-opacity="1" font-style="normal" font-family="Arial" font-weight="bold" stroke="none" fill="#000000" font-size="11pt" x="0" y="0"><tspan x="0" dy="11">A</tspan>
            </text>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 41, 205.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 0.5 0.5 L 141.5 0.5 L 141.5 59.5 L 0.5 59.5 L 0.5 0.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 41, 205.88216018676758)">
            <g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#bebebe">
              <path d="M 0.5 0.5 L 141.5 0.5 L 141.5 59.5 L 0.5 59.5 L 0.5 0.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 55.5, 222.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 54.5, 221.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 53.5, 220.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 52.5, 219.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 51.5, 218.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g stroke="url(#gradient-0)">
            <g transform="matrix(1, 0, 0, 1, 51.5, 218.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="url(#gradient-0)">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 51.5, 218.88216018676758)">
            <g stroke-width="3" stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 1.5 17 L 1.5 17 C 1.5 25.560413622377297 8.439586377622703 32.5 17 32.5 L 17 32.5 C 25.560413622377297 32.5 32.5 25.560413622377297 32.5 17 L 32.5 17 C 32.5 8.439586377622703 25.560413622377297 1.5 17 1.5 L 17 1.5 C 8.439586377622703 1.5 1.5 8.439586377622703 1.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 136.5, 219.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 135.5, 218.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 134.5, 217.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 133.5, 216.88216018676758)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 132.5, 215.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 132.5, 215.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 132.5, 215.88216018676758)">
            <g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 0.5 20 L 0.5 20 C 0.5 30.76955262170047 9.23044737829953 39.5 20 39.5 L 20 39.5 C 30.76955262170047 39.5 39.5 30.76955262170047 39.5 20 L 39.5 20 C 39.5 9.23044737829953 30.76955262170047 0.5 20 0.5 L 20 0.5 C 9.23044737829953 0.5 0.5 9.23044737829953 0.5 20 z"/>
            </g>
            </g>
            <g stroke="url(#gradient-0)">
            <g transform="matrix(1, 0, 0, 1, 135.5, 218.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="url(#gradient-0)">
              <path d="M 0.5 17 L 0.5 17 C 0.5 26.11269837220809 7.88730162779191 33.5 17 33.5 L 17 33.5 C 26.11269837220809 33.5 33.5 26.11269837220809 33.5 17 L 33.5 17 C 33.5 7.88730162779191 26.11269837220809 0.5 17 0.5 L 17 0.5 C 7.88730162779191 0.5 0.5 7.88730162779191 0.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 135.5, 218.88216018676758)">
            <g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 0.5 17 L 0.5 17 C 0.5 26.11269837220809 7.88730162779191 33.5 17 33.5 L 17 33.5 C 26.11269837220809 33.5 33.5 26.11269837220809 33.5 17 L 33.5 17 C 33.5 7.88730162779191 26.11269837220809 0.5 17 0.5 L 17 0.5 C 7.88730162779191 0.5 0.5 7.88730162779191 0.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 41, 205.88216018676758)">
            <g stroke-width="2" stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 44.5 30 C 54.5 30 61.25 30 68 30 C 74.75 30 81.5 30 91.5 30"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 124.5, 232.88216018676758)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0 0 L 3.200000047683716 3 L 0 6 L 8 3 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 124.5, 232.88216018676758)">
            <g stroke-linejoin="round" stroke-width="2" stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 0 0 L 3.200000047683716 3 L 0 6 L 8 3 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 105.5, 220.23323440551758)">
            <clipPath id="clip10">
              <path d="M -105.5 -220.23323440551758 L -105.5 176.3017692565918 L 122.5 176.3017692565918 L 122.5 -220.23323440551758 z"/>
            </clipPath>
            <g clip-path="url(#clip10)">
            <text fill-opacity="1" font-style="normal" font-family="Arial" font-weight="bold" stroke="none" fill="#000000" font-size="11pt" x="0" y="0"><tspan x="0" dy="11">B</tspan>
            </text>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 99, 329.5310859680176)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 17 L 0.5 17 C 0.5 26.11269837220809 7.88730162779191 33.5 17 33.5 L 17 33.5 C 26.11269837220809 33.5 33.5 26.11269837220809 33.5 17 L 33.5 17 C 33.5 7.88730162779191 26.11269837220809 0.5 17 0.5 L 17 0.5 C 7.88730162779191 0.5 0.5 7.88730162779191 0.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 98, 328.5310859680176)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 17 L 0.5 17 C 0.5 26.11269837220809 7.88730162779191 33.5 17 33.5 L 17 33.5 C 26.11269837220809 33.5 33.5 26.11269837220809 33.5 17 L 33.5 17 C 33.5 7.88730162779191 26.11269837220809 0.5 17 0.5 L 17 0.5 C 7.88730162779191 0.5 0.5 7.88730162779191 0.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 97, 327.5310859680176)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 17 L 0.5 17 C 0.5 26.11269837220809 7.88730162779191 33.5 17 33.5 L 17 33.5 C 26.11269837220809 33.5 33.5 26.11269837220809 33.5 17 L 33.5 17 C 33.5 7.88730162779191 26.11269837220809 0.5 17 0.5 L 17 0.5 C 7.88730162779191 0.5 0.5 7.88730162779191 0.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 96, 326.5310859680176)">
            <g fill-opacity="0.09803921729326248" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0.5 17 L 0.5 17 C 0.5 26.11269837220809 7.88730162779191 33.5 17 33.5 L 17 33.5 C 26.11269837220809 33.5 33.5 26.11269837220809 33.5 17 L 33.5 17 C 33.5 7.88730162779191 26.11269837220809 0.5 17 0.5 L 17 0.5 C 7.88730162779191 0.5 0.5 7.88730162779191 0.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 95, 325.5310859680176)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
              <path d="M 0.5 17 L 0.5 17 C 0.5 26.11269837220809 7.88730162779191 33.5 17 33.5 L 17 33.5 C 26.11269837220809 33.5 33.5 26.11269837220809 33.5 17 L 33.5 17 C 33.5 7.88730162779191 26.11269837220809 0.5 17 0.5 L 17 0.5 C 7.88730162779191 0.5 0.5 7.88730162779191 0.5 17 z"/>
            </g>
            </g>
            <g stroke="url(#gradient-0)">
            <g transform="matrix(1, 0, 0, 1, 95, 325.5310859680176)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="url(#gradient-0)">
              <path d="M 0.5 17 L 0.5 17 C 0.5 26.11269837220809 7.88730162779191 33.5 17 33.5 L 17 33.5 C 26.11269837220809 33.5 33.5 26.11269837220809 33.5 17 L 33.5 17 C 33.5 7.88730162779191 26.11269837220809 0.5 17 0.5 L 17 0.5 C 7.88730162779191 0.5 0.5 7.88730162779191 0.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 95, 325.5310859680176)">
            <g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#bebebe">
              <path d="M 0.5 17 L 0.5 17 C 0.5 26.11269837220809 7.88730162779191 33.5 17 33.5 L 17 33.5 C 26.11269837220809 33.5 33.5 26.11269837220809 33.5 17 L 33.5 17 C 33.5 7.88730162779191 26.11269837220809 0.5 17 0.5 L 17 0.5 C 7.88730162779191 0.5 0.5 7.88730162779191 0.5 17 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 24, 122.88216018676758)">
            <g stroke-dasharray="7,3" stroke-width="2" stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 88 150 C 88 160 88 168.1622314453125 88 176.324462890625 C 88 184.4866943359375 88 192.64892578125 88 202.64892578125"/>
            </g>
            </g>
            <g transform="matrix(-0.00000004371139024679, 0.999999999999999, -0.999999999999999, -0.00000004371139024679, 115.00000026226834, 317.53108609915176)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0 0 L 3.200000047683716 3 L 0 6 L 8 3 z"/>
            </g>
            </g>
            <g transform="matrix(-0.00000004371139024679, 0.999999999999999, -0.999999999999999, -0.00000004371139024679, 115.00000026226834, 317.53108609915176)">
            <g stroke-linejoin="round" stroke-width="2" stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 0 0 L 3.200000047683716 3 L 0 6 L 8 3 z"/>
            </g>
            </g>
            <g transform="matrix(-0.00000004371139024679, 0.999999999999999, -0.999999999999999, -0.00000004371139024679, 117.50000024041265, 272.3821604271802)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#00ff00">
              <path d="M 0 0 L 0 11 L 11 5.5 z"/>
            </g>
            </g>
            <g transform="matrix(-0.00000004371139024679, 0.999999999999999, -0.999999999999999, -0.00000004371139024679, 117.50000024041265, 272.3821604271802)">
            <g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 0 0 L 0 11 L 11 5.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 115, 292.8821601867676)">
            <clipPath id="clip11">
              <path d="M -115 -292.8821601867676 L -115 103.6528434753418 L 113 103.6528434753418 L 113 -292.8821601867676 z"/>
            </clipPath>
            <g clip-path="url(#clip11)">
            <text fill-opacity="1" font-style="normal" font-family="Arial" font-weight="bold" stroke="none" fill="#000000" font-size="11pt" x="0" y="0"><tspan x="0" dy="11">/ O</tspan>
            </text>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 7, 59.048828125)">
            <g stroke-width="2" stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 73.33333587646484 55.83333206176758 C 73.33333587646484 40.83333206176758 89.16666412353516 25 105 25 C 120.83333587646484 25 136.6666717529297 40.83333206176758 136.6666717529297 55.83333206176758"/>
            </g>
            </g>
            <g transform="matrix(0.1253041466757638, 0.9921183754098393, -0.9921183754098393, 0.1253041466757638, 145.64059360089846, 106.56930075670468)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#000000">
              <path d="M 0 0 L 3.200000047683716 3 L 0 6 L 8 3 z"/>
            </g>
            </g>
            <g transform="matrix(0.1253041466757638, 0.9921183754098393, -0.9921183754098393, 0.1253041466757638, 145.64059360089846, 106.56930075670468)">
            <g stroke-linejoin="round" stroke-width="2" stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 0 0 L 3.200000047683716 3 L 0 6 L 8 3 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 75.83455796482359, 105.91368737998897)">
            <g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ff0000">
              <path d="M 9.5 5 C 9.5 7.4852813742385695 7.4852813742385695 9.5 5 9.5 C 2.51471862576143 9.5 0.5 7.4852813742385695 0.5 5 C 0.5 2.51471862576143 2.51471862576143 0.5 5 0.5 C 7.4852813742385695 0.5 9.5 2.51471862576143 9.5 5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 75.83455796482359, 105.91368737998897)">
            <g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
              <path d="M 9.5 5 C 9.5 7.4852813742385695 7.4852813742385695 9.5 5 9.5 C 2.51471862576143 9.5 0.5 7.4852813742385695 0.5 5 C 0.5 2.51471862576143 2.51471862576143 0.5 5 0.5 C 7.4852813742385695 0.5 9.5 2.51471862576143 9.5 5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 108.5, 71.39990234375)">
            <clipPath id="clip12">
              <path d="M -108.5 -71.39990234375 L -108.5 325.1351013183594 L 119.5 325.1351013183594 L 119.5 -71.39990234375 z"/>
            </clipPath>
            <g clip-path="url(#clip12)">
            <text fill-opacity="1" font-style="normal" font-family="Arial" font-weight="bold" stroke="none" fill="#000000" font-size="11pt" x="0" y="0"><tspan x="0" dy="11">R</tspan>
            </text>
            </g>
            </g>
            </g>
            </g>
            </g>
            </g>
            </g>
            </g>
            </g>
            </g>
            </g>
            </svg>
        ''')
        //CHECKSTYLEON LineLength
    }

    def assertEquals(ByteArrayOutputStream actual, CharSequence expected) {
        val output = actual.toString
        val descStart = output.indexOf('<desc>')
        val descEnd = output.indexOf('</desc>')
        val masked = output.substring(0, descStart + 6) + '...' + output.substring(descEnd, output.length)

        assertEquals(expected.toString.replaceAll("\r\n", "\n"), masked.replaceAll("\r\n", "\n"))
    }
}
