/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://rtsys.informatik.uni-kiel.de/kieler
 * 
 * Copyright 2017 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 */
package de.cau.cs.kieler.scg.processors.transformators.codegen.c

import de.cau.cs.kieler.scg.codegen.SCGCodeGeneratorModule
import de.cau.cs.kieler.scg.transformations.guardExpressions.AbstractGuardExpressions
import de.cau.cs.kieler.scg.transformations.guards.AbstractGuardTransformation
import com.google.inject.Inject

/**
 * C Code Generator Reset Module
 * 
 * Handles the creation of the reset function.
 * 
 * @author ssm
 * @kieler.design 2017-07-24 proposed 
 * @kieler.rating 2017-07-24 proposed yellow 
 * 
 */
class CCodeGeneratorResetModule extends SCGCodeGeneratorModule {
    
    static val RESET_NAME = "reset"
    
    @Inject CCodeGeneratorStructModule struct
    
    override configure() {
        struct = (parent as CCodeGeneratorModule).struct as CCodeGeneratorStructModule
    }    
    
    override getName() {
        RESET_NAME + baseName + suffix
    }
    
    override generateInit() {
        code.append("void ").append(getName)
        code.append("(")
        code.append(struct.getName).append("* ").append(struct.getVariableName)
        code.append(")")
        
        struct.forwardDeclarations.append(code).append(";\n")
        
        code.append(" {\n")
        
        indent 
        code.append(struct.getVariableName).append("->").append(AbstractGuardExpressions.GO_GUARD_NAME).append(" = 1;\n")
        indent
        code.append(struct.getVariableName).append("->").append(AbstractGuardTransformation.TERM_GUARD_NAME).append(" = 0;\n")
    }
    
    override generate() {
    }
    
    override generateDone() {
        code.append("}\n")
    }
    
}