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
package de.cau.cs.kieler.sccharts.processors.statebased.codegen.java

import de.cau.cs.kieler.kexpressions.BoolValue
import de.cau.cs.kieler.kexpressions.PrintCall
import de.cau.cs.kieler.kexpressions.RandomCall
import de.cau.cs.kieler.kexpressions.RandomizeCall
import de.cau.cs.kieler.kexpressions.ValueType
import de.cau.cs.kieler.sccharts.processors.statebased.codegen.StatebasedCCodeSerializeHRExtensions
import de.cau.cs.kieler.kexpressions.keffects.PrintCallEffect
import de.cau.cs.kieler.annotations.extensions.AnnotationsExtensions
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsValuedObjectExtensions
import com.google.inject.Inject
import de.cau.cs.kieler.kexpressions.keffects.ReferenceCallEffect
import de.cau.cs.kieler.kexpressions.ReferenceCall

/**
 * @author wechselberg
 *
 */
class StatebasedJavaCodeSerializeHRExtensions extends StatebasedCCodeSerializeHRExtensions {
    
    @Inject extension AnnotationsExtensions
    @Inject extension KExpressionsValuedObjectExtensions
    
    public static val IMPORTS = "imports"
    public static val GLOBAL_OBJECTS = "globalObjects"
    
    new() {
        CODE_ANNOTATION = "Java"
    }
    
    override dispatch CharSequence serialize(ValueType valueType) {
        if (valueType == ValueType.BOOL) {
            return "boolean"
        } else if (valueType == ValueType.STRING) {
            return "String"
        } else if (valueType == ValueType.FLOAT) {
            return "double"
        } else {
            return valueType.literal
        }
    }
  
    override dispatch CharSequence serialize(BoolValue expression) {
        if (expression.value) return "true"
        return "false"
    }   

    override dispatch CharSequence serialize(PrintCall printCall) {
        var paramStr = printCall.parameters.serializeParameters.toString
        if (printCall.parameters.size == 1) {
            return "System.out.println(" + paramStr.substring(1, paramStr.length - 1) + ")" 
        } 
        
        return "System.out.format(" + paramStr.substring(1, paramStr.length - 1) + ")"
    }

    override dispatch CharSequence serializeHR(PrintCallEffect printCall) {
        var paramStr = printCall.parameters.serializeParameters.toString
        if (printCall.parameters.size == 1) {
            return "System.out.println(" + paramStr.substring(1, paramStr.length - 1) + ")" 
        } 
        
        return "System.out.format(" + paramStr.substring(1, paramStr.length - 1) + ")"
    }
    
    override dispatch CharSequence serialize(RandomCall randomCall) {
        modifications.put(GLOBAL_OBJECTS, "private static Random random = new Random(0);")
        modifications.put(IMPORTS, "java.util.Random")
        
        return "random.nextDouble()"
    }
    
    override dispatch CharSequence serializeHR(RandomCall randomCall) {
        modifications.put(GLOBAL_OBJECTS, "private static Random random = new Random(0);")
        modifications.put(IMPORTS, "java.util.Random")
        
        return "random.nextDouble()"
    }
    
    override dispatch CharSequence serialize(RandomizeCall randomizeCall) {
        modifications.put(GLOBAL_OBJECTS, "private static Random random = new Random(0);")
        modifications.put(IMPORTS, "java.util.Random")
            
        return "random.setSeed(System.currentTimeMillis())"
    }

    override dispatch CharSequence serializeHR(RandomizeCall randomizeCall) {
        modifications.put(GLOBAL_OBJECTS, "private static Random random = new Random(0);")
        modifications.put(IMPORTS, "java.util.Random")
            
        return "random.setSeed(System.currentTimeMillis())"
    }
    
    override dispatch CharSequence serialize(ReferenceCallEffect referenceCall) {
        val declaration = referenceCall.valuedObject.referenceDeclaration
        if (declaration.extern.nullOrEmpty) { 
            return referenceCall.valuedObject.serialize.toString + referenceCall.parameters.serializeParameters
        } else {
            val contextCall = if (declaration.annotations.exists['Context'.equalsIgnoreCase(name)]) {
                'externalContext.'
            } else {
                ''
            }
            var code = declaration.extern.head.code
            if (declaration.extern.exists[ hasAnnotation(codeAnnotation) ]) {
                code = declaration.extern.filter[ hasAnnotation(codeAnnotation) ].head.code
            }
            return contextCall + code + referenceCall.parameters.serializeParameters
        }
    }

    override dispatch CharSequence serializeHR(ReferenceCallEffect referenceCall) {
        val declaration = referenceCall.valuedObject.referenceDeclaration
        if (declaration.extern.nullOrEmpty) { 
            return referenceCall.valuedObject.serializeHR.toString + referenceCall.parameters.serializeHRParameters
        } else {
            val contextCall = if (declaration.annotations.exists['Context'.equalsIgnoreCase(name)]) {
                'externalContext.'
            } else {
                ''
            }
            var code = declaration.extern.head.code
            if (declaration.extern.exists[ hasAnnotation(codeAnnotation) ]) {
                code = declaration.extern.filter[ hasAnnotation(codeAnnotation) ].head.code
            }
            return contextCall + code + referenceCall.parameters.serializeHRParameters
        }
    }

    override dispatch CharSequence serialize(ReferenceCall referenceCall) {
        val declaration = referenceCall.valuedObject.referenceDeclaration
        if (declaration.extern.nullOrEmpty) { 
            return referenceCall.valuedObject.serialize.toString + referenceCall.parameters.serializeParameters
        } else {
            val contextCall = if (declaration.annotations.exists['Context'.equalsIgnoreCase(name)]) {
                'externalContext.'
            } else {
                ''
            }
            var code = declaration.extern.head.code
            if (declaration.extern.exists[ hasAnnotation(codeAnnotation) ]) {
                code = declaration.extern.filter[ hasAnnotation(codeAnnotation) ].head.code
            }
            return contextCall + code + referenceCall.parameters.serializeParameters
        }
    }

    override dispatch CharSequence serializeHR(ReferenceCall referenceCall) {
        val declaration = referenceCall.valuedObject.referenceDeclaration
        if (declaration.extern.nullOrEmpty) { 
            return referenceCall.valuedObject.serializeHR.toString + referenceCall.parameters.serializeHRParameters
        } else {
            val contextCall = if (declaration.annotations.exists['Context'.equalsIgnoreCase(name)]) {
                'externalContext.'
            } else {
                ''
            }
            var code = declaration.extern.head.code
            if (declaration.extern.exists[ hasAnnotation(codeAnnotation) ]) {
                code = declaration.extern.filter[ hasAnnotation(codeAnnotation) ].head.code
            }
            return contextCall + code + referenceCall.parameters.serializeHRParameters
        }
    }    
}
