package de.scheidtbachmann.statemachine.diagrams

import de.cau.cs.kieler.klighd.LightDiagramServices
import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.sccharts.State
import java.nio.file.Path
import java.util.Map
import java.util.function.Function
import org.eclipse.core.runtime.IStatus
import org.eclipse.core.runtime.Status
import org.eclipse.swt.widgets.Display

import static java.nio.file.StandardOpenOption.*

import static extension java.nio.file.Files.*

class DiagramRenderer implements Function<Map<Object, Object>, IStatus> {
	
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
					
					outlet.resolve(name + '.' + format).newOutputStream(CREATE, WRITE) => [
						LightDiagramServices.renderOffScreen(input, format, it)
						close()
					]
				} catch (Throwable t) {
					return new Status(IStatus.ERROR, '', 'Diagram rendering failed for ' + name + ' with the following exception', t)
				}
			}
		}
		return Status.OK_STATUS
	}
}
