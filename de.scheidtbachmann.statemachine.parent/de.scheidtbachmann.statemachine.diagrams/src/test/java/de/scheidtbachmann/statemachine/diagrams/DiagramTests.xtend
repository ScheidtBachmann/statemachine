package de.scheidtbachmann.statemachine.diagrams

import de.cau.cs.kieler.klighd.Klighd
import de.cau.cs.kieler.klighd.standalone.KlighdStandaloneSetup
import java.io.PrintWriter
import java.io.StringWriter
import org.eclipse.core.runtime.IStatus

class DiagramTests {
	
	public static val init = [| KlighdStandaloneSetup.initialize() null ].apply()
	
	static def getFailureTrace(IStatus status) {
		if (status?.exception === null)
			""
		else {
			val buffer = new StringWriter()
			status.exception.printStackTrace(new PrintWriter(buffer))
			Klighd.LINE_SEPARATOR + buffer.toString
		}
	}
}