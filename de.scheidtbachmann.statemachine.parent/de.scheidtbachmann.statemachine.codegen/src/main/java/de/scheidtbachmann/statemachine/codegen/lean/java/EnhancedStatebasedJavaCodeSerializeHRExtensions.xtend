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

package de.scheidtbachmann.statemachine.codegen.lean.java

import com.google.inject.Inject
import de.cau.cs.kieler.annotations.extensions.AnnotationsExtensions
import de.cau.cs.kieler.kexpressions.ReferenceCall
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsValuedObjectExtensions
import de.cau.cs.kieler.kexpressions.keffects.ReferenceCallEffect
import de.cau.cs.kieler.sccharts.processors.statebased.codegen.java.StatebasedJavaCodeSerializeHRExtensions

/**
 * Enhanced version of {@code StatebasedJavaCodeSerializeHRExtensions} to support external 
 * interface for {@code ReferenceCall}s.
 * 
 * @author wechselberg
 */
class EnhancedStatebasedJavaCodeSerializeHRExtensions extends StatebasedJavaCodeSerializeHRExtensions {
    
    @Inject extension AnnotationsExtensions
    @Inject extension KExpressionsValuedObjectExtensions
      
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