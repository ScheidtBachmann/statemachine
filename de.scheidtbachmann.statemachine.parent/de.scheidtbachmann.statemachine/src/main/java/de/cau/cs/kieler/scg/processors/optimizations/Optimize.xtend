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
package de.cau.cs.kieler.scg.processors.optimizations

import de.cau.cs.kieler.scg.processors.SCGProcessors

/**
 * Deletes conditionals with constant value, unreachable nodes until all eliminated.
 * Resolves unused variables to constants
 * 
 * @author krat ssm 
 * @kieler.design 2015-05-25 proposed 
 * @kieler.rating 2015-05-25 proposed yellow
 *
 */
class Optimize {
    
    def getId() {
        return "scg.optimizations.esterel.all"
    }
    
    def getName() {
        return "Esterel Optimizations"
    }
    
    def getProcessorOptions() {
//        <ProcessorOption>newArrayList => [
//            it += new ProcessorOption(SCGProcessors.REPLACEUNUSEDVARIABLES_ID)
//            it += new ProcessorOption(SCGProcessors.CONSTANTCONDITIONALS_ID)
//            it += new ProcessorOption(SCGProcessors.UNREACHABLENODES_ID)
//        ]
    }
    
    def isInplace() {
        true
    }
    
}