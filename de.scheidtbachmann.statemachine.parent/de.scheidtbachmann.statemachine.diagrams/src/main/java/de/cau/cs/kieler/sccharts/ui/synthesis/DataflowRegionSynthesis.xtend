/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://rtsys.informatik.uni-kiel.de/kieler
 * 
 * Copyright 2016 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 */
package de.cau.cs.kieler.sccharts.ui.synthesis

import com.google.inject.Inject
import de.cau.cs.kieler.kexpressions.ValuedObject
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsDeclarationExtensions
import de.cau.cs.kieler.kicool.ui.kitt.tracing.TracingVisualizationProperties
import de.cau.cs.kieler.klighd.KlighdConstants
import de.cau.cs.kieler.klighd.SynthesisOption
import de.cau.cs.kieler.klighd.kgraph.KNode
import de.cau.cs.kieler.klighd.krendering.ViewSynthesisShared
import de.cau.cs.kieler.klighd.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.klighd.util.KlighdProperties
import de.cau.cs.kieler.sccharts.DataflowRegion
import de.cau.cs.kieler.sccharts.extensions.SCChartsSerializeHRExtensions
import de.cau.cs.kieler.sccharts.ui.synthesis.styles.DataflowRegionStyles
import org.eclipse.elk.alg.layered.options.NodePlacementStrategy
import org.eclipse.elk.alg.layered.options.GreedySwitchType
import org.eclipse.elk.alg.layered.options.LayeredOptions
import org.eclipse.elk.core.math.ElkPadding
import org.eclipse.elk.core.options.CoreOptions
import org.eclipse.elk.core.options.Direction
import org.eclipse.elk.core.options.EdgeRouting

import static extension de.cau.cs.kieler.klighd.syntheses.DiagramSyntheses.*
import static de.cau.cs.kieler.sccharts.ui.synthesis.GeneralSynthesisOptions.*
import de.cau.cs.kieler.annotations.extensions.AnnotationsExtensions

/**
 * @author ssm
 *
 * Transforms {@link DataflowRegion} into {@link KNode} diagram elements.
 * 
 * @author als ssm
 * @kieler.design 2015-08-13 proposed
 * @kieler.rating 2015-08-13 proposed yellow
 * 
 */
@ViewSynthesisShared
class DataflowRegionSynthesis extends SubSynthesis<DataflowRegion, KNode> {
    
    public static val SynthesisOption CIRCUIT = SynthesisOption.createCheckOption("Circuit layout", false).
        setCategory(GeneralSynthesisOptions::DATAFLOW)
    public static val SynthesisOption AUTOMATIC_INLINE = SynthesisOption.createCheckOption("Automatic inline", false).
        setCategory(GeneralSynthesisOptions::DATAFLOW)
    
    @Inject extension KNodeExtensionsReplacement
    @Inject extension KRenderingExtensions
    @Inject extension KExpressionsDeclarationExtensions
    @Inject extension DataflowRegionStyles
    @Inject extension SCChartsSerializeHRExtensions
    @Inject extension EquationSynthesis 
    @Inject extension AnnotationsExtensions
    @Inject extension CommentSynthesis
    
    override getDisplayedSynthesisOptions() {
        return newArrayList(CIRCUIT, AUTOMATIC_INLINE)
    }   
    
    override performTranformation(DataflowRegion region) {
        val node = region.createNode().associateWith(region)

        node.addLayoutParam(CoreOptions::ALGORITHM, "org.eclipse.elk.layered")
        node.addLayoutParam(CoreOptions::EDGE_ROUTING, EdgeRouting::ORTHOGONAL)
        node.addLayoutParam(CoreOptions::DIRECTION, Direction::RIGHT)
        node.addLayoutParam(LayeredOptions::THOROUGHNESS, 100)
        node.addLayoutParam(LayeredOptions::NODE_PLACEMENT_STRATEGY, NodePlacementStrategy::NETWORK_SIMPLEX)
        node.addLayoutParam(CoreOptions::SEPARATE_CONNECTED_COMPONENTS, true)
        node.setLayoutOption(LayeredOptions::HIGH_DEGREE_NODES_TREATMENT, true)
        
        if (CIRCUIT.booleanValue) {
            node.addLayoutParam(LayeredOptions::CROSSING_MINIMIZATION_SEMI_INTERACTIVE, true)
          node.addLayoutParam(LayeredOptions::CROSSING_MINIMIZATION_GREEDY_SWITCH_TYPE, GreedySwitchType::TWO_SIDED)
            
            node.setLayoutOption(CoreOptions::SPACING_NODE_NODE, 10d); //10.5 // 8f
            node.setLayoutOption(CoreOptions::PADDING, new ElkPadding(4d));
//            node.setLayoutOption(LayeredOptions::SPACING_EDGE_SPACING_FACTOR, 0.8f); // 0.7
//            node.setLayoutOption(LayeredOptions::SPACING_EDGE_NODE_SPACING_FACTOR, 0.75f); //1 //0.5
//            node.setLayoutOption(LayeredOptions::SPACING_IN_LAYER_SPACING_FACTOR, 0.25f); //0.2 // 0.5
        }
            
        node.setLayoutOption(KlighdProperties::EXPAND, true)
        
        // User schedules
        val sLabel = new StringBuilder
        val userSchedule = region.schedule
        if (userSchedule.size > 0) {
            val exists = <Pair<ValuedObject, Integer>> newHashSet
            for (s : userSchedule) {
                val existPair = new Pair<ValuedObject, Integer>(s.valuedObject, s.priority)
                if (!exists.contains(existPair)) {
                    sLabel.append(", ")
                    sLabel.append(s.valuedObject.name + " " + s.priority)
                    exists.add(existPair)
                }
            }
        }    
        val label = if(region.label.nullOrEmpty) "" else " " + region.label + sLabel.toString

        // Expanded
        node.addRegionFigure(false) => [
            setAsExpandedView
//            addDoubleClickAction(ReferenceExpandAction::ID)
            if (region.declarations.empty) {
                addStatesArea(label.nullOrEmpty);
            } else {
                addStatesAndDeclarationsAndActionsArea(false, false);
                // Add declarations
                for (declaration : region.variableDeclarations) {
                    addDeclarationLabel(declaration.serializeHighlighted(true)) => [
                        setProperty(TracingVisualizationProperties.TRACING_NODE, true);
                        associateWith(declaration);
                        children.forEach[associateWith(declaration)];
                    ]
                }
            }
            if (sLabel.length > 0) it.setUserScheduleStyle
            // Add Button after area to assure correct overlapping
            if (!CIRCUIT.booleanValue)
                addCollapseButton(label).addDoubleClickAction(KlighdConstants::ACTION_COLLAPSE_EXPAND);
        ]

        // Collapsed
        node.addRegionFigure(false) => [
            setAsCollapsedView
            if (sLabel.length > 0) it.setUserScheduleStyle
//            addDoubleClickAction(ReferenceExpandAction::ID)
            if (CIRCUIT.booleanValue)
                addExpandButton(label).addDoubleClickAction(KlighdConstants::ACTION_COLLAPSE_EXPAND);
        ]
        
        if (SHOW_COMMENTS.booleanValue) {
            region.getCommentAnnotations.forEach[
                node.children += it.transform                
            ]
        }           

        // translate all direct dataflow equations
        node.children += region.equations.performTranformation

        return <KNode> newArrayList(node)
    }
    
    /**
     * Create region area for reference states
     * 
     * @param state 
     *          the reference state
     */
    def KNode createReferenceDataflowRegion(ValuedObject valuedObject) {
        val node = createNode().associateWith(valuedObject); // This association is important for the ReferenceExpandAction
//        if (USE_KLAY.booleanValue) {
            node.addLayoutParam(CoreOptions::ALGORITHM, "de.cau.cs.kieler.klay.layered");
            node.setLayoutOption(CoreOptions::SPACING_NODE_NODE, 10d); //10.5 // 8f
            node.setLayoutOption(CoreOptions::PADDING, new ElkPadding(4d));
//        } else {
//            node.addLayoutParam(LayoutOptions::ALGORITHM, "de.cau.cs.kieler.graphviz.dot");
//            node.setLayoutOption(LayoutOptions::SPACING, 40f);
//        }
//        node.addLayoutParam(LayoutOptions::EDGE_ROUTING, EdgeRouting::SPLINES);
//        node.setLayoutOption(LayoutOptions::SPACING, 40f);

        // Set initially collapsed
        node.setLayoutOption(KlighdProperties::EXPAND, false);

        if (!CIRCUIT.booleanValue) {
            // Expanded
            node.addRegionFigure(false) => [
                setAsExpandedView;
                addStatesArea(true);
//                addDoubleClickAction(ReferenceExpandAction::ID)
                // Add Button after area to assure correct overlapping
                // Use special expand action to resolve references
//                addCollapseButton(null).addDoubleClickAction(ReferenceExpandAction::ID);
            ]
    
            // Collapsed
            node.addRegionFigure(false) => [
                setAsCollapsedView;
//                addDoubleClickAction(ReferenceExpandAction::ID)
//                addExpandButton(null).addDoubleClickAction(ReferenceExpandAction::ID);
            ]
        }

        return node;
    }    
    
}