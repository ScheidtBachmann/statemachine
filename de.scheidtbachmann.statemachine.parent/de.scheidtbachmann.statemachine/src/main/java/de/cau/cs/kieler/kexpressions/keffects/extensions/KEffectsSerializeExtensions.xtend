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
package de.cau.cs.kieler.kexpressions.keffects.extensions

import de.cau.cs.kieler.kexpressions.ValueType
import de.cau.cs.kieler.kexpressions.VariableDeclaration
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsSerializeHRExtensions
import de.cau.cs.kieler.kexpressions.keffects.AssignOperator
import de.cau.cs.kieler.kexpressions.keffects.Assignment
import de.cau.cs.kieler.kexpressions.keffects.Effect
import de.cau.cs.kieler.kexpressions.keffects.Emission
import org.eclipse.emf.common.util.EList
import de.cau.cs.kieler.kexpressions.keffects.PrintCallEffect
import de.cau.cs.kieler.kexpressions.PrintCall
import de.cau.cs.kieler.kexpressions.keffects.ReferenceCallEffect
import de.cau.cs.kieler.kexpressions.ReferenceCall
import de.cau.cs.kieler.kexpressions.keffects.RandomizeCallEffect

/**
 * Serialization of KEffects.
 * 
 * @author ssm
 *
 * @kieler.design 2015-06-08 proposed ssm
 * @kieler.rating 2015-06-08 proposed yellow
 */
class KEffectsSerializeExtensions extends KExpressionsSerializeHRExtensions {
    
    public def CharSequence serializeAssignOperator(AssignOperator operator) {
        if (operator == AssignOperator::ASSIGNADD) {
            return " += " 
        } else 
        if (operator == AssignOperator::ASSIGNSUB) {
            return " -= " 
        } else 
        if (operator == AssignOperator::ASSIGNMUL) {
            return " *= " 
        } else 
        if (operator == AssignOperator::ASSIGNDIV) {
            return " /= " 
        } else 
        if (operator == AssignOperator::ASSIGNMOD) {
            return " %= " 
        } else 
        if (operator == AssignOperator::ASSIGNAND) {
            return " &= " 
        } else 
        if (operator == AssignOperator::ASSIGNOR) {
            return " |= " 
        } else 
        if (operator == AssignOperator::ASSIGNXOR) {
            return " ^= "
        } else 
        if (operator == AssignOperator::ASSIGNSHIFTLEFT) {
            return " <<= "
        } else 
        if (operator == AssignOperator::ASSIGNSHIFTRIGHT) {
            return " >>= "
        } else 
        if (operator == AssignOperator::ASSIGNSHIFTRIGHTUNSIGNED) {
            return " >>>= "
        } else 
        if (operator == AssignOperator::ASSIGNMIN) {
            return " min= " 
        } else 
        if (operator == AssignOperator::ASSIGNMAX) {
            return " max= " 
        } else 
        if (operator == AssignOperator::POSTFIXADD) {
            return "++"
        } else 
        if (operator == AssignOperator::POSTFIXSUB) {
            return "--"
        }
        
        return " = "          
    }
    
    public def CharSequence serializeAssignmentRoot(Assignment assignment) {
        var String res = ""
        if (assignment.reference !== null) {
            res = res + assignment.reference.valuedObject.name
            if (!assignment.reference.indices.nullOrEmpty) {
                for(index : assignment.reference.indices) {
                    res = res + "[" + index.serialize + "]"
                }
            }
        }
        return res        
    }
    
    public def CharSequence serializeAssignment(Assignment assignment, CharSequence expressionStr) {
        var res = assignment.serializeAssignmentRoot.toString
        
        if (!res.nullOrEmpty) {
            res = res + assignment.operator.serializeAssignOperator
        }
        
        if (expressionStr !== null) {
            res = res + expressionStr
        }
        
        return res
    }
    
    def dispatch CharSequence serialize(Assignment assignment) {
        assignment.serializeAssignment(assignment.expression.serialize)
    }
    
    def dispatch CharSequence serialize(Emission emission) {
        val valuedObjectContainer = emission.reference.valuedObject.eContainer
        if (valuedObjectContainer instanceof VariableDeclaration) {
            if (valuedObjectContainer.type != ValueType::PURE) {
                return (emission.reference.valuedObject.name + "(" + emission.newValue.serialize + ")")             
            } else {
                return emission.reference.valuedObject.name
            }
        } else {
            return emission.reference.valuedObject.name
        }
    }
    
    def dispatch CharSequence serialize(EList<Effect> effects) {
        if (!effects.empty) {
            var String label = "" 
            for(effect : effects) {
                label = label + effect.serialize as String + "; "
            }
            label = label.substring(0, label.length - 2)
            return label
        }
        return ""
    }
    
    def dispatch CharSequence serialize(PrintCallEffect printCallEffect) {
        var paramStr = printCallEffect.parameters.serializeParameters.toString
        
        return "print " + paramStr.substring(1, paramStr.length - 1)
    }   
    
    def dispatch CharSequence serialize(PrintCall printCall) {
        var paramStr = printCall.parameters.serializeParameters.toString
        
        return "print " + paramStr.substring(1, paramStr.length - 1)
    }  

    def dispatch CharSequence serialize(ReferenceCallEffect referenceCallEffect) {
        var paramStr = referenceCallEffect.parameters.serializeParameters.toString
        
        return "print " + paramStr.substring(1, paramStr.length - 1)
    }   
    
    def dispatch CharSequence serialize(RandomizeCallEffect randomizeCallEffect) {
        return "randomize";
    }   
    
}