/*  * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2013 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.sccharts.ui.synthesis

import com.google.inject.Inject
import de.cau.cs.kieler.klighd.internal.util.SourceModelTrackingAdapter
import de.cau.cs.kieler.klighd.krendering.KText
import de.cau.cs.kieler.klighd.krendering.ViewSynthesisShared
import de.cau.cs.kieler.klighd.krendering.extensions.KNodeExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis
import de.cau.cs.kieler.klighd.util.KlighdProperties
import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.sccharts.extensions.SCChartsCoreExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsSerializeHRExtensions
import de.cau.cs.kieler.sccharts.ui.synthesis.hooks.SynthesisHooks
import java.util.LinkedHashSet
import org.eclipse.xtend.lib.annotations.Accessors
import de.cau.cs.kieler.klighd.krendering.Colors

import static de.cau.cs.kieler.sccharts.ui.synthesis.GeneralSynthesisOptions.*
import de.cau.cs.kieler.sccharts.State
import de.cau.cs.kieler.klighd.kgraph.KNode
import java.util.HashMap
import com.google.common.collect.HashMultimap
import de.cau.cs.kieler.kexpressions.VariableDeclaration
import de.cau.cs.kieler.klighd.krendering.extensions.KEdgeExtensions
import de.cau.cs.kieler.sccharts.ui.synthesis.styles.TransitionStyles
import org.eclipse.elk.core.options.CoreOptions
import org.eclipse.elk.alg.force.options.StressOptions
import de.cau.cs.kieler.annotations.extensions.PragmaExtensions

/**
 * Main diagram synthesis for SCCharts.
 * 
 * @author als
 * @kieler.design 2012-10-08 proposed cmot
 * @kieler.rating 2012-10-08 proposed yellow
 */
@ViewSynthesisShared
class SCChartsSynthesis extends AbstractDiagramSynthesis<SCCharts> {

    @Inject extension KNodeExtensions
    @Inject extension KEdgeExtensions
    @Inject extension KRenderingExtensions
    @Inject extension SCChartsCoreExtensions 
    @Inject extension SCChartsSerializeHRExtensions
    @Inject extension PragmaExtensions
    @Inject extension TransitionStyles
    @Inject StateSynthesis stateSynthesis
    @Inject ControlflowRegionSynthesis controlflowSynthesis    
    @Inject DataflowRegionSynthesis dataflowSynthesis  
    @Inject TransitionSynthesis transitionSynthesis
    @Inject CommentSynthesis commentSynthesis
        
    @Inject SynthesisHooks hooks  

    static val PRAGMA_SYMBOLS = "symbols"       
    static val PRAGMA_SYMBOL = "symbol"       
    static val PRAGMA_SYMBOLS_GREEK = "greek"
    static val PRAGMA_SYMBOLS_SUBSCRIPT = "subscript"       
    static val PRAGMA_SYMBOLS_MATH_SCRIPT = "math script"       
    static val PRAGMA_SYMBOLS_MATH_FRAKTUR = "math fraktur"       
    static val PRAGMA_SYMBOLS_MATH_DOUBLESTRUCK = "math doublestruck"
    static val PRAGMA_FONT = "font"        
    static val PRAGMA_SKINPATH = "skinpath"
          
    val ID = "de.cau.cs.kieler.sccharts.ui.synthesis.SCChartsSynthesis"
    
    @Accessors private var String skinPath = ""
    
    override getDisplayedActions() {
        return newLinkedList => [ list |
            hooks.allHooks.forEach[list.addAll(getDisplayedActions)];
        ]
    }
       
    override getDisplayedSynthesisOptions() {
        val options = new LinkedHashSet()
        
        // Add categories options
        options.addAll(APPEARANCE, NAVIGATION, DATAFLOW, DEBUGGING, LAYOUT)
        
        // General options
        options.addAll(USE_KLAY, SHOW_ALL_SCCHARTS, SHOW_COMMENTS)
        
        // Subsynthesis options
        options.addAll(stateSynthesis.displayedSynthesisOptions)
        options.addAll(transitionSynthesis.displayedSynthesisOptions)
        options.addAll(controlflowSynthesis.displayedSynthesisOptions)
        options.addAll(dataflowSynthesis.displayedSynthesisOptions)
        options.addAll(commentSynthesis.displayedSynthesisOptions)
        
        // Add options of hooks
        hooks.allHooks.forEach[options.addAll(displayedSynthesisOptions)]
        
        return options.toList
    }

    override transform(SCCharts scc) {
        val startTime = System.currentTimeMillis
        
        val rootNode = createNode
                
        // If dot is used draw edges first to prevent overlapping with states when layout is bad
        usedContext.setProperty(KlighdProperties.EDGES_FIRST, !USE_KLAY.booleanValue)
        
        clearSymbols
        for(symbolTable : scc.getStringPragmas(PRAGMA_SYMBOLS)) {  
            var prefix = ""
            if (symbolTable.values.size > 1) prefix = symbolTable.values.get(1)
            if (symbolTable.values.head.equals(PRAGMA_SYMBOLS_GREEK)) { defineGreekSymbols(prefix) }
            if (symbolTable.values.head.equals(PRAGMA_SYMBOLS_SUBSCRIPT)) { defineSubscriptSymbols(prefix) }
            if (symbolTable.values.head.equals(PRAGMA_SYMBOLS_MATH_SCRIPT)) { defineMathScriptSymbols(prefix) }
            if (symbolTable.values.head.equals(PRAGMA_SYMBOLS_MATH_FRAKTUR)) { defineMathFrakturSymbols(prefix) }
            if (symbolTable.values.head.equals(PRAGMA_SYMBOLS_MATH_DOUBLESTRUCK)) { defineMathDoubleStruckSymbols(prefix) }
        }             
        for(symbol : scc.getStringPragmas(PRAGMA_SYMBOL)) {
            symbol.values.head.defineSymbol(symbol.values.get(1))
        }
        if (scc.hasPragma(PRAGMA_SKINPATH)) skinPath = scc.getStringPragmas(PRAGMA_SKINPATH).head.values.head

        if (SHOW_ALL_SCCHARTS.booleanValue) {
            val rootStateNodes = <State, KNode> newHashMap
            for(rootState : scc.rootStates) {
                hooks.invokeStart(rootState, rootNode)
                rootStateNodes.put(rootState, stateSynthesis.transform(rootState).head)
                rootNode.children += rootStateNodes.get(rootState)
                
                // Add tracking adapter to allow access to source model associations
                val trackingAdapter = new SourceModelTrackingAdapter();
                rootNode.setLayoutOption(SCChartsDiagramProperties::MODEL_TRACKER, trackingAdapter);
                // Since the root node will node use to display the diagram (SimpleUpdateStrategy) the tracker must be set on the children.
                rootNode.children.forEach[eAdapters.add(trackingAdapter)]
                
                hooks.invokeFinish(rootState, rootNode)
            }
            rootNode.children.addAll(rootStateNodes.values)
            if (scc.rootStates.size > 1) {
//                rootNode.configureInterChartCommunication(scc, rootStateNodes)
            }
        } else {
            hooks.invokeStart(scc.rootStates.head, rootNode)
            rootNode.children += stateSynthesis.transform(scc.rootStates.head)
            
            // Add tracking adapter to allow access to source model associations
            val trackingAdapter = new SourceModelTrackingAdapter();
            rootNode.setLayoutOption(SCChartsDiagramProperties::MODEL_TRACKER, trackingAdapter);
            // Since the root node will node use to display the diagram (SimpleUpdateStrategy) the tracker must be set on the children.
            rootNode.children.forEach[eAdapters.add(trackingAdapter)]
            
            hooks.invokeFinish(scc.rootStates.head, rootNode) 
        }
        
        val pragmaFont = scc.getStringPragmas(PRAGMA_FONT).last
        if (pragmaFont !== null) {
            rootNode.eAllContents.filter(KText).forEach[ fontName = pragmaFont.values.head ]
        }
        
        // Log elapsed time
        println(
            "SCCharts synthesis transformed model " + (scc.rootStates.head.label ?: scc.hash) + " in " +
                ((System.currentTimeMillis - startTime) as float / 1000) + "s.")
		
        return rootNode
    }
    
    protected def void configureInterChartCommunication(KNode rootNode, SCCharts scc, HashMap<State, KNode> rootStateNodes) {
        // Bugged in the stress version we're working with.
        rootNode.setLayoutOption(CoreOptions::ALGORITHM, "org.eclipse.elk.stress")
        rootNode.setLayoutOption(StressOptions.DESIRED_EDGE_LENGTH, 300d)
        val HashMultimap<String, State> inputMessages = HashMultimap.create
        scc.rootStates.forEach[ rootState | rootState.declarations.filter(VariableDeclaration).filter[ input ].map[ valuedObjects ].flatten.forEach[ vo | inputMessages.put(vo.name, rootState) ] ]
        for (rootState : scc.rootStates) {
            val sourceNode = rootStateNodes.get(rootState)
            for (outputMessage : rootState.declarations.filter(VariableDeclaration).filter[ output ].map[ valuedObjects ].flatten) {
                for (target : inputMessages.get(outputMessage.name)) {
                    val targetNode = rootStateNodes.get(target)
                    
                    val edge = createEdge.associateWith(outputMessage)
                    edge.addPolyline(3) => [ foreground = Colors.DARK_SLATE_BLUE ]
                    edge.addDefaultDecorator
                    edge.source = sourceNode
                    edge.target = targetNode
                }                 
            }
        }
    }
   
}
