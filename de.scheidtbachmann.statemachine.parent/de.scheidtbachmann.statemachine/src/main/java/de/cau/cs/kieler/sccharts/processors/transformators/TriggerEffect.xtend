/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2014 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.sccharts.processors.transformators

import com.google.common.collect.Sets
import com.google.inject.Inject
import de.cau.cs.kieler.kicool.compilation.ProcessorType
import de.cau.cs.kieler.sccharts.processors.SCChartsProcessor
import de.cau.cs.kieler.kicool.kitt.tracing.Traceable
import de.cau.cs.kieler.sccharts.State
import de.cau.cs.kieler.sccharts.Transition
import de.cau.cs.kieler.sccharts.features.SCChartsFeature

import static extension de.cau.cs.kieler.kicool.kitt.tracing.TransformationTracing.*
import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.sccharts.extensions.SCChartsScopeExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsTransitionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsActionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsStateExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsUniqueNameExtensions
import de.cau.cs.kieler.annotations.extensions.UniqueNameCache

/**
 * SCCharts TriggerEffect Transformation.
 * 
 * @author cmot
 * @kieler.design 2013-09-05 proposed 
 * @kieler.rating 2013-09-05 proposed yellow
 */
class TriggerEffect extends SCChartsProcessor implements Traceable {

    //-------------------------------------------------------------------------
    //--                 K I C O      C O N F I G U R A T I O N              --
    //-------------------------------------------------------------------------
    override getId() {
        "de.cau.cs.kieler.sccharts.processors.triggerEffect"
    }
    
    override getName() {
        "Trigger / Effect"
    }
 
    override process() {
        setModel(model.transform)
    }


//    override getExpandsFeatureId() {
//        return SCChartsFeature::TRIGGEREFFECT_ID
//    }
//
//    override getProducesFeatureIds() {
//        return Sets.newHashSet(SCChartsFeature::SURFACEDEPTH_ID)
//    }
//
//    // THIS IS NOW DONE INDIRECTLY BY DECLARING META DEPENDENCIES ON FEATURE GROUPS
//    override getNotHandlesFeatureIds() {
////        return Sets.newHashSet(SCChartsFeatureGroup::EXTENDED_ID)
//        return Sets.newHashSet()
//    }
    
//    override getNotHandlesFeatureIds() {
//        return Sets.newHashSet()
//    }

    //-------------------------------------------------------------------------    
    @Inject extension SCChartsScopeExtensions
    @Inject extension SCChartsStateExtensions
    @Inject extension SCChartsActionExtensions
    @Inject extension SCChartsTransitionExtensions
    @Inject extension SCChartsUniqueNameExtensions
//    @Inject extension ValuedObjectRise

    // This prefix is used for naming of all generated signals, states and regions
    static public final String GENERATED_PREFIX = "__te_"
    
    private val nameCache = new UniqueNameCache

    //-------------------------------------------------------------------------
    //--                  T R I G G E R   E F F E C T                        --
    //-------------------------------------------------------------------------
    // For every transition T that has both, a trigger and an effect do the following:
    //   For every effect:
    //     Create a conditional C and add it to the parent of T's source state S_src.
    //     create a new true triggered immediate effect transition T_eff and move all effects of T to T_eff.
    //     Set the T_eff to have T's target state. Set T to have the target C.
    //     Add T_eff to C's outgoing transitions. 
    def State transform(State rootState) {
        nameCache.clear
//        rootState.transformValuedObjectRise

        // Traverse all transitions
        for (targetTransition : rootState.getAllContainedTransitions.toList) {
            targetTransition.transformTriggerEffect(rootState)
        }
        rootState
    }

    def void transformTriggerEffect(Transition transition, State targetRootState) {

        // Only apply this to transition that have both, a trigger (or is a termination) and one or more effects 
        if (((transition.trigger != null || !transition.immediate || transition.isTermination) &&
            !transition.effects.nullOrEmpty) || transition.effects.size > 1) {
            val targetState = transition.targetState
            val parentRegion = targetState.parentRegion
            val transitionOriginalTarget = transition.targetState
            var Transition lastTransition = transition

            for (effect : transition.effects.immutableCopy) {
                    val effectState = parentRegion.createState(GENERATED_PREFIX + "S").trace(transition, effect)
                    effectState.uniqueName(nameCache)
                    val effectTransition = createImmediateTransition().trace(transition, effect)
                    effectTransition.addEffect(effect) 
                    effectTransition.setSourceState(effectState)
                    lastTransition.setTargetState(effectState)
                    lastTransition = effectTransition
            }

            lastTransition.setTargetState(transitionOriginalTarget)
        }
    }

    def SCCharts transform(SCCharts sccharts) {
        sccharts => [ rootStates.forEach[ it.transform ] ]
    }

}
