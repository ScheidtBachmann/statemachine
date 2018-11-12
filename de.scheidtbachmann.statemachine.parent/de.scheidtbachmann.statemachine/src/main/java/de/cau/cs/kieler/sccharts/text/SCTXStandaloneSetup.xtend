/*
 * generated by Xtext 2.13.0
 */
package de.cau.cs.kieler.sccharts.text

import com.google.inject.Injector
import de.cau.cs.kieler.sccharts.SCChartsPackage
import org.eclipse.emf.ecore.EPackage

/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class SCTXStandaloneSetup extends SCTXStandaloneSetupGenerated {

	def static void doSetup() {
		new SCTXStandaloneSetup().createInjectorAndDoEMFRegistration()
	}

	override void register(Injector injector) {
		EPackage.Registry.INSTANCE.put(SCChartsPackage.eNS_URI, SCChartsPackage.eINSTANCE)
		super.register(injector)
	}
}
