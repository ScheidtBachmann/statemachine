/*
 * generated by Xtext 2.14.0
 */
package de.scheidtbachmann.statemachine.tests

import com.google.inject.Inject
import de.cau.cs.kieler.sccharts.SCCharts
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Assert
import org.junit.Ignore
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(XtextRunner)
@InjectWith(StateMachineInjectorProvider)
class StateMachineParsingTest {
	
	@Inject
	ParseHelper<SCCharts> parseHelper
	
	@Ignore
	@Test
	def void loadModel() {
		val result = parseHelper.parse('''
			Hello Xtext!
		''')
		Assert.assertNotNull(result)
		val errors = result.eResource.errors
		Assert.assertTrue('''Unexpected errors: «errors.join(", ")»''', errors.isEmpty)
	}
}
