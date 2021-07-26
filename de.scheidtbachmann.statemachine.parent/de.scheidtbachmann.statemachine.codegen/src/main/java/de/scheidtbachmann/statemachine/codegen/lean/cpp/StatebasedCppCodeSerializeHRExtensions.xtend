// ******************************************************************************
//
// Copyright (c) 2021 by
// Scheidt & Bachmann System Technik GmbH, 24109 Melsdorf
//
// This program and the accompanying materials are made available under the terms of the
// Eclipse Public License v2.0 which accompanies this distribution, and is available at
// https://www.eclipse.org/legal/epl-v20.html
//
// ******************************************************************************

package de.scheidtbachmann.statemachine.codegen.lean.cpp

import de.cau.cs.kieler.kexpressions.BoolValue
import de.cau.cs.kieler.kexpressions.ValueType
import de.cau.cs.kieler.kexpressions.keffects.PrintCallEffect
import de.cau.cs.kieler.sccharts.processors.statebased.codegen.StatebasedCCodeSerializeHRExtensions
import de.cau.cs.kieler.kexpressions.ValuedObject
import com.google.inject.Inject
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsValuedObjectExtensions

/**
 * Extension methods to serialize code for human-readable C++ code generation.
 */
class StatebasedCppCodeSerializeHRExtensions extends StatebasedCCodeSerializeHRExtensions {
    
    @Inject extension KExpressionsValuedObjectExtensions

    protected var CODE_ANNOTATION = "CPP"

    override dispatch CharSequence serialize(ValueType valueType) {
        switch (valueType) {
          case STRING: {
              modifications.put(INCLUDES, "<string>")
              return "std::string"
          }
          case FLOAT: return "double"
          default: return valueType.literal
        }
    }
    
    override dispatch CharSequence serialize(BoolValue expression) {
        return expression.value.toString
    }
    
    override dispatch CharSequence serializeHR(PrintCallEffect printCall) {
        var paramStr = printCall.parameters.serializeParameters.toString
        
        modifications.put(INCLUDES, "<iostream>")
        
        return "std::cout << " + paramStr.substring(1, paramStr.length - 1) + " << std::endl"
    }
    
    def CharSequence serializeInitialization(ValuedObject vo) {
        val value = switch (vo.type) {
            case BOOL: "false"
            case INT: "0"
            case STRING: '""'
            default: "0"
        }
        return '''« vo.name » = « value »;'''
    }
}
