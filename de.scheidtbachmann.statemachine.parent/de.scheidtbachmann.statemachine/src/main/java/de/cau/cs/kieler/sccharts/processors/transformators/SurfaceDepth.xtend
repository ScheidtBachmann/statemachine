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

import com.google.inject.Inject
import de.cau.cs.kieler.sccharts.processors.SCChartsProcessor
import de.cau.cs.kieler.kicool.kitt.tracing.Traceable
import de.cau.cs.kieler.sccharts.State
import de.cau.cs.kieler.sccharts.extensions.SCChartsOptimization
import de.cau.cs.kieler.core.model.properties.IProperty
import de.cau.cs.kieler.core.model.properties.Property


import static extension de.cau.cs.kieler.kicool.kitt.tracing.TracingEcoreUtil.*
import static extension de.cau.cs.kieler.kicool.kitt.tracing.TransformationTracing.*
import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsCompareExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsScopeExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsFixExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsStateExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsActionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsTransitionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsControlflowRegionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsUniqueNameExtensions
import de.cau.cs.kieler.annotations.extensions.UniqueNameCache

/**
 * SCCharts SurfaceDepth Transformation.
 * 
 * @author cmot
 * @kieler.design 2013-09-05 proposed 
 * @kieler.rating 2013-09-05 proposed yellow
 */
class SurfaceDepth extends SCChartsProcessor implements Traceable {

    /** Enable duplicate transition optimization (DTO) */
    public static val IProperty<Boolean> ENABLE_DTO = 
       new Property<Boolean>("de.cau.cs.kieler.sccharts.processors.surfaceDepth.DTO", true)
       
    /** Enable superfluous conditional states optimization (SCSO) */
    public static val IProperty<Boolean> ENABLE_SCSO = 
       new Property<Boolean>("de.cau.cs.kieler.sccharts.processors.surfaceDepth.SCSO", true)
       
    /** Enable superfluous immediate transition optimization (SITO) */
    public static val IProperty<Boolean> ENABLE_SITO = 
       new Property<Boolean>("de.cau.cs.kieler.sccharts.processors.surfaceDepth.SITO", true)
       
    /** Enable dead code optimization */
    public static val IProperty<Boolean> ENABLE_DCO = 
       new Property<Boolean>("de.cau.cs.kieler.sccharts.processors.surfaceDepth.DCO", true)
       
    // -------------------------------------------------------------------------
    // --                 K I C O      C O N F I G U R A T I O N              --
    // -------------------------------------------------------------------------
    override getId() {
        "de.cau.cs.kieler.sccharts.processors.surfaceDepth"
    }
    
    override getName() {
        "Surface / Depth"
    }
 
    override process() {
        setModel(model.transform)
    }


//    override getExpandsFeatureId() {
//        return SCChartsFeature::SURFACEDEPTH_ID
//    }
//
//    override getProducesFeatureIds() {
//        return Sets.newHashSet();
//    }
//
//    override getNotHandlesFeatureIds() {
//        return Sets.newHashSet(SCChartsFeature::TRIGGEREFFECT_ID)
//    }

    // -------------------------------------------------------------------------
    @Inject extension KExpressionsCompareExtensions
    @Inject extension SCChartsScopeExtensions
    @Inject extension SCChartsControlflowRegionExtensions
    @Inject extension SCChartsStateExtensions
    @Inject extension SCChartsActionExtensions
    @Inject extension SCChartsTransitionExtensions
    @Inject extension SCChartsFixExtensions
    @Inject extension SCChartsOptimization
    @Inject extension SCChartsUniqueNameExtensions

    // This prefix is used for naming of all generated signals, states and regions
    static public final String GENERATED_PREFIX = "__sd_"
    
    private val nameCache = new UniqueNameCache

    // -------------------------------------------------------------------------
    // --                S U R F A C E  &   D E P T H                         --
    // -------------------------------------------------------------------------
    // @requires: abort transformation (there must not be any weak or strong aborts outgoing from
    // macro state, hence we just consider simple states here)
    //
    // For every non-hierarchical state S that has outgoing transitions and is of type NORMAL:
    // Create an auxiliary valuedObject isDepth_S that indicates that the state was
    // entered in an earlier tick and add it to the parent state P of the parent region R of S.
    // Modify all triggers of outgoing non-immediate transitions T of S: 1. set them to be
    // immediate and 2. add "isDepth_S &&" to its trigger.
    // Modify state S and make it a conditional.
    // Now walk through all n transitions T_1..n outgoing from S (ordered ascended by their priority):
    // For T_i create a conditional C_i. Connect C_i-1 and C_i with a true triggered immediate transition
    // of priority 2. Set priority of T_i to 1. Note that T_i's original priority is now implicitly encoded
    // by the sequential order of evaluating the conditionals C_1..n.
    // The last conditional C_n connect with a new a normal state D (the explicit depth of S).
    // Connect D with C_1 using a transition that emits isDepth_S.
    // Note that conditionals cannot be marked to be initial. Hence, if a state S is marked initial 
    // then an additional initial state I with a true triggered immediate transition to S will
    // be inserted. \code{S} is then marked not to be initial. This is a necessary pre-processing for
    // the above transformation.
    def State transform(State rootState) {
        nameCache.clear
        
        // Traverse all states
        rootState.allStates.toList.forEach [ targetState |
            targetState.transformSurfaceDepth(rootState)
        ]
        
        val scso = environment.getProperty(ENABLE_SCSO)
        val sito = environment.getProperty(ENABLE_SITO)
        val dco = environment.getProperty(ENABLE_DCO)

        if (scso || sito || dco) {
            snapshot
            var optimizedRootState = rootState
            
            if (scso) optimizedRootState = optimizedRootState.optimizeSuperflousConditionalStates
            if (sito) optimizedRootState = optimizedRootState.optimizeSuperflousImmediateTransitions
            if (dco) optimizedRootState = optimizedRootState.fixDeadCode
            
            return optimizedRootState
        } else {
            return rootState
        }
    }

    def void transformSurfaceDepth(State state, State targetRootState) {
        state.setDefaultTrace
        val numTransition = state.outgoingTransitions.size
        // root or final state
        if (state.isRootState || (numTransition == 0 && state.final)) {
            return
        }
        if (numTransition == 0 && state.isHierarchical) {
            // Do not transform  halt-superstates
            // Rationale: It would be necessary to add a termination transition with a delayed pause
            // self-loop (over an additional auxiliary state)
            // or not a loop but a transition to such a state but
            // this would be dead code.
            // Hence, we decided to not transform such states
            if (!state.regionsMayTerminate) {
                // Optimization according to decision in SYNCHRON meeting 22. Aug 2016
                return
            } else {
                val haltState = state.parentRegion.createState(GENERATED_PREFIX + "HaltState")
                val halt = state.createTransitionTo(haltState)
                halt.setTypeTermination
                haltState.createTransitionTo(haltState)
                state.transformSurfaceDepth(targetRootState)
                return
            }
        }
        if (numTransition == 0) { // && !state.isHierarchical
        // halt state --> create explicit pause (self loop)
            state.createTransitionTo(state)
        }
        if (numTransition > 0) {
            // termination
            if (numTransition == 1 && state.outgoingTransitions.get(0).isTermination) {
                return
            }
            val immediate0 = state.outgoingTransitions.get(0).implicitlyImmediate
            val noTrigger0 = state.outgoingTransitions.get(0).trigger === null
            val noEffects0 = state.outgoingTransitions.get(0).effects.nullOrEmpty
            if (numTransition == 1 && noTrigger0) {
                // pause
                if (!immediate0 && noEffects0) {
                    return
                }
                // action
                if (immediate0 && !noEffects0) {
                    return
                }
            }
            if (numTransition > 1) {
                val immediate1 = state.outgoingTransitions.get(1).implicitlyImmediate
                val noTrigger1 = state.outgoingTransitions.get(1).trigger === null
                val noEffects1 = state.outgoingTransitions.get(1).effects.nullOrEmpty
                // conditional
                if (immediate0 && !noTrigger0 && noEffects0 && immediate1 && noTrigger1 && noEffects1) {
                    // This checks if the second transition is the default transition...
                    // ... however, there may still be other transitions! 
                    // This would violate the normalized form.
                    if (numTransition > 2) {
                        // Further transitions are not reachable! Remove them.
                        for (var i = 2; i < numTransition; i++) {
                            state.outgoingTransitions.remove(i)
                        }
                    }
                    return
                }
            }
        }

        // /////////////////////////////////////////
        // O L D     C O N D I T I O N      ///
        // /////////////////////////////////////////
        // FIXME: REMOVE THIS AFTER SYNCHRON MEETING 22. AUG 2016
        //
//        if (!(state.outgoingTransitions.size > 0 && state.type == StateType::NORMAL &&
//            !state.outgoingTransitions.get(0).typeTermination &&
//            (state.outgoingTransitions.get(0).trigger != null || !state.outgoingTransitions.get(0).immediate))) {
//            return
//        }
        val parentRegion = state.parentRegion;

        // Duplicate immediate transitions
        val immediateTransitions = state.outgoingTransitions.filter[isImmediate].sortBy[-priority].toList
        for (transition : immediateTransitions) {
            val transitionCopy = transition.copy
            transitionCopy.setSourceState(transition.sourceState)
            transitionCopy.setTargetState(transition.targetState)
            transitionCopy.setHighestPriority
            transition.setNotImmediate
        }

        // Modify surfaceState (the original state)
        val surfaceState = state
        var depthState = state
        surfaceState.uniqueName(nameCache)

        // For every state create a number of surface nodes
        val orderedTransitionList = state.outgoingTransitions.sortBy[priority];

        var pauseInserted = false

        var State previousState = surfaceState
        var State currentState = surfaceState
        
        surfaceState.setDefaultTrace // All following states etc. will be traced to surfaceState if not traced to transition
        for (transition : orderedTransitionList) {

            if (!(transition.isImmediate) && !pauseInserted) {

                // For the first transition that is NOT immediate (a delay transition)
                // and if we have not inserted a pause yet, then do it now
                // Make sure the next transition is delayed 
                pauseInserted = true

                depthState = parentRegion.createState(GENERATED_PREFIX + "Pause").uniqueName(nameCache)
                previousState.createImmediateTransitionTo(depthState).trace(transition)
                // System.out.println("Connect pause 1:" + previousState.id + " -> " + depthState.id);
                val pauseState = parentRegion.createState(GENERATED_PREFIX + "Depth").uniqueName(nameCache)
                depthState.createTransitionTo(pauseState).trace(transition)

                // Imitate next cycle
                previousState = pauseState
                currentState = null

            // System.out.println("Connect pause 2:" + depthState.id + " -> " + pauseState.id);
            }

            if (currentState === null) {
                // Create a new state
                currentState = parentRegion.createState(GENERATED_PREFIX + "S").uniqueName(nameCache)
                // System.out.println("New currentState := " + currentState.id)
                // Move transition to this state
                // System.out.println("Move transition from " + transition.sourceState.id + " to " + currentState.id)
                currentState.outgoingTransitions.add(transition)

                // Connect
                previousState.createImmediateTransitionTo(currentState)
            // System.out.println("Connect:" + previousState.id + " -> " + currentState.id);
            }

            // Ensure the transition is immediate
            transition.setImmediate(true)

            // We can now set the transition priority to 1 (it is reflected implicitly by the sequential order now)
            transition.setSpecificPriority(1)

            // Next cycle
            // System.out.println("Set previousState := " + currentState.id)
            previousState = currentState
            currentState = null
            
            
            //i++;
            //if (i == 2) {
            //    return;
            // }
            
        }


        // Connect back depth with surface state
        var T2tmp = previousState.createImmediateTransitionTo(depthState).trace(previousState)
        // System.out.println("Connect BACK:" + previousState.id + " -> " + depthState.id);
        // Afterwards do the DTO transformation
        /* Der Knoten _Pause ist besonders ausgezeichnet. Er hat meistens zwei
         * eingehende Kanten T1 von der surface und T2 von dem feedback aus der depth.
         * 
         * Falls _Pause KEINE zwei eingehenden Kanten hat, so ist er vermutlich
         * als initial Knoten markiert!
         * 
         * Gehe beide Kanten T1 und T2 rückwärts zu jeweiligen Source-Knoten K1 und
         * K2 entlang und verleiche die ausgehenden Transitionen TK1 und TK2 (die
         * nicht T1 oder T2 sind). 
         *  
         * Wenn diese gleich sind wird K1 der neue Pause
         * Knoten und die eingehende Kanten von K2 zeigt nun auf den neuen _Pause.
         * K2, T2 und TK2 werden eliminiert.
         * 
         * Vergleiche nun rekursiv wieder die eingehenden Kanten von neuen _Pause
         bis TK1 und TK2 ungleich sind.*/
        var stateAfterDepth = depthState

        // System.out.println("stateAfterDepth:" + stateAfterDepth.id);
        var doDTO = environment.getProperty(ENABLE_DTO)

        if (doDTO) {
            var done = false
            while (!done) {
                done = true
                if (stateAfterDepth.incomingTransitions.size == 2) {

                    // T1 is the incoming node from the surface
                    var T1tmp = stateAfterDepth.incomingTransitions.get(0)
                    if (T1tmp == T2tmp) {
                        T1tmp = stateAfterDepth.incomingTransitions.get(1)
                    }
                    val T1 = T1tmp
                    val T2 = T2tmp

                    // T2 is the incoming node from the feedback
                    val K1 = T1.sourceState
                    val K2 = T2.sourceState
                    if (K1.outgoingTransitions.exists[it != T1]
                        && K2.outgoingTransitions.exists[it != T2]
                        && K1 != K2
                    ) {
                        val TK1 = K1.outgoingTransitions.findFirst[it != T1]
                        val TK2 = K2.outgoingTransitions.findFirst[it != T2]
                        if ((TK1.targetState == TK2.targetState)
                                && ((TK1.trigger == TK2.trigger)
                            || (TK2.trigger !== null && TK1.trigger !== null
                                && (TK1.trigger.equals2(TK2.trigger))
                            ))) {// TODO: TK1.trigger.equals2 is currently only implemented for the most trivial triggers
                            stateAfterDepth = K1

                            val t = K2.incomingTransitions.get(0)
                            t.setTargetState(stateAfterDepth)
                            for (transition : K2.outgoingTransitions) {
                                stateAfterDepth.trace(transition) // KITT: Redirect tracing before removing
                                transition.targetState.incomingTransitions.remove(transition)
                            }
                            stateAfterDepth.trace(K2) // KITT: Redirect tracing before removing
                            K2.parentRegion.states.remove(K2)
                            done = false
                            T2tmp = t
                        }
                    }
                }

            // End of DTO transformation
            // This MUST be highest priority so that the control flow restarts and takes other 
            // outgoing transition.
            // There should not be any other outgoing transition.
            }
        }
    }
    
    def SCCharts transform(SCCharts sccharts) {
        sccharts => [ rootStates.forEach[ it.transform ] ]
    }    

}
