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
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsValuedObjectExtensions
import de.cau.cs.kieler.kexpressions.kext.extensions.KExtDeclarationExtensions
import de.cau.cs.kieler.kicool.compilation.ProcessorType
import de.cau.cs.kieler.sccharts.processors.SCChartsProcessor
import de.cau.cs.kieler.kicool.kitt.tracing.Traceable
import de.cau.cs.kieler.sccharts.ControlflowRegion
import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.sccharts.Scope
import de.cau.cs.kieler.sccharts.State
import de.cau.cs.kieler.sccharts.extensions.SCChartsActionExtensions
import de.cau.cs.kieler.sccharts.extensions.SCChartsScopeExtensions
import de.cau.cs.kieler.sccharts.featuregroups.SCChartsFeatureGroup
import de.cau.cs.kieler.sccharts.features.SCChartsFeature

import static de.cau.cs.kieler.kicool.kitt.tracing.TransformationTracing.*

import static extension de.cau.cs.kieler.kicool.kitt.tracing.TracingEcoreUtil.*
import de.cau.cs.kieler.kexpressions.keffects.extensions.KEffectsExtensions

/**
 * SCCharts Initialization Transformation.
 * 
 * @author cmot ssm
 * @kieler.design 2013-09-05 proposed 
 * @kieler.rating 2013-09-05 proposed yellow
 */
class Initialization extends SCChartsProcessor implements Traceable {

    //-------------------------------------------------------------------------
    //--                 K I C O      C O N F I G U R A T I O N              --
    //-------------------------------------------------------------------------
    override getId() {
        "de.cau.cs.kieler.sccharts.processors.initialization"
    }
    
    override getName() {
        "Initialization"
    }
 
    override process() {
        setModel(model.transform)
    }


//    override getExpandsFeatureId() {
//        return SCChartsFeature::INITIALIZATION_ID
//    }
//
//    override getProducesFeatureIds() {
//        return Sets.newHashSet(SCChartsFeature::ENTRY_ID)
//    }
//
//    override getNotHandlesFeatureIds() {
//        return Sets.newHashSet(SCChartsFeatureGroup::EXPANSION_ID)
//    }

    //-------------------------------------------------------------------------
    @Inject extension KExpressionsValuedObjectExtensions    
    @Inject extension KEffectsExtensions
    @Inject extension KExtDeclarationExtensions
    @Inject extension SCChartsScopeExtensions
    @Inject extension SCChartsActionExtensions
    
    // This prefix is used for naming of all generated signals, states and regions
    static public final String GENERATED_PREFIX = "_"

    //-------------------------------------------------------------------------
    //--                       I N I T I A L I Z A T I O N                   --
    //-------------------------------------------------------------------------
    // @requires: entry actions
    // Transforming Variable Initializations
    def State transform(State rootState) {
        // Traverse all states
        for (scope : rootState.getAllScopes.toList) {
            scope.transformInitialization(rootState);
        }
        rootState
    }

    // Traverse all states and transform macro states that have actions to transform
    def void transformInitialization(Scope scope, State targetRootState) {
        for (valuedObject : scope.valuedObjects.filter[initialValue != null].toList.reverseView) {
            setDefaultTrace(valuedObject, valuedObject.declaration)
            
            // Initialization combined with existing entry action: The order in which new, 
            // additional initialization-entry actions are added matters for the semantics.
            // Initializations before part of the declaration. Entry actions afterwards. 
            // So the initialization-entry-actions should be ordered also before the other
            // entry actions to keep the original order. 
            if (scope instanceof State) {
                val entryAction = scope.createEntryAction(0)
                entryAction.addAssignment(valuedObject.createAssignment(valuedObject.initialValue.copy))
            } else if (scope instanceof ControlflowRegion) {
                val entryAction = scope.states.findFirst[initial].createEntryAction(0)
                entryAction.addAssignment(valuedObject.createAssignment(valuedObject.initialValue.copy))
            }
            valuedObject.setInitialValue(null)
        }
    }

    def SCCharts transform(SCCharts sccharts) {
        sccharts => [ rootStates.forEach[ transform ] ]
    }

}
