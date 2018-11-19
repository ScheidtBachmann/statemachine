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
import de.cau.cs.kieler.kexpressions.VariableDeclaration
import com.google.inject.Inject
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsValuedObjectExtensions
import org.eclipse.xtend.lib.annotations.Accessors
import de.cau.cs.kieler.kexpressions.ValueType

/**
 * C Code Generator Struct Module
 * 
 * Handles the creation of the data struct.
 * 
 * @author ssm
 * @kieler.design 2017-07-21 proposed 
 * @kieler.rating 2017-07-21 proposed yellow 
 * 
 */
class CCodeGeneratorStructModule extends SCGCodeGeneratorModule {
    
    @Inject extension KExpressionsValuedObjectExtensions
    @Accessors @Inject CCodeSerializeHRExtensions serializer
    
    public static val STRUCT_NAME = "TickData"
    public static val STRUCT_VARIABLE_NAME = "d"
    public static val STRUCT_PRE_PREFIX = "_p"
    
    @Accessors StringBuilder forwardDeclarations = new StringBuilder
  
    override getName() {
        STRUCT_NAME + baseName + suffix
    }
    
    def getVariableName() {
        STRUCT_VARIABLE_NAME
    }
    
    def protected separator() {
        "->"
    }    
    
    override generateInit() {
        code.append("typedef struct {\n")
    }
    
    override generate() {
        generate(serializer)
    }
    
    protected def generate(extension CCodeSerializeHRExtensions serializer) {
        // Add the declarations of the model.
        for (declaration : scg.declarations) {
            for (valuedObject : declaration.valuedObjects) {
                if (declaration instanceof VariableDeclaration) {
                    val declarationType = if (declaration.type != ValueType.HOST || declaration.hostType.nullOrEmpty) 
                        declaration.type.serializeHR
                        else declaration.hostType
                    code.append(indentation + declarationType)
                    code.append(" ")
                    code.append(valuedObject.name)
                    if (valuedObject.isArray) {
                        for (cardinality : valuedObject.cardinalities) {
                            code.append("[" + cardinality.serializeHR + "]")
                        }
                    }
                    code.append(";\n")
                }
            }
        }
    }
    
    override generateDone() {
        code.append("} ").append(getName).append(";\n")
        
        if (forwardDeclarations.length > 0) code.append("\n")
        code.append(forwardDeclarations)
    }
    
}