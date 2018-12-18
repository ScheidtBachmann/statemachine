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
package de.cau.cs.kieler.sccharts.ui.synthesis.srtg

import com.google.inject.Inject
import de.cau.cs.kieler.klighd.internal.util.SourceModelTrackingAdapter
import de.cau.cs.kieler.klighd.kgraph.KNode
import de.cau.cs.kieler.klighd.krendering.ViewSynthesisShared
import de.cau.cs.kieler.klighd.krendering.extensions.KNodeExtensions
import de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis
import de.cau.cs.kieler.klighd.util.KlighdProperties
import de.cau.cs.kieler.sccharts.Scope
import de.cau.cs.kieler.sccharts.State
import de.cau.cs.kieler.sccharts.ui.synthesis.SCChartsDiagramProperties
import java.util.LinkedHashSet
import org.eclipse.elk.alg.layered.options.FixedAlignment
import org.eclipse.elk.alg.layered.options.LayeredOptions
import org.eclipse.elk.core.options.CoreOptions
import org.eclipse.elk.core.options.Direction
import org.eclipse.elk.core.options.EdgeRouting

import static de.cau.cs.kieler.sccharts.ui.synthesis.GeneralSynthesisOptions.*

/**
 * Main diagram synthesis for SCCharts.
 * 
 * @author ssm
 * @kieler.design 2017-01-18 proposed 
 * @kieler.rating 2017-01-18 proposed 
 */
@ViewSynthesisShared
class SRTGSynthesis extends AbstractDiagramSynthesis<Scope> {

    @Inject 
    extension KNodeExtensions
    
    // -------------------------------------------------------------------------
    // SubSyntheses
    @Inject
    SRTGStateSynthesis stateSynthesis
    
    @Inject
    SRTGControlflowRegionSynthesis controlflowSynthesis    
    
    @Inject
    SRTGTransitionSynthesis transitionSynthesis
        
    // -------------------------------------------------------------------------
    // Fields
    public val ID = "de.cau.cs.kieler.sccharts.ui.srtg.synthesis.SRTGSynthesis"
       
    // -------------------------------------------------------------------------
    // Sidebar Options

    override getDisplayedSynthesisOptions() {
        val options = new LinkedHashSet();
        
        // Add general options
        options.addAll(USE_KLAY);//USE_ADAPTIVEZOOM
        
        // Add options of subsyntheses
        options.addAll(stateSynthesis.displayedSynthesisOptions);
        options.addAll(transitionSynthesis.displayedSynthesisOptions);
        options.addAll(controlflowSynthesis.displayedSynthesisOptions);
        
        // Add categories options
        options.addAll(APPEARANCE, DEBUGGING)
        
        return options.toList;
    }
    
    public static KNode myRootNode 

    // -------------------------------------------------------------------------
    // The main entry transform function   
    override transform(Scope root) {
        val startTime = System.currentTimeMillis;
        
        val rootNode = createNode();
        myRootNode = rootNode
        
        rootNode.setLayoutOption(CoreOptions.ALGORITHM, "org.eclipse.elk.layered")
//        rootNode.setLayoutOption(LayeredOptions.NODE_PLACEMENT_STRATEGY, NodePlacementStrategy.NETWORK_SIMPLEX)
        rootNode.setLayoutOption(CoreOptions.DIRECTION, Direction.DOWN)
        rootNode.setLayoutOption(CoreOptions::EDGE_ROUTING, EdgeRouting::SPLINES);
        rootNode.setLayoutOption(LayeredOptions::NODE_PLACEMENT_BK_FIXED_ALIGNMENT, FixedAlignment.BALANCED);
//        rootNode.setLayoutOption(CoreOptions.LAYOUT_HIERARCHY, true)
//        rootNode.setLayoutOption(CoreOptions.HIERARCHY_HANDLING, HierarchyHandling.SEPARATE_CHILDREN)
//        rootNode.setLayoutOption(LayeredOptions.SPACING_IN_LAYER_SPACING_FACTOR, 200f);
                
        // If dot is used draw edges first to prevent overlapping with states when layout is bad
        usedContext.setProperty(KlighdProperties.EDGES_FIRST, !USE_KLAY.booleanValue);

        if (root instanceof State) {
            rootNode.children += stateSynthesis.transform(root);
        } 
        
        // Add tracking adapter to allow access to source model associations
        val trackingAdapter = new SourceModelTrackingAdapter();
        rootNode.setLayoutOption(SCChartsDiagramProperties::MODEL_TRACKER, trackingAdapter);
        // Since the root node will node use to display the diagram (SimpleUpdateStrategy) the tracker must be set on the children.
        rootNode.children.forEach[eAdapters.add(trackingAdapter)]
        
        // Log elapsed time
        println(
            "SCCharts synthesis transformed model " + (root.label ?: root.name) + " in " +
                ((System.currentTimeMillis - startTime) as float / 1000) + "s.");
		
        return rootNode;
    }

    // -------------------------------------------------------------------------
    // Increase Visibility of needed protected inherited methods
    
    override getUsedContext() {
        return super.usedContext;
    }
    
}
