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
import de.cau.cs.kieler.klighd.kgraph.KNode
import de.cau.cs.kieler.klighd.krendering.ViewSynthesisShared
import de.cau.cs.kieler.klighd.krendering.extensions.KContainerRenderingExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KEdgeExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KNodeExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.sccharts.ControlflowRegion
import de.cau.cs.kieler.sccharts.ui.synthesis.styles.ControlflowRegionStyles
import org.eclipse.elk.alg.layered.options.LayeredOptions
import org.eclipse.elk.core.options.CoreOptions
import org.eclipse.elk.core.options.Direction
import org.eclipse.elk.core.options.EdgeRouting

import static de.cau.cs.kieler.sccharts.ui.synthesis.GeneralSynthesisOptions.*

import static extension de.cau.cs.kieler.klighd.syntheses.DiagramSyntheses.*

/**
 * Transforms {@link ControlflowRegion} into {@link KNode} diagram elements.
 * 
 * @author ssm
 * @kieler.design 2017-01-18 proposed 
 * @kieler.rating 2017-01-18 proposed 
 * 
 */
@ViewSynthesisShared
class SRTGControlflowRegionSynthesis extends SRTGSubSynthesis<ControlflowRegion, KNode> {

    @Inject
    extension KNodeExtensions
    
    @Inject
    extension KEdgeExtensions        

    @Inject
    extension KRenderingExtensions

    @Inject
    extension SRTGStateSynthesis

    @Inject
    extension ControlflowRegionStyles
    
    @Inject
    extension SRTGTransitionStyles
    @Inject extension KContainerRenderingExtensions    

    override performTranformation(ControlflowRegion region) {
        val node = region.createNode().associateWith(region)
        val result = <KNode> newArrayList(node)
        node.setMinimalNodeSize(40,7)
        
        val label = if(region.label.nullOrEmpty) "" else " " + region.label;

        node.addRegionFigure(region.final) => [
            associateWith(region)
            addText(label)
        ]

        val regionStateNode = region.createNode("states")
        regionStateNode.setLayoutOption(CoreOptions.DIRECTION, Direction.RIGHT)
        regionStateNode.setLayoutOption(CoreOptions::EDGE_ROUTING, EdgeRouting::SPLINES);
        result += regionStateNode
        regionStateNode.addRectangle => [
            lineWidth = 0
        ]
        
        val dummyEdge = regionStateNode.createEdge
        dummyEdge.addTransitionPolyline => [
            lineWidth = 0
        ]
        dummyEdge.source = node
        dummyEdge.target = regionStateNode

        for (state : region.states) {
            val stateNodes = state.transform
//            result += stateNodes
            regionStateNode.children += stateNodes
                        
            val stateNode = stateNodes.head
            val edge = region.createEdge(stateNode)

//            node.setLayoutOption(CoreOptions::EDGE_ROUTING, EdgeRouting::POLYLINE)
            if (USE_KLAY.booleanValue) {
                edge.setLayoutOption(LayeredOptions::SPACING_LABEL_LABEL, 3.0d)
            } else {
                edge.setLayoutOption(CoreOptions::SPACING_LABEL_LABEL, 2.0d)
            }

            edge.source = node
            edge.target = stateNode

            edge.addTransitionPolyline
            edge.setLayoutOption(CoreOptions.NO_LAYOUT, true)
        }

        return result;
    }

}