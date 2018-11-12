/*
 * generated by Xtext 2.13.0
 */
package de.cau.cs.kieler.sccharts.text.ide

import com.google.inject.Guice
import de.cau.cs.kieler.sccharts.text.SCTXRuntimeModule
import de.cau.cs.kieler.sccharts.text.SCTXStandaloneSetup
import org.eclipse.xtext.util.Modules2

/**
 * Initialization support for running Xtext languages as language servers.
 */
class SCTXIdeSetup extends SCTXStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new SCTXRuntimeModule, new SCTXIdeModule))
	}
	
}
