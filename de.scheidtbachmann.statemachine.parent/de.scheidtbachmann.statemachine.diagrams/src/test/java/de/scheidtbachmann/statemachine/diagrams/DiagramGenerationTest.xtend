package de.scheidtbachmann.statemachine.diagrams

import de.cau.cs.kieler.klighd.LightDiagramServices
import java.io.ByteArrayOutputStream
import org.junit.Test

import static de.cau.cs.kieler.klighd.kgraph.util.KGraphUtil.*
import static org.junit.Assert.*

class DiagramGenerationTest {
	
	@Test
	def generationTest01() {
		val root = createInitializedNode
		root.children += createInitializedNode => [
			setSize(100, 50)
		]
		root.children += createInitializedNode => [
			setSize(50, 100)
			outgoingEdges += createInitializedEdge => [
				target = root.children.head
			]
		]
		
		val stream = new ByteArrayOutputStream
		val result = LightDiagramServices.renderOffScreen(root, 'svg', stream)
		
		assertNotNull('No diagram generated.', result)
		assertTrue('Diagram generation failed: ' + result.message, result.isOK)
		
		// FIXME als: ordering of xml attributes may differ
//		stream.assertEquals('''
//		<?xml version="1.0" standalone="no"?>
//		
//		<svg 
//		     version="1.1"
//		     baseProfile="full"
//		     xmlns="http://www.w3.org/2000/svg"
//		     xmlns:xlink="http://www.w3.org/1999/xlink"
//		     xmlns:ev="http://www.w3.org/2001/xml-events"
//		     xmlns:klighd="http://de.cau.cs.kieler/klighd"
//		     xml:space="preserve"
//		     x="0px"
//		     y="0px"
//		     width="170px"
//		     height="100px"
//		     viewBox="0 0 170 100"
//		     >
//		<title></title>
//		<desc>...</desc>
//		<g stroke-linejoin="miter" stroke-dashoffset="0" stroke-dasharray="none" stroke-width="1" stroke-miterlimit="10" stroke-linecap="square">
//		<g fill-opacity="1" fill-rule="nonzero" stroke="none" fill="#ffffff">
//		  <path d="M 0 0 L 170 0 L 170 100 L 0 100 L 0 0 z"/>
//		</g>
//		<g transform="matrix(1, 0, 0, 1, 70, 25)">
//		<g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
//		  <path d="M 0.5 0.5 L 99.5 0.5 L 99.5 49.5 L 0.5 49.5 L 0.5 0.5 z"/>
//		</g>
//		</g>
//		<g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
//		  <path d="M 0.5 0.5 L 49.5 0.5 L 49.5 99.5 L 0.5 99.5 L 0.5 0.5 z"/>
//		</g>
//		<g transform="matrix(1, 0, 0, 1, -12, -12)">
//		<g stroke-linecap="butt" fill="none" stroke-opacity="1" stroke="#000000">
//		  <path d="M 62 62 L 82 62"/>
//		</g>
//		</g>
//		</g>
//		</svg>
//		''')
	}
	
	def assertEquals(ByteArrayOutputStream actual, CharSequence expected) {
		val output = actual.toString
		val descStart = output.indexOf('<desc>')
		val descEnd = output.indexOf('</desc>')
		val masked = output.substring(0, descStart + 6) + '...' + output.substring(descEnd, output.length)
		
		assertEquals(expected.toString.replaceAll("\r\n", "\n"), masked.replaceAll("\r\n", "\n"))
	}
}