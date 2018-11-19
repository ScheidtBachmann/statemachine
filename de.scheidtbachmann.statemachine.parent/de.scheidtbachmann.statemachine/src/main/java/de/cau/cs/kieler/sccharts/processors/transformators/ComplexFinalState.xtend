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
import de.cau.cs.kieler.kexpressions.ValuedObject
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsComplexCreateExtensions
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsCreateExtensions
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsDeclarationExtensions
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsValuedObjectExtensions
import de.cau.cs.kieler.kicool.compilation.ProcessorType
import de.cau.cs.kieler.sccharts.processors.SCChartsProcessor
import de.cau.cs.kieler.kicool.kitt.tracing.Traceable
import de.cau.cs.kieler.sccharts.ControlflowRegion
import de.cau.cs.kieler.sccharts.Region
import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.sccharts.State
import de.cau.cs.kieler.sccharts.extensions.SCChartsActionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsControlflowRegionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsScopeExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsStateExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsTransitionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsUniqueNameExtensions
import de.cau.cs.kieler.sccharts.featuregroups.SCChartsFeatureGroup
import de.cau.cs.kieler.sccharts.features.SCChartsFeature
import java.util.ArrayList

import static extension de.cau.cs.kieler.kicool.kitt.tracing.TransformationTracing.*
import de.cau.cs.kieler.annotations.extensions.UniqueNameCache
import de.cau.cs.kieler.kexpressions.kext.extensions.KExtDeclarationExtensions
import de.cau.cs.kieler.kexpressions.keffects.extensions.KEffectsExtensions

/**
 * SCCharts ComplexFinalState Transformation.
 * 
 * @author cmot
 * @kieler.design 2013-09-05 proposed 
 * @kieler.rating 2013-09-05 proposed yellow
 */
class ComplexFinalState extends SCChartsProcessor implements Traceable {

    // -------------------------------------------------------------------------
    // --                 K I C O      C O N F I G U R A T I O N              --
    // -------------------------------------------------------------------------
    override getId() {
        "de.cau.cs.kieler.sccharts.processors.complexFinalState"
    }
    
    override getName() {
        "Complex Final State"
    }

    override process() {
        setModel(model.transform)
    }


//    override getExpandsFeatureId() {
//        return SCChartsFeature::COMPLEXFINALSTATE_ID
//    }
//
//    override getProducesFeatureIds() {
//        return Sets.newHashSet(SCChartsFeature::ABORT_ID, SCChartsFeature::INITIALIZATION_ID)
//    }
//
//    override getNotHandlesFeatureIds() {
//        return Sets.newHashSet(SCChartsFeature::HISTORY_ID, SCChartsFeatureGroup::EXPANSION_ID)
//    }

    // -------------------------------------------------------------------------
    @Inject extension KExpressionsCreateExtensions
    @Inject extension KExpressionsComplexCreateExtensions
    @Inject extension KExpressionsDeclarationExtensions
    @Inject extension KExpressionsValuedObjectExtensions
    @Inject extension KEffectsExtensions
    @Inject extension KExtDeclarationExtensions
    @Inject extension SCChartsScopeExtensions
    @Inject extension SCChartsControlflowRegionExtensions
    @Inject extension SCChartsStateExtensions
    @Inject extension SCChartsActionExtensions
    @Inject extension SCChartsTransitionExtensions
    @Inject extension SCChartsUniqueNameExtensions

    // This prefix is used for naming of all generated signals, states and regions
    static public final String GENERATED_PREFIX = "_CFS"
    
    private val nameCache = new UniqueNameCache

    // -------------------------------------------------------------------------
    // --              C O M P L E X   F I N A L   S T A T E                  --
    // -------------------------------------------------------------------------
    //
    // PRODUCES: ABORTS
    //
    // ...
    // Optimizations: 
    // (1)   In transitions from one ComplexFinalState (CFS) to another CFS
    // optimize: Do not set term to false and to true again later
    // (-> .filter[!complexFinalStates.contains(sourceState)])
    // ATTENTION: if using this optimization make sure that if there is a
    // final&INITIAL-state, the term-variable is initialized with TRUE!!! (not FALSE as usual) ***
    // (2)   Share a unique final state if possible (-> retrieveFinalState())
    // (3)   If just one regions: No watcher region is needed, no abort signal and
    // only a single term signal 
    // (TODO)                
    def State transform(State rootState) {
        nameCache.clear
        // Traverse all parent states that contain at least one region that directly contains a complex final state                    
        val parentSatesContainingComplexFinalStates = rootState.allStates.filter [
            isParentContainingComplexFinalState
        ]
        for (targetParentState : parentSatesContainingComplexFinalStates.toList) {
            // val parentState = targetRegion.parentState
            targetParentState.transformComplexFinalState(rootState);
        }
        rootState
    }

    // Tells if a  state is a parent states that contain at least one region which directly contains a complex final state (or more)
    def boolean isParentContainingComplexFinalState(State state) {
        state.regions.filter[containsComplexFinalState].size > 0
    }

    // Tells if a region directly contains a complex final state (or more)
    def boolean containsComplexFinalState(Region region) {
        if (region instanceof ControlflowRegion) {
            return (region as ControlflowRegion).states.filter[isComplexFinalState].size > 0
        }
        return false
    }

    // Tells if a state is a complex final state, i.e., it is final and has either inner actions (during/exit) or outgoing transitions
    def boolean isComplexFinalState(State state) {
        state.isFinal &&
            ((!state.outgoingTransitions.nullOrEmpty) || state.duringActions.size > 0 || state.exitActions.size > 0 || (state.allContainedStates.size > 0))
    }

    def void transformComplexFinalState(State parentState, State rootState) {
        parentState.setDefaultTrace
        var ArrayList<ValuedObject> termVariables = new ArrayList
        
        var state = parentState
        
        // If there are regions that cannot terminate, then we do not need to transform something
        if (!state.regionsMayTerminate) {
           return;
        }
        
        // If the parent state is the root state then make an explicit termination transition
        if (parentState.isRootState) {
            rootState.setDefaultTrace
            val r = parentState.createControlflowRegion(GENERATED_PREFIX + "Main").uniqueName(nameCache)
            val i = r.createInitialState(GENERATED_PREFIX + "I").uniqueName(nameCache)
            val f = r.createFinalState(GENERATED_PREFIX + "F").uniqueName(nameCache)
            for (mainRegion : parentState.regions.filter(e|e != r).toList.immutableCopy) {
                    i.regions.add(mainRegion)
            }
            i.createImmediateTransitionTo(f).setTypeTermination
            state = i;
        }
         
        // For every region in such a parent state, we need to track if it finishes
        for (region : state.regions.filter(ControlflowRegion)) {
            val allStatesFinal = region.states.size == region.states.filter[isFinal].size

            // Use this new term variable to track final states of this region
            val finalStates = region.states.filter[final && (incomingTransitions.size > 0 || initial)]
            finalStates.setDefaultTrace

            if (!allStatesFinal) {
                val termVariable = state.parentRegion.parentState.createValuedObject(GENERATED_PREFIX + "term", createBoolDeclaration).
                    uniqueName(nameCache)
                state.createEntryAction.addAssignment(termVariable.createAssignment(FALSE))    
                //termVariable.setInitialValue(FALSE)
                if (region.initialState.final) {
                    termVariable.setInitialValue(TRUE)
                }
                termVariables.add(termVariable)

                for (finalState : finalStates) {
                    for (transition : finalState.incomingTransitions.filter[!sourceState.isFinal]) {
                        transition.addEffect(termVariable.createAssignment(TRUE))
                    }
                    for (transition : finalState.outgoingTransitions.filter[!targetState.isFinal]) {
                        transition.addEffect(termVariable.createAssignment(FALSE))
                    }
                }
            }

            for (finalState : finalStates) {
                if (finalState.complexFinalState) {
                    finalState.final = false
                }
            }
        }

        // Modify all termination transitions by weak aborts
        for (termination : state.outgoingTransitions.filter[ isTermination ].toList) {
            termination.setTypeWeakAbort

            for (termVariable : termVariables) {
                termination.setTrigger(termination.trigger.and(termVariable.reference))
            }
        }
    }


    def SCCharts transform(SCCharts sccharts) {
        sccharts => [ rootStates.forEach[ transform ] ]
    }

}
