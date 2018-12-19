package de.scheidtbachmann.statemachine.diagrams

import de.cau.cs.kieler.klighd.LightDiagramServices
import de.cau.cs.kieler.sccharts.text.SCTXResource
import de.scheidtbachmann.statemachine.StateMachineStandaloneSetup
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.nio.charset.StandardCharsets
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.resource.XtextResource
import org.junit.Test

import static org.junit.Assert.*

class SCChartsDiagramGenerationTest {
	
	
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
	    val smInjector = new StateMachineStandaloneSetup().createInjectorAndDoEMFRegistration()
	    val res = smInjector.getInstance(SCTXResource)
	    res.URI = URI.createURI("test://" + System.currentTimeMillis + ".sctx")
	    res.load(new ByteArrayInputStream(sm.getBytes(StandardCharsets.UTF_8)), emptyMap)
		val model = res.contents.head
		
		val stream = new ByteArrayOutputStream
		val result = LightDiagramServices.renderOffScreen(model, 'svg', stream)
		
		assertNotNull('No diagram generated.', result)
		assertTrue('Diagram generation failed: ' + result.message, result.isOK)
		
		stream.assertEquals('''
		  UNKOWN
		''')
	}
	
	def assertEquals(ByteArrayOutputStream actual, CharSequence expected) {
		val output = actual.toString
		val descStart = output.indexOf('<desc>')
		val descEnd = output.indexOf('</desc>')
		val masked = output.substring(0, descStart + 6) + '...' + output.substring(descEnd, output.length)
		
		assertEquals(expected.toString.replaceAll("\r\n", "\n"), masked.replaceAll("\r\n", "\n"))
	}
}