/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 * 
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2015 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.sccharts.ui.synthesis.srtg

import com.google.inject.Inject
import de.cau.cs.kieler.klighd.krendering.ViewSynthesisShared
import de.cau.cs.kieler.klighd.krendering.extensions.KNodeExtensions
import de.cau.cs.kieler.sccharts.ControlflowRegion
import de.cau.cs.kieler.sccharts.State
import org.eclipse.elk.core.options.CoreOptions

import static de.cau.cs.kieler.sccharts.ui.synthesis.GeneralSynthesisOptions.*
import static extension de.cau.cs.kieler.klighd.syntheses.DiagramSyntheses.*
import de.cau.cs.kieler.klighd.krendering.extensions.KEdgeExtensions
import org.eclipse.elk.alg.layered.options.LayeredOptions
import de.cau.cs.kieler.klighd.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.klighd.kgraph.KNode
import org.eclipse.elk.core.math.ElkPadding

/**
 * Transforms {@link State} into {@link KNode} diagram elements.
 * 
 * @author ssm
 * @kieler.design 2017-01-18 proposed 
 * @kieler.rating 2017-01-18 proposed 
 * 
 */
@ViewSynthesisShared
class SRTGStateSynthesis extends SRTGSubSynthesis<State, KNode> {

    @Inject
    extension KNodeExtensions
    
    @Inject
    extension KEdgeExtensions    
    
    @Inject
    extension KRenderingExtensions    

    @Inject
    extension SRTGTransitionSynthesis

    @Inject
    extension SRTGControlflowRegionSynthesis

    @Inject
    extension SRTGStateStyles
    
    @Inject
    extension SRTGTransitionStyles

    override performTranformation(State state) {
        val node = state.createNode().associateWith(state);
        val result = <KNode> newArrayList(node)

        node.addLayoutParam(CoreOptions::ALGORITHM, "org.eclipse.elk.box");
        node.setLayoutOption(CoreOptions::EXPAND_NODES, true);
        node.setLayoutOption(CoreOptions::SPACING_NODE_NODE, 10d); //10.5 // 8f
        node.setLayoutOption(CoreOptions::PADDING, new ElkPadding(2d));

        // Basic state style
        node.addDefaultFigure

        // Styles from modifiers
        if (state.isInitial) {
            node.setInitialStyle
        }
        if (state.isFinal) {
            node.setFinalStyle
        }

        node.setShadowStyle

        if (!state.label.nullOrEmpty) {
           node.addSimpleStateLabel(state.label).associateWith(state)
        } else {
            node.addEmptyStateLabel
        }

        // Transform all outgoing transitions
        for (transition : state.outgoingTransitions) {
            
//            val transitionNode = transition.createNode
//            transitionNode.addConnectorFigure
//            node.children += transitionNode        

            transition.transform
        }
        
//        val stateRegionNode = createNode
//        stateRegionNode.setLayoutOption(CoreOptions.DIRECTION, Direction.DOWN)
////        stateRegionNode.setLayoutOption(CoreOptions.COMMENT_BOX, true)
//        result += stateRegionNode
//        stateRegionNode.addRectangle => [
//            lineWidth = 1
//        ]        
//                

        // Transform regions
        for (region : state.regions) {
            switch region {
                ControlflowRegion: {
                        val regionNodes = region.transform
//                        result += regionNodes
                            SRTGSynthesis.myRootNode.children += regionNodes
//                        stateRegionNode.children += regionNodes
                        
                        val regionNode = regionNodes.head
                        val edge = state.createEdge(region)

                        if (USE_KLAY.booleanValue) {
                            edge.setLayoutOption(LayeredOptions::SPACING_LABEL_LABEL, 3.0d)
                        } else {
                            edge.setLayoutOption(CoreOptions::SPACING_LABEL_LABEL, 2.0)
                        }
        
                        edge.source = node
                        edge.target = regionNode

                        edge.addTransitionPolyline
                        edge.setLayoutOption(CoreOptions.NO_LAYOUT, true)


                        val dummyEdge = createEdge
                        dummyEdge.addTransitionPolyline => [
                            lineWidth = 0
                        ]
                        if (state.eContainer == null) {
                            dummyEdge.source = state.node                        
                        } else {
                            dummyEdge.source = state.eContainer.getNode("states")
                        }
                        dummyEdge.target = region.node
                        dummyEdge.setLayoutOption(CoreOptions.PRIORITY, 2)

                    }
            }
        }

        return result;
    }

}