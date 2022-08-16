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
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import javax.xml.parsers.DocumentBuilderFactory

import static de.cau.cs.kieler.klighd.kgraph.util.KGraphUtil.*

import static extension de.scheidtbachmann.statemachine.diagrams.DiagramTests.*
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Disabled
import org.junit.jupiter.api.Assertions

class DiagramGenerationTest {

    public static val init = DiagramTests.init

    @Disabled('Generated SVG is platform dependant')
    @Test
    def generationTest01() {
        val root = createInitializedNode

        val stream = new ByteArrayOutputStream
        val result = LightDiagramServices.renderOffScreen(root, 'svg', stream)

        Assertions.assertNotNull(result, 'No diagram generated.')
        Assertions.assertTrue(result.isOK, 'Diagram generation failed: ' + result.message + result.failureTrace)

        //CHECKSTYLEOFF LineLength This is template code that can't be arbitrarily formatted
        stream.assertXMLEquals('''
            <?xml version="1.0" standalone="no"?>
            
            <svg 
                 version="1.1"
                 baseProfile="full"
                 xmlns="http://www.w3.org/2000/svg"
                 xmlns:xlink="http://www.w3.org/1999/xlink"
                 xmlns:ev="http://www.w3.org/2001/xml-events"
                 xmlns:klighd="http://de.cau.cs.kieler/klighd"
                 x="0px"
                 y="0px"
                 width="163px"
                 height="45px"
                 viewBox="0 0 163 45"
                 >
            <title></title>
            <desc>...</desc>
            <g stroke-dashoffset="0" stroke-linejoin="miter" stroke-dasharray="none" stroke-width="1" stroke-linecap="butt" stroke-miterlimit="10">
            <g fill="#ffffff" fill-rule="nonzero" fill-opacity="1" stroke="none">
              <path d="M 0 0 L 163 0 L 163 44.9560546875 L 0 44.9560546875 L 0 0 z"/>
            </g>
            <g transform="matrix(1, 0, 0, 1, 0, 1.9580078125)">
            <g fill="#f2f2f2" fill-rule="nonzero" fill-opacity="1" stroke="none">
              <path d="M 0.5 8.5 L 0.5 34.498046875 C 0.5 38.916324873646346 4.081722001353653 42.498046875 8.5 42.498046875 L 42.5 42.498046875 C 46.918277998646346 42.498046875 50.5 38.916324873646346 50.5 34.498046875 L 50.5 8.5 C 50.5 4.081722001353653 46.918277998646346 0.5 42.5 0.5 L 8.5 0.5 C 4.081722001353653 0.5 0.5 4.081722001353653 0.5 8.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 0, 1.9580078125)">
            <g stroke-opacity="1" fill="none" stroke="#bebebe">
              <path d="M 0.5 8.5 L 0.5 34.498046875 C 0.5 38.916324873646346 4.081722001353653 42.498046875 8.5 42.498046875 L 42.5 42.498046875 C 46.918277998646346 42.498046875 50.5 38.916324873646346 50.5 34.498046875 L 50.5 8.5 C 50.5 4.081722001353653 46.918277998646346 0.5 42.5 0.5 L 8.5 0.5 C 4.081722001353653 0.5 0.5 4.081722001353653 0.5 8.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 8, 9.9580078125)">
              <text x="0" y="11.0" font-weight="bold" font-size="11pt" font-family="Arial" style="white-space: pre" font-style="normal" fill="#000000" fill-opacity="1" stroke="none">KNode</text>
            </g>
            <g transform="matrix(1, 0, 0, 1, 8, 26.60693359375)">
              <text x="0" y="9.0" font-weight="normal" font-size="9pt" font-family="Arial" style="white-space: pre" font-style="normal" fill="#0000ff" fill-opacity="1" stroke="none">[Details]</text>
            </g>
            <g transform="matrix(1, 0, 0, 1, 51, 19.95703125)">
            <g fill="#000000" fill-rule="nonzero" fill-opacity="1" stroke="none">
              <path d="M 0.5 0.5 L 6.5 0.5 L 6.5 6.5 L 0.5 6.5 L 0.5 0.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 51, 19.95703125)">
            <g stroke-opacity="1" fill="none" stroke="#000000">
              <path d="M 0.5 0.5 L 6.5 0.5 L 6.5 6.5 L 0.5 6.5 L 0.5 0.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 59, 27.95703125)">
              <text x="0" y="10.0" font-weight="normal" font-size="10pt" font-family="Arial" style="white-space: pre" font-style="normal" fill="#000000" fill-opacity="1" stroke="none">insets</text>
            </g>
            <g transform="matrix(1, 0, 0, 1, 105, 1.9580078125)">
            <g fill="#f2f2f2" fill-rule="nonzero" fill-opacity="1" stroke="none">
              <path d="M 0.5 8.5 L 0.5 34.498046875 C 0.5 38.916324873646346 4.081722001353653 42.498046875 8.5 42.498046875 L 49.5 42.498046875 C 53.918277998646346 42.498046875 57.5 38.916324873646346 57.5 34.498046875 L 57.5 8.5 C 57.5 4.081722001353653 53.918277998646346 0.5 49.5 0.5 L 8.5 0.5 C 4.081722001353653 0.5 0.5 4.081722001353653 0.5 8.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 105, 1.9580078125)">
            <g stroke-opacity="1" fill="none" stroke="#bebebe">
              <path d="M 0.5 8.5 L 0.5 34.498046875 C 0.5 38.916324873646346 4.081722001353653 42.498046875 8.5 42.498046875 L 49.5 42.498046875 C 53.918277998646346 42.498046875 57.5 38.916324873646346 57.5 34.498046875 L 57.5 8.5 C 57.5 4.081722001353653 53.918277998646346 0.5 49.5 0.5 L 8.5 0.5 C 4.081722001353653 0.5 0.5 4.081722001353653 0.5 8.5 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 113, 9.9580078125)">
              <text x="0" y="11.0" font-weight="bold" font-size="11pt" font-family="Arial" style="white-space: pre" font-style="normal" fill="#000000" fill-opacity="1" stroke="none">KInsets</text>
            </g>
            <g transform="matrix(1, 0, 0, 1, 116.5, 26.60693359375)">
              <text x="0" y="9.0" font-weight="normal" font-size="9pt" font-family="Arial" style="white-space: pre" font-style="normal" fill="#0000ff" fill-opacity="1" stroke="none">[Details]</text>
            </g>
            <g transform="matrix(1, 0, 0, 1, -12, -10.0419921875)">
            <g stroke-opacity="1" fill="none" stroke="#000000">
              <path d="M 70 33.4990234375 L 117 33.4990234375"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 97, 20.45703125)">
            <g fill="#000000" fill-rule="nonzero" fill-opacity="1" stroke="none">
              <path d="M 0 0 L 3.200000047683716 3 L 0 6 L 8 3 z"/>
            </g>
            </g>
            <g transform="matrix(1, 0, 0, 1, 97, 20.45703125)">
            <g stroke-opacity="1" stroke-linejoin="round" fill="none" stroke="#000000">
              <path d="M 0 0 L 3.200000047683716 3 L 0 6 L 8 3 z"/>
            </g>
            </g>
            </g>
            </svg>
        ''')
        //CHECKSTYLEON LineLength        
    }

    def void assertXMLEquals(ByteArrayOutputStream actual, CharSequence expected) {
        val output = actual.toString
        val descStart = output.indexOf('<desc>')
        val descEnd = output.indexOf('</desc>')
        val masked = output.substring(0, descStart + 6) + '...' + output.substring(descEnd, output.length)

        val dbf = DocumentBuilderFactory.newInstance();
        val db = dbf.newDocumentBuilder();

        val doc1 = db.parse(new ByteArrayInputStream(masked.getBytes("UTF-8")))
        val doc2 = db.parse(new ByteArrayInputStream(expected.toString.getBytes("UTF-8")))

        Assertions.assertTrue(doc1.isEqualNode(doc2));
    }
}
