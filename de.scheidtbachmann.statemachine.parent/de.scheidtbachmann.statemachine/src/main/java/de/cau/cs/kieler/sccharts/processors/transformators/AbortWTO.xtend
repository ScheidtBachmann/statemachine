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
import de.cau.cs.kieler.kexpressions.Expression
import de.cau.cs.kieler.kexpressions.ValuedObject
import de.cau.cs.kieler.kicool.compilation.ProcessorType
import de.cau.cs.kieler.sccharts.processors.SCChartsProcessor
import de.cau.cs.kieler.sccharts.State
import de.cau.cs.kieler.sccharts.Transition
import de.cau.cs.kieler.sccharts.featuregroups.SCChartsFeatureGroup
import de.cau.cs.kieler.sccharts.features.SCChartsFeature
import java.util.HashMap

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsCreateExtensions
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsComplexCreateExtensions
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsDeclarationExtensions
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsValuedObjectExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsTransformationExtension
import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.sccharts.extensions.SCChartsScopeExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsControlflowRegionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsStateExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsActionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsTransitionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsUniqueNameExtensions
import de.cau.cs.kieler.annotations.extensions.UniqueNameCache
import de.cau.cs.kieler.kexpressions.keffects.extensions.KEffectsExtensions

/**
 * SCCharts Abort WTO Transformation. This may require an advanced SCG compiler that can handle depth join.
 * 
 * @author cmot
 * @kieler.design 2013-09-05 proposed 
 * @kieler.rating 2013-09-05 proposed yellow
 */
class AbortWTO extends SCChartsProcessor {

    //-------------------------------------------------------------------------
    //--                 K I C O      C O N F I G U R A T I O N              --
    //-------------------------------------------------------------------------
    
    override getId() {
        "de.cau.cs.kieler.sccharts.processors.abort.wto"
    }
    
    override getName() {
        "Abort WTO"
    }
    
    override process() {
        setModel(model.transform)
    }


//    override getExpandsFeatureId() {
//        return SCChartsFeature::ABORT_ID
//    }
//
//    override getProducesFeatureIds() {
//        return Sets.newHashSet(SCChartsFeature::INITIALIZATION_ID, SCChartsFeature::ENTRY_ID,
//            SCChartsFeature::CONNECTOR_ID)
//    }
//
//    override getNotHandlesFeatureIds() {
//        return Sets.newHashSet(SCChartsFeature::COUNTDELAY_ID, SCChartsFeature::COMPLEXFINALSTATE_ID, SCChartsFeatureGroup::EXPANSION_ID)
//    }

    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
    @Inject extension KExpressionsCreateExtensions
    @Inject extension KExpressionsComplexCreateExtensions
    @Inject extension KExpressionsDeclarationExtensions
    @Inject extension KEffectsExtensions    
    @Inject extension SCChartsScopeExtensions
    @Inject extension SCChartsControlflowRegionExtensions
    @Inject extension SCChartsStateExtensions
    @Inject extension SCChartsActionExtensions
    @Inject extension SCChartsTransitionExtensions
    @Inject extension SCChartsUniqueNameExtensions
    @Inject extension SCChartsTransformationExtension

    // This prefix is used for naming of all generated signals, states and regions
    static public final String GENERATED_PREFIX = "_"

    private val nameCache = new UniqueNameCache => [ it += "_term" ]

    //-------------------------------------------------------------------------
    //--   A B O R T   A L T E R N A T I V E  T R A N S F O R M A T I O N    --
    //-------------------------------------------------------------------------
    // The new DEFAULT abort transformation, previously transformAbortAlternative.
    // Transforming Aborts.
    def State transform(State rootState) {
        nameCache.clear
        // Traverse all states
        var done = false;
        for (targetState : rootState.getAllContainedStatesList) {
            if (!done) {
                targetState.transformAbort(rootState);
            }
        }
        rootState
    }

    // For all transitions of a state compute the maximal priority
    def int maxPriority(State state) {
        var priority = 0;
        for (transition : state.outgoingTransitions) {
            val newPriority = transition.priority;
            if (newPriority > priority) {
                priority = newPriority;
            }
        }
        priority;
    }

    // Traverse all states 
    def void transformAbort(State state, State targetRootState) {

        // (a) more than one transitions outgoing OR
        // (b) ONE outgoing transition AND
        //     + not a termination transition without any trigger
        val stateHasUntransformedTransitions = ((state.outgoingTransitions.size > 1) || ((state.outgoingTransitions.size ==
            1) && (!(state.outgoingTransitions.filter[ isTermination ].filter[trigger == null].size == 1))))

        val stateHasUntransformedAborts = (!(state.outgoingTransitions.filter[ !isTermination ].nullOrEmpty))

        //        if (state.hierarchical && stateHasUntransformedAborts && state.label != "WaitAandB") {
        if ((state.controlflowRegionsContainStates || state.containsInnerActions) && stateHasUntransformedTransitions) { // && state.label != "WaitAB") {
            val transitionTriggerVariableMapping = new HashMap<Transition, ValuedObject>

            // Remember all outgoing transitions and regions (important: do not consider regions without inner states! => regions2)
            val outgoingTransitions = state.outgoingTransitions.immutableCopy
            val regions = state.getNotEmptyControlflowRegions.toList

            // .. || stateHasUntransformedTransitions : for conditional terminations!
            if (stateHasUntransformedAborts || stateHasUntransformedTransitions) {
                val ctrlRegion = state.createControlflowRegion(GENERATED_PREFIX + "Ctrl").uniqueName(nameCache)
                val runState = ctrlRegion.createInitialState(GENERATED_PREFIX + "Run").uniqueName(nameCache)
                val doneState = ctrlRegion.createFinalState(GENERATED_PREFIX + "Done").uniqueName(nameCache)

                // Build up weak and strong abort triggers
                var Expression strongAbortTrigger = null;

                // FIXME: This is a temporary set to TRUE but it should be set to FALSE to help the compiler
                // currently this breaks a lot of SCGs downstream, we should work on this issue! Email to SSM 5.10.14 
                var strongImmediateTrigger = true;
                var Expression weakAbortTrigger = null;
                var weakImmediateTrigger = true; // weak aborts need always to be --> immediate AbortComplexityWeak2.sct
                for (transition : outgoingTransitions) {

                    // Create a new _transitionTrigger valuedObject
                    val transitionTriggerVariable = state.parentRegion.parentState.createVariable(
                        GENERATED_PREFIX + "trig").setTypeBool.uniqueName(nameCache)
                    state.createEntryAction.addEffect(transitionTriggerVariable.createAssignment(FALSE))
                    transitionTriggerVariableMapping.put(transition, transitionTriggerVariable)
                    if (transition.isStrongAbort) {
                        strongAbortTrigger = strongAbortTrigger.or(transitionTriggerVariable.reference)
                        strongImmediateTrigger = strongImmediateTrigger || transition.implicitlyImmediate
                    } else if (transition.isWeakAbort) {
                        weakAbortTrigger = weakAbortTrigger.or(transitionTriggerVariable.reference)
                    }
                }

                var Expression terminationTrigger;

                // Decides whether a _TERM signal and the necessary _Run, _Done state is needed
                // OPTIMIZATION
                val terminationHandlingNeeded = !outgoingTransitions.filter[ isTermination ].nullOrEmpty

                // For each region encapsulate it into a _Main state and add a _Term variable
                // also to the terminationTrigger
                for (region : regions) {
                    if (terminationHandlingNeeded) {
                        val mainRegion = state.createControlflowRegion(GENERATED_PREFIX + "Main").uniqueName(nameCache)
                        val mainState = mainRegion.createInitialState(GENERATED_PREFIX + "Main").
                            uniqueName(nameCache)
                        mainState.regions.add(region)
                        val termState = mainRegion.createFinalState(GENERATED_PREFIX + "Term").
                            uniqueName(nameCache)
                        val termVariable = state.createVariable(GENERATED_PREFIX + "termRegion").setTypeBool.
                            uniqueName(nameCache)
                        mainState.createTransitionTo(termState).setTypeTermination.addEffect(termVariable.createAssignment(TRUE))
                        if (terminationTrigger != null) {
                            terminationTrigger = terminationTrigger.and(termVariable.reference)
                        } else {
                            terminationTrigger = termVariable.reference
                        }
                        state.createEntryAction.addEffect(termVariable.createAssignment(FALSE))
                    }

                    // Inside every region create a _Aborted
                    val abortedState = region.getOrCreateSimpleFinalState(GENERATED_PREFIX + "Aborted").
                        uniqueName(nameCache)
                    for (innerState : region.states.filter[!final && !isConnector]) {
                        if (innerState != abortedState) {
                            if (strongAbortTrigger != null) {
                                val strongAbort = innerState.createTransitionTo(abortedState, 0)
                                if (innerState.controlflowRegionsContainStates || innerState.containsInnerActions) {

                                    // HERE DIFFERENCE TO ABORT2()
                                    // We mark the transition as strong abort and handle
                                    // it later when transforming this hierarchical state.
                                    // This leads to more variables but avoids more transitions.
                                    strongAbort.setTypeStrongAbort

                                // END OF DIFFERENCE
                                }
                                strongAbort.setHighestPriority
                                strongAbort.setTrigger(strongAbortTrigger.copy)
                                strongAbort.setImmediate(strongImmediateTrigger)
                            }
                            if (weakAbortTrigger != null) {

                                // The following line is responsible for KISEMA 925 to fail                                 
                                //                                val weakAbort = innerState.createTransitionTo(abortedState) 
                                //                                val weakAbort = innerState.createTransitionTo(abortedState, 0)
                                val weakAbort = innerState.createTransitionTo(abortedState)
                                weakAbort.setTrigger(weakAbortTrigger.copy)
                                weakAbort.setLowestPriority;

                                // The following comment seems obsolete
                                // ?MUST be immediate: Otherwise new aborting transition may never be
                                // ?taken (e.g., in cyclic behavior like during actions)
                                weakAbort.setImmediate(weakImmediateTrigger);
                            }
                        }
                    }
                }

                if (terminationTrigger == null) {
                    terminationTrigger = TRUE;
                }

                for (transition : outgoingTransitions) {

                    // Get the _transitionTrigger that was created earlier
                    val transitionTriggerVariable = transitionTriggerVariableMapping.get(transition)

                    // Create a ctrlTransition in the ctrlRegion
                    val ctrlTransition = runState.createTransitionTo(doneState)
                    ctrlTransition.setLowestPriority
                    if (transition.implicitlyImmediate) {

                        // if the transition was immediate then set the ctrl transition to be immediate
                        ctrlTransition.setImmediate(true)
                    }

                    if (transition.isTermination) {
                        if (transition.trigger != null) {
                            ctrlTransition.setTrigger(terminationTrigger.copy.and(transition.trigger))
                        } else {
                            ctrlTransition.setTrigger(terminationTrigger.copy)
                        }
                    } else {
                        ctrlTransition.setTrigger(transition.trigger)
                    }

                    ctrlTransition.addEffect(transitionTriggerVariable.createAssignment(TRUE))
                }

            }

            // Create a single outgoing normal termination to a new connector state
            val outgoingConnectorState = state.parentRegion.createState(GENERATED_PREFIX + "C").
                uniqueName(nameCache).setTypeConnector
            state.createTransitionTo(outgoingConnectorState).setTypeTermination

            // Be careful to NOT create a trigger for the LAST (lowest priorized) outgoing transition from a connector, this must
            // be the DEFAULT transition that has NO trigger ***
            val defaultTransition = outgoingTransitions.last

            for (transition : outgoingTransitions) {

                // Modify the outgoing transition
                transition.setSourceState(outgoingConnectorState)

                if (transition != defaultTransition) {

                    // Get the _transitionTrigger that was created earlier
                    val transitionTriggerVariable = transitionTriggerVariableMapping.get(transition)
                    if (transitionTriggerVariable != null) {
                        transition.setTrigger(transitionTriggerVariable.reference)
                    } else {

                        // Fall back to this case when we did not create a trigger variable
                        // because there where NO strong or weak aborts but one or more triggered
                        // normal termination transitions.
                        transition.setTrigger(transition.trigger)
                    }
                }

                transition.setTypeWeakAbort
            }

            // OPTIMIZATION
            // if the connector has to just one outgoing transition, erase it
            if (outgoingConnectorState.outgoingTransitions.size == 1) {
                val transition = outgoingConnectorState.outgoingTransitions.get(0)
                transition.setImmediate(true)
                transition.setTypeTermination
                transition.setTrigger(null)
                val transitionToDelete = outgoingConnectorState.incomingTransitions.get(0)
                state.outgoingTransitions.remove(transitionToDelete)
                state.outgoingTransitions.add(transition)
                state.parentRegion.states.remove(outgoingConnectorState)
            }

        }

    }
    
    def SCCharts transform(SCCharts sccharts) {
        sccharts => [ rootStates.forEach[ transform ] ]
    }
}
