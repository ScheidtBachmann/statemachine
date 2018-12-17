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
package de.cau.cs.kieler.sccharts.ui.synthesis

import com.google.inject.Inject
import de.cau.cs.kieler.annotations.extensions.AnnotationsExtensions
import de.cau.cs.kieler.kexpressions.ValuedObject
import de.cau.cs.kieler.klighd.SynthesisOption
import de.cau.cs.kieler.klighd.kgraph.KEdge
import de.cau.cs.kieler.klighd.krendering.ViewSynthesisShared
import de.cau.cs.kieler.klighd.krendering.extensions.KEdgeExtensions
import de.cau.cs.kieler.sccharts.HistoryType
import de.cau.cs.kieler.sccharts.Transition
import de.cau.cs.kieler.sccharts.extensions.SCChartsTransitionExtensions
import de.cau.cs.kieler.sccharts.ui.synthesis.labels.TransitionLabelSerializer
import de.cau.cs.kieler.sccharts.ui.synthesis.styles.ColorStore
import de.cau.cs.kieler.sccharts.ui.synthesis.styles.TransitionStyles
import org.eclipse.elk.alg.layered.options.LayeredOptions
import org.eclipse.elk.core.options.CoreOptions

import static de.cau.cs.kieler.sccharts.ui.synthesis.GeneralSynthesisOptions.*
import static de.cau.cs.kieler.sccharts.ui.synthesis.styles.ColorStore.Color.*

import static extension de.cau.cs.kieler.klighd.syntheses.DiagramSyntheses.*

/**
 * Transforms {@link Transition} into {@link KEdge} diagram elements.
 * 
 * @author als ssm
 * @kieler.design 2015-08-13 proposed
 * @kieler.rating 2015-08-13 proposed yellow
 * 
 */
@ViewSynthesisShared
class TransitionSynthesis extends SubSynthesis<Transition, KEdge> {

    public static val SynthesisOption SHOW_USER_LABELS =
            SynthesisOption.createCheckOption("User Labels", true).setCategory(APPEARANCE)
            
    /**
     * Immediate transition will be more likely drwn from left to right as long as there are no more than this threshold
     *  number of other edges to flip to break a cycle.
     */ 
    public static val IMMEDIATE_TRANSITION_DIRECTION_THRESHOLD = 6

    @Inject extension KNodeExtensionsReplacement
    @Inject extension KEdgeExtensions
    @Inject extension AnnotationsExtensions
    @Inject extension SCChartsTransitionExtensions
    @Inject extension TransitionLabelSerializer
    @Inject extension TransitionStyles
    @Inject extension ColorStore
    
    override getDisplayedSynthesisOptions() {
        return newLinkedList(SHOW_USER_LABELS)
    }

    override performTranformation(Transition transition) {
        val edge = transition.createEdge().associateWith(transition);

        if (USE_KLAY.booleanValue) {
            edge.setLayoutOption(LayeredOptions::SPACING_EDGE_LABEL, 3.0)
            if (transition.isImplicitlyImmediate) {
                edge.setLayoutOption(LayeredOptions::PRIORITY_DIRECTION, IMMEDIATE_TRANSITION_DIRECTION_THRESHOLD)
            }
        } else {
            edge.setLayoutOption(CoreOptions::SPACING_EDGE_LABEL, 2.0);
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
        if (transition.nondeterministic) {
            edge.setNondeterministicStyle
        }
        else if (transition.triggerProbability > 0) {
            edge.setProbabilityStyle
        }

        // User schedules
        val userSchedule = if (transition.trigger !== null) (transition.trigger.schedule + transition.effects.map[ schedule ].flatten).toSet
            else (transition.effects.map[ schedule ].flatten).toSet
        if (userSchedule.size > 0) {
            val sLabel = new StringBuilder
            val exists = <Pair<ValuedObject, Integer>> newHashSet
            for (s : userSchedule) {
                val existPair = new Pair<ValuedObject, Integer>(s.valuedObject, s.priority)
                if (!exists.contains(existPair)) {
                    if (s !== userSchedule.head) sLabel.append(", ")
                    sLabel.append(s.valuedObject.name + " " + s.priority)
                    exists.add(existPair)
                }
            }
            edge.addTailLabel(sLabel.toString).associateWith(transition)
            edge.setUserScheduleStyle
        }
        
        switch (transition.history) {
            case SHALLOW: edge.addShallowHistoryDecorator
            case DEEP: edge.addDeepHistoryDecorator
            case !transition.deferred: edge.addDefaultDecorator
        }

        if (transition.deferred) {
            edge.addDeferredDecorator(transition.history == HistoryType::DEEP ||
                transition.history == HistoryType::SHALLOW);
        }

        switch (transition.preemption) {
            case STRONGABORT: edge.addStrongAbortionDecorator
            case TERMINATION: edge.addNormalTerminationDecorator
            default: {
            }
        };
        
        if (SHOW_COMMENTS.booleanValue) {
            transition.getCommentAnnotations.forEach[
                edge.addLabel(it.values.head, 
                    COMMENT_BACKGROUND_GRADIENT_2.color)
            ]
        }     
        
        //Configure selection style
        edge.setSelectionStyle

        // Add Label
        val label = transition.serializeLabel(SHOW_USER_LABELS.booleanValue)
        if (label.length != 0) {
            edge.addLabel(label.toString).associateWith(transition);
        }
        
        return <KEdge> newArrayList(edge)
    }

}