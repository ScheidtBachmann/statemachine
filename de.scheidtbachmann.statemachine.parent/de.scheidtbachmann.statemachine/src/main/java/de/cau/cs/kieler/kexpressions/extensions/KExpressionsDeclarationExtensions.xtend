/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2015 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.kexpressions.extensions

import de.cau.cs.kieler.kexpressions.Declaration
import de.cau.cs.kieler.kexpressions.KExpressionsFactory
import de.cau.cs.kieler.kexpressions.ValueType
import de.cau.cs.kieler.kexpressions.ValuedObject
import org.eclipse.emf.ecore.EObject
import java.util.List
import de.cau.cs.kieler.kexpressions.VariableDeclaration
import de.cau.cs.kieler.kexpressions.ReferenceDeclaration
import de.cau.cs.kieler.kexpressions.Value
import de.cau.cs.kieler.kexpressions.IntValue
import de.cau.cs.kieler.kexpressions.BoolValue
import de.cau.cs.kieler.kexpressions.StringValue
import de.cau.cs.kieler.kexpressions.FloatValue
import de.cau.cs.kieler.kexpressions.ExternString
import de.cau.cs.kieler.kexpressions.ScheduleDeclaration
import com.google.inject.Inject

/**
 * @author ssm
 * @kieler.design 2015-08-19 proposed 
 * @kieler.rating 2015-08-19 proposed yellow
 */
class KExpressionsDeclarationExtensions {
    
    @Inject
    extension EcoreUtilExtensions
    
    def dispatch Declaration createDeclaration(VariableDeclaration declaration) {
        declaration.createVariableDeclaration
    }
    
    def dispatch Declaration createDeclaration(ReferenceDeclaration declaration) {
        declaration.createReferenceDeclaration
    }
    
    def dispatch Declaration createDeclaration(ScheduleDeclaration declaration) {
        declaration.createScheduleDeclaration
    }
    
    /**
     * @deprecated
     */
    def VariableDeclaration createDeclaration() {
        createVariableDeclaration
    }   
    
    def VariableDeclaration createVariableDeclaration() {
        KExpressionsFactory::eINSTANCE.createVariableDeclaration
    }   
    
    def VariableDeclaration createVariableDeclaration(ValueType valueType) {
        KExpressionsFactory::eINSTANCE.createVariableDeclaration => [
            type = valueType
        ]
    }   
    
    
    def VariableDeclaration createSignalDeclaration() {
        val decl = createVariableDeclaration(ValueType::PURE)
        decl.signal = true
        decl
    }    
    
    def VariableDeclaration createIntDeclaration() {
        createVariableDeclaration(ValueType::INT)
    }    

    def VariableDeclaration createBoolDeclaration() {
        createVariableDeclaration(ValueType::BOOL)
    }    

    def VariableDeclaration createDoubleDeclaration() {
        createVariableDeclaration(ValueType::DOUBLE)
    }    

    def VariableDeclaration createStringDeclaration() {
        createVariableDeclaration(ValueType::STRING)
    }    
    
    def VariableDeclaration createVariableDeclaration(VariableDeclaration declaration) {
        (createVariableDeclaration as VariableDeclaration) => [
            type = declaration.type
            input = declaration.input
            output = declaration.output
            signal = declaration.signal
            static = declaration.static
            const = declaration.const
            extern = declaration.extern
            volatile = declaration.volatile
            hostType = declaration.hostType
        ]
    } 
    
    def dispatch Declaration createDeclaration(Value value) {
        if (value instanceof IntValue) createIntDeclaration
        else if (value instanceof BoolValue) createBoolDeclaration
        else if (value instanceof FloatValue) createDoubleDeclaration
        else if (value instanceof StringValue) createStringDeclaration
        else createDeclaration
    }
    
    def VariableDeclaration applyAttributes(VariableDeclaration declaration, VariableDeclaration declarationWithAttributes) {
        declaration => [
            input = declarationWithAttributes.input
            output = declarationWithAttributes.output
            static = declarationWithAttributes.static
            const = declarationWithAttributes.const
            extern = declarationWithAttributes.extern
            type = declarationWithAttributes.type
        ]
    }
    
    def ReferenceDeclaration createReferenceDeclaration() {
        KExpressionsFactory::eINSTANCE.createReferenceDeclaration
    } 
    
    def ReferenceDeclaration createReferenceDeclaration(ReferenceDeclaration declaration) {
        (createReferenceDeclaration as ReferenceDeclaration) => [ d |
            d.reference = declaration.reference
            declaration.extern.forEach[
                d.extern += it.createExternString
            ]
        ]
    }
    
    def createExternString(String code) {
        KExpressionsFactory.eINSTANCE.createExternString => [
            it.code = code
        ]
    }
    
    def createExternString(ExternString externString) {
        createExternString(externString.code) => [ e |
            externString.annotations.forEach[
                e.annotations += it.copy
            ]
        ]
    }
    
    def ScheduleDeclaration createScheduleDeclaration() {
        KExpressionsFactory::eINSTANCE.createScheduleDeclaration
    }
    
    def ScheduleDeclaration createScheduleDeclaration(ScheduleDeclaration declaration) {
        createScheduleDeclaration => [ d |
            d.name = declaration.name
            d.global = declaration.global
            declaration.priorities.forEach[
                d.priorities.add(it)
            ]            
        ]
    }
        
        
    def void delete(Declaration declaration) {
        declaration.valuedObjects.immutableCopy.forEach[ remove ]
        declaration.remove
    }
    
    def List<Declaration> copyDeclarations(EObject source) {
        <Declaration> newArrayList => [ targetList | 
            for (declaration : source.eContents.filter(typeof(Declaration))) {
                // @als: is this trace necessary?
                targetList += createDeclaration(declaration) => [ newDec |
                    declaration.valuedObjects.forEach[ _copyValuedObject(newDec) ]
                ]
            }
        ]
    }
    
    private def void _copyValuedObject(ValuedObject sourceObject, Declaration targetDeclaration) {
        val newValuedObject = sourceObject.copy
        targetDeclaration.valuedObjects += newValuedObject
    }            
    
    
    def List<VariableDeclaration> getVariableDeclarations(EObject eObject) {
        <VariableDeclaration> newArrayList => [ list |
            eObject.eContents.filter(VariableDeclaration).forEach[ list += it ]
        ]
    }  
    
    def List<ReferenceDeclaration> getReferenceDeclarations(EObject eObject) {
        <ReferenceDeclaration> newArrayList => [ list |
            eObject.eContents.filter(ReferenceDeclaration).forEach[ list += it ]
        ]
    }   
    
//    def ReferenceDeclaration getReferenceDeclaration(ValuedObject valuedObject) {
//        valuedObject.eContainer as ReferenceDeclaration
//    }   
 
    def Declaration checkAndCleanup(Declaration declaration) {
        if (declaration.valuedObjects.nullOrEmpty) { 
            declaration.remove
        }
        declaration
    } 
    
}