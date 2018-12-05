package de.scheidtbachmann.statemachine.diagrams

import com.google.gson.GsonBuilder
import de.cau.cs.kieler.sccharts.ControlflowRegion
import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.sccharts.State
import de.cau.cs.kieler.sccharts.Transition
import java.io.IOException
import java.io.OutputStreamWriter
import java.io.Writer
import java.nio.file.Path
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

import static java.nio.file.StandardOpenOption.*

import static extension java.nio.file.Files.*

class DiagramModelGenerator {
	
	public static val DIAGRAM_MODEL_FILE_NAME = 'diagramModel.js'
	
	def create(EObject chart, Path outlet) {
		if (chart instanceof SCCharts) {
			for (rootState : chart.rootStates) {
				val diagramRoot = outlet.resolve(rootState.name.replace('/','-'.charAt(0)).replace('\\', '-'.charAt(0)))
				if (!diagramRoot.exists())
					diagramRoot.createDirectory()
				
				new OutputStreamWriter(
					diagramRoot.resolve(DIAGRAM_MODEL_FILE_NAME).newOutputStream(CREATE, WRITE)
				).writeDiagramModel(rootState).close()
			}
		}
	}

	def writeDiagramModel(Writer it, State rootState) {
		write('''
			function getDiagramModel() {
			  return '''
		)
		write(
			rootState.toGraph, '  '
		)
		write('''
			;
			}
		'''
		)
		
		return it
	}
	
	def write(Writer writer, View view, String indentation) {
		new GsonBuilder().setPrettyPrinting.create().toJson(
			view, new IndentationAwareWriter(writer, indentation.toCharArray)
		)
	}
	
	def View toGraph(State rootState) {
		new Graph(
			new LayoutOptions[
				HGap = 5
				HAlign = 'left'
				paddingLeft = 7
				paddingRight = 7
				paddingTop = 7
				paddingBottom = 7
			],
			rootState.regions.filter(ControlflowRegion).head?.states.indexed.map[ value.toView(key, 'state-') ]
		)
	}
	
	def View toView(State state, int index, String idPrefix) {
		val id = idPrefix + index.toString
		
		new StateNode(
			id,
			new LayoutOptions[
				resizeContainer = true
				paddingLeft = 10
				paddingRight = 10
				paddingTop = 8
				paddingBottom = 8
			],
			state.toLabelView(0, id)
		)
	}
	
	def View toLabelView(State state, int index, String idPrefix) {
		new StateLabel(
			idPrefix + '-label-' + index.toString,
			state.label?:state.name
		)
	}
	
	def View toView(Transition transition) {
		
	}
}

@Data
class View {
	val String id
	val String type
	val String layout
	val LayoutOptions layoutOptions
	val List<View> children
	
	new(String type, String id, String layout, LayoutOptions layoutOptions, Iterable<View> children) {
		this.type = type
		this.id = id
		this.layout = layout
		this.layoutOptions = layoutOptions
		this.children = if (children !== null && children.iterator.hasNext) children.toList
	}
}

class Graph extends View {
	new(LayoutOptions layoutOptions, Iterable<View> children) {
		super('graph', 'graph', null, layoutOptions, children)
	}
}

class StateNode extends View {
	new(String id, LayoutOptions layoutOptions, View children) {
		this(id, 'vbox', layoutOptions, if (children !== null) newArrayList(children))
	}
	new(String id, LayoutOptions layoutOptions, Iterable<View> children) {
		this(id, 'vbox', layoutOptions, children)
	}
	private new(String id, String layout, LayoutOptions layoutOptions, Iterable<View> children) {
		super('node:state', id, layout, layoutOptions, children)
	}
}

@Data
class StateLabel extends View {
	val String text
	
	new(String id, String labelText) {
		this(id, labelText, null, null)
	}
	private new(String id, String labelText, LayoutOptions layoutOptions, Iterable<View> children) {
		super('label:stateLabel', id, null, layoutOptions, children)
		this.text = labelText
	}
}

@Accessors
class LayoutOptions {
	String hAlign
	Integer hGap
	Integer paddingLeft
	Integer paddingRight
	Integer paddingTop
	Integer paddingBottom
	Integer paddingFactor
	Boolean resizeContainer
	
	new((LayoutOptions)=>void initializer) {
		this => initializer
	}
}

@FinalFieldsConstructor
package class IndentationAwareWriter extends Writer {
	
	val char lf = '\n'
	val Writer delegate
	val char[] indentation
	
	override write(String str) throws IOException {
		var i = str.indexOf(lf)
		if (i === -1) {
			write(str, 0, str.length)
		} else {
			i++
			write(str, 0, i)
			write(indentation, 0, indentation.length)
			if (i !== str.length) {
				super.write(str, i, str.length)
			}
		}
	}
	
	override write(String str, int off, int len) throws IOException {
		delegate.write(str, off, len)
	}
	
	override write(char[] cbuf) throws IOException {
		delegate.write(cbuf)
	}
	
	override write(int c) throws IOException {
		delegate.write(c)
	}
	
	override write(char[] cbuf, int off, int len) throws IOException {
		delegate.write(cbuf, off, len)
	}
	
	override flush() throws IOException {
		delegate.flush()
	}
	
	override close() throws IOException {
		delegate.close()
	}
}
