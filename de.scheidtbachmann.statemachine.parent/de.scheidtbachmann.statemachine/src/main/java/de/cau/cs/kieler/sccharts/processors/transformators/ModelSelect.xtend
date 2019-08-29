/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://rtsys.informatik.uni-kiel.de/kieler
 * 
 * Copyright ${year} by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 */
package de.cau.cs.kieler.sccharts.processors.transformators

import de.cau.cs.kieler.core.model.properties.IProperty
import de.cau.cs.kieler.core.model.properties.Property

/**
 * @author Wechselberg
 *
 */
class ModelSelect extends de.cau.cs.kieler.sccharts.processors.SCChartsProcessor {
    
    public static val IProperty<String> SELECTED_MODEL =
       new Property<String>("de.cau.cs.kieler.sccharts.modelselect.name", "")
    
    override getId() {
        "de.cau.cs.kieler.sccharts.processors.modelselect"
    }
    
    override getName() {
        "Model Selector"
    }
    
    override process() {
        if (!environment.getProperty(SELECTED_MODEL).nullOrEmpty) {
            val allowedModels = environment.getProperty(SELECTED_MODEL).split(",");
            val model = getModel()
            model.rootStates.removeIf[root | !allowedModels.exists[allowed | allowed.equals(root.name)]]
        }
    }
}
