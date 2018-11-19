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
import de.cau.cs.kieler.sccharts.featuregroups.SCChartsFeatureGroup
import de.cau.cs.kieler.sccharts.features.SCChartsFeature
import static extension de.cau.cs.kieler.kicool.kitt.tracing.TransformationTracing.*import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.sccharts.extensions.SCChartsScopeExtensions

/**
 * SCCharts InputOutputVariable Transformation.
 * 
 * @author cmot
 * @kieler.design 2013-09-05 proposed 
 * @kieler.rating 2013-09-05 proposed yellow
 */
class InputOutputVariable extends SCChartsProcessor implements Traceable {

    //-------------------------------------------------------------------------
    //--                 K I C O      C O N F I G U R A T I O N              --
    //-------------------------------------------------------------------------
    override getId() {
        "de.cau.cs.kieler.sccharts.processors.iovariable"
    }
    
    override getName() {
        "IO Variable"
    }
 
    override process() {
        setModel(model.transform)
    }


//    override getExpandsFeatureId() {
//        return SCChartsFeature::INPUTOUTPUT_ID
//    }
//
//    override getProducesFeatureIds() {
//        // TODO: Check
//        return Sets.newHashSet()
//    }
//
//    override getNotHandlesFeatureIds() {
//        // TODO: Check
//        return Sets.newHashSet(SCChartsFeatureGroup::EXPANSION_ID)
//    }

    //-------------------------------------------------------------------------
    @Inject extension SCChartsScopeExtensions    

    //-------------------------------------------------------------------------
    //--          I N P U T   O U T P U T   V A R I A B L E                  --
    //-------------------------------------------------------------------------
    // ...
    def State transform(State rootState) {
        // Traverse all states
        for (targetTransition : rootState.getAllStates.toList) {
            targetTransition.transformInputOutputVariable(rootState);
        }
        rootState
    }

    def void transformInputOutputVariable(State state, State targetRootState) {
        state.setDefaultTrace
        //TODO: Implement this transformation
    }

    def SCCharts transform(SCCharts sccharts) {
        sccharts => [ rootStates.forEach[ transform ] ]
    }

}
