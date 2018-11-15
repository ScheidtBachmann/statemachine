/*
 * generated by Xtext 2.14.0
 */
package de.cau.cs.kieler.kicool.tests

import com.google.inject.Inject
import de.cau.cs.kieler.kicool.System
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Assert
import org.junit.Ignore
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(XtextRunner)
@InjectWith(KiCoolInjectorProvider)
class KiCoolParsingTest {
	@Inject
	ParseHelper<System> parseHelper
	
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
