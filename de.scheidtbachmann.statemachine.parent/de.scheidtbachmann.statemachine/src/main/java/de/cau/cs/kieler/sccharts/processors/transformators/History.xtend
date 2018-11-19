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

import com.google.common.collect.ImmutableList
import com.google.common.collect.Sets
import com.google.inject.Inject
import de.cau.cs.kieler.kicool.compilation.ProcessorType
import de.cau.cs.kieler.sccharts.processors.SCChartsProcessor
import de.cau.cs.kieler.kicool.kitt.tracing.Traceable
import de.cau.cs.kieler.sccharts.ControlflowRegion
import de.cau.cs.kieler.sccharts.HistoryType
import de.cau.cs.kieler.sccharts.State
import de.cau.cs.kieler.sccharts.featuregroups.SCChartsFeatureGroup
import de.cau.cs.kieler.sccharts.features.SCChartsFeature
import java.util.ArrayList
import java.util.List

import static extension de.cau.cs.kieler.kicool.kitt.tracing.TransformationTracing.*import de.cau.cs.kieler.kexpressions.extensions.KExpressionsCreateExtensions
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsDeclarationExtensions
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsValuedObjectExtensions
import de.cau.cs.kieler.kexpressions.ValuedObject
import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.sccharts.extensions.SCChartsScopeExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsTransitionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsActionExtensions
import de.cau.cs.kieler.kexpressions.kext.extensions.KExtDeclarationExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsUniqueNameExtensions
import de.cau.cs.kieler.annotations.extensions.UniqueNameCache
import de.cau.cs.kieler.sccharts.extensions.SCChartsStateExtensions
import de.cau.cs.kieler.kexpressions.keffects.extensions.KEffectsExtensions

/**
 * SCCharts History Transformation.
 * 
 * @author cmot
 * @kieler.design 2013-09-05 proposed 
 * @kieler.rating 2013-09-05 proposed yellow
 */
class History extends SCChartsProcessor implements Traceable {

    //-------------------------------------------------------------------------
    //--                 K I C O      C O N F I G U R A T I O N              --
    //-------------------------------------------------------------------------
    override getId() {
        "de.cau.cs.kieler.sccharts.processors.history"
    }
    
    override getName() {
        "History"
    }

    override process() {
        setModel(model.transform)
    }


//    override getExpandsFeatureId() {
//        return SCChartsFeature::HISTORY_ID
//    }
//
//    override getProducesFeatureIds() {
//        return Sets.newHashSet(SCChartsFeature::STATIC_ID, SCChartsFeature::INITIALIZATION_ID, SCChartsFeature::ENTRY_ID)
//    }
//
//    override getNotHandlesFeatureIds() {
//        return Sets.newHashSet(SCChartsFeatureGroup::EXPANSION_ID)
//    }

    //-------------------------------------------------------------------------
    @Inject extension KExpressionsCreateExtensions
    @Inject extension KExpressionsDeclarationExtensions
    @Inject extension KExpressionsValuedObjectExtensions    
    @Inject extension KEffectsExtensions
    @Inject extension KExtDeclarationExtensions
    @Inject extension SCChartsScopeExtensions
    @Inject extension SCChartsStateExtensions
    @Inject extension SCChartsActionExtensions
    @Inject extension SCChartsTransitionExtensions
    @Inject extension SCChartsUniqueNameExtensions

    private val nameCache = new UniqueNameCache

    // This prefix is used for naming of all generated signals, states and regions
    static public final String GENERATED_PREFIX = "_H"

    //-------------------------------------------------------------------------
    //--                        H I S T O R Y                                --
    //-------------------------------------------------------------------------
    // @requires: suspend
    // Transforming History. This is using the concept of suspend so it must
    // be followed by resolving suspension
    def State transform(State rootState) {
        nameCache.clear
        // Traverse all states
        rootState.getAllStates.toList.forEach [ targetState |
            targetState.transformHistory(rootState)
        ]
        rootState
    }

    // Traverse all states and transform macro states that have connecting
    // (incoming) history transitions.    
    def void transformHistory(State state, State targetRootState) {
        state.setDefaultTrace        
        
        val historyTransitions = ImmutableList::copyOf(state.incomingTransitions.filter[isHistory])
        val nonHistoryTransitions = ImmutableList::copyOf(state.incomingTransitions.filter[!isHistory])
        historyTransitions.setDefaultTrace

        if (historyTransitions != null && historyTransitions.size > 0 && state.regions != null && state.regions.size > 0) {
            var int initialValue
            val List<ValuedObject> stateEnumsAll = new ArrayList
            val List<ValuedObject> stateEnumsDeep = new ArrayList

            val regions = state.regions.filter(ControlflowRegion).toList
            var regionsDeep = state.regions.filter(ControlflowRegion).toList 
            if (historyTransitions.findFirst[isDeepHistory] != null) { // if state has any deep history transition
                regionsDeep = state.allContainedControlflowRegions.toList
            }

            for (region : regionsDeep.toList) {
                var counter = 0

                // FIXME: stateEnum should be static
                val stateEnum = state.parentRegion.parentState.createValuedObject(GENERATED_PREFIX + state.name, createIntDeclaration).
                    uniqueName(nameCache)
                stateEnumsAll.add(stateEnum)
                if (!regions.contains(region)) {
                    stateEnumsDeep.add(stateEnum)
                }
                val originalInitialState = region.initialState
                originalInitialState.setNotInitial
                val subStates = region.states.immutableCopy
                val initialState = region.createInitialState(GENERATED_PREFIX + "Init").uniqueName(nameCache)

                for (subState : subStates) {
                    val transition = initialState.createImmediateTransitionTo(subState)
                    transition.setTrigger(stateEnum.reference.createEQExpression(counter.createIntValue))
                    subState.createEntryAction.addEffect(stateEnum.createAssignment(counter.createIntValue))
                    if (subState == originalInitialState) {
                        initialValue = counter
                        stateEnum.setInitialValue(counter.createIntValue)
                    }
                    counter = counter + 1
                }
            }

            for (transition : historyTransitions) {
                if (!transition.deepHistory) {

                    // Reset deepStateEnums
                    for (stateEnum : stateEnumsDeep) {
                        transition.addEffect(stateEnum.createAssignment(initialValue.createIntValue)).trace(transition)
                    }
                }
                transition.setHistory(HistoryType::RESET)
            }

            for (transition : nonHistoryTransitions) {
                for (stateEnum : stateEnumsAll) {
                    transition.addEffect(stateEnum.createAssignment(initialValue.createIntValue))
                }
            }

        }
    }

    def SCCharts transform(SCCharts sccharts) {
        sccharts => [ rootStates.forEach[ transform ] ]
    }

}
