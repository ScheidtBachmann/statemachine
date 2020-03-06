package de.scheidtbachmann.statemachine.diagrams

import de.cau.cs.kieler.klighd.LightDiagramServices
import de.cau.cs.kieler.klighd.standalone.KlighdStandaloneSetup
import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.sccharts.State
import java.nio.file.Path
import java.util.Map
import java.util.function.Function
import org.eclipse.core.runtime.IStatus
import org.eclipse.core.runtime.MultiStatus
import org.eclipse.core.runtime.Status
import org.eclipse.swt.widgets.Display

import static java.nio.file.StandardOpenOption.*

import static extension java.nio.file.Files.*

class DiagramRenderer implements Function<Map<Object, Object>, IStatus> {
	
	static val PLUGIN_ID = 'de.scheidtbachmann.statemachine.diagrams'
	
	static val PARAM_INPUT = "param-input"
	static val PARAM_FORMAT = "param-format"
	static val PARAM_OUTLET = "param-outlet"
	
	static val RESULT_WRITTEN_FOLDERS = "result-written-folders"
	
	override apply(Map<Object, Object> args) {
		val inputs = switch input: args.get(PARAM_INPUT) {
			Iterable<?>: input
			default: #[input]
		}
		val format = switch format: args.get(PARAM_FORMAT) {
			String: format
			default:
				throw new IllegalArgumentException('Expected a string as format parameter.')
		}
		val outlet = switch outlet: args.get(PARAM_OUTLET) {
			Path: outlet
			default:
				throw new IllegalArgumentException('Expected object of type "java.nio.Path" as output location parameter.')
		}
		
		val pageFolders = newArrayList
		args.put(RESULT_WRITTEN_FOLDERS, pageFolders)
		
		Display.getDefault()
		
		val result = new MultiStatus(PLUGIN_ID, 0, '', null)
		for (input : inputs) {
			if (input instanceof SCCharts) {
				val name = switch head:input.rootStates.head {
					State: head.name
					default: 'chart'
				}
				try {
					if (!outlet.exists())
						outlet.createDirectories()
					pageFolders.add(outlet)
					
					KlighdStandaloneSetup.initialize()
					
					val stream = outlet.resolve(name + '.' + format).newOutputStream(CREATE, WRITE)
					val status = LightDiagramServices.renderOffScreen(input, format, stream) => [
						stream.close()
					]
					
					if (status.severity === IStatus.ERROR)
						return status
					else if (!status.isOK)
						result.add(status)
					
				} catch (Throwable t) {
					return new Status(IStatus.ERROR, PLUGIN_ID, 'Diagram rendering failed for ' + name + ' with the following exception', t)
				}
			}
		}
		
		if (result.children.length === 0)
			return Status.OK_STATUS
		else if (result.children.length === 1)
			return result.children.get(0)
		else
			return result
	}
}
