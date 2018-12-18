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
import de.cau.cs.kieler.klighd.krendering.extensions.KEdgeExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KNodeExtensions
import de.cau.cs.kieler.sccharts.Transition
import de.cau.cs.kieler.sccharts.extensions.SCChartsSerializeHRExtensions
import de.cau.cs.kieler.sccharts.ui.synthesis.styles.TransitionStyles
import java.util.ArrayList
import org.eclipse.elk.alg.layered.options.LayeredOptions
import org.eclipse.elk.core.options.CoreOptions

import static de.cau.cs.kieler.sccharts.ui.synthesis.GeneralSynthesisOptions.*

import static extension de.cau.cs.kieler.klighd.syntheses.DiagramSyntheses.*
import de.cau.cs.kieler.klighd.kgraph.KEdge
import de.cau.cs.kieler.sccharts.extensions.SCChartsTransitionExtensions

/**
 * Transforms {@link Transition} into {@link KEdge} diagram elements.
 * 
 * @author ssm
 * @kieler.design 2017-01-18 proposed 
 * @kieler.rating 2017-01-18 proposed 
 * 
 */
@ViewSynthesisShared
class SRTGTransitionSynthesis extends SRTGSubSynthesis<Transition, KEdge> {

    @Inject extension KNodeExtensions
    @Inject extension KEdgeExtensions
    @Inject extension SCChartsTransitionExtensions
    @Inject extension SCChartsSerializeHRExtensions
    @Inject extension TransitionStyles

    override performTranformation(Transition transition) {
        val edge = transition.createEdge().associateWith(transition);

//        edge.setLayoutOption(CoreOptions::EDGE_ROUTING, EdgeRouting::SPLINES);
        if (USE_KLAY.booleanValue) {
            edge.setLayoutOption(LayeredOptions::SPACING_LABEL_LABEL, 3.0d);
        } else {
            edge.setLayoutOption(CoreOptions::SPACING_LABEL_LABEL, 2.0);
        }
        
        // Connect with states
        edge.source = transition.sourceState.node;
        edge.target = transition.targetState.node;

        // Basic spline
        edge.addTransitionSpline();

        // Modifiers
        if (transition.isImplicitlyImmediate) {
            edge.setImmediateStyle
        }
        
        edge.addDefaultDecorator

        switch (transition.preemption) {
            case STRONGABORT: edge.addStrongAbortionDecorator
            case TERMINATION: edge.addNormalTerminationDecorator
            case WEAKABORT: {}
        };

        // Add Label
        val label = new StringBuilder();
        if (transition.label.nullOrEmpty) {
            label.append(transition.serializeHR);
        } else {
            label.append(transition.label);
        }
        if (transition.sourceState.outgoingTransitions.size > 1) {
            label.insert(0, ": ");
            label.insert(0, transition.sourceState.outgoingTransitions.indexOf(transition) + 1);
        }
        if (label.length != 0) {
            edge.addLabel(label.toString).associateWith(transition);
        }
        
//        edge.setLayoutOption(CoreOptions.NO_LAYOUT, true)
//        edge.setLayoutOption(CoreOptions.PRIORITY, 2)

        return new ArrayList<KEdge>(1) => [ add(edge) ];
    }

}