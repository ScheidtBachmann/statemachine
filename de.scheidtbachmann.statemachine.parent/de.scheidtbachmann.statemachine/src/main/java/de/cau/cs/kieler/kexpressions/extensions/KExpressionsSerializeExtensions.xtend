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
package de.cau.cs.kieler.kexpressions.extensions

import de.cau.cs.kieler.kexpressions.BoolValue
import de.cau.cs.kieler.kexpressions.Expression
import de.cau.cs.kieler.kexpressions.FloatValue
import de.cau.cs.kieler.kexpressions.FunctionCall
import de.cau.cs.kieler.kexpressions.IntValue
import de.cau.cs.kieler.kexpressions.OperatorExpression
import de.cau.cs.kieler.kexpressions.OperatorType
import de.cau.cs.kieler.kexpressions.StringValue
import de.cau.cs.kieler.kexpressions.TextExpression
import de.cau.cs.kieler.kexpressions.ValueType
import de.cau.cs.kieler.kexpressions.ValuedObject
import de.cau.cs.kieler.kexpressions.ValuedObjectReference
import java.util.Iterator
import java.util.List
import de.cau.cs.kieler.kexpressions.VariableDeclaration
import de.cau.cs.kieler.kexpressions.Parameter
import de.cau.cs.kieler.kexpressions.ReferenceCall
import de.cau.cs.kieler.kexpressions.CombineOperator
import de.cau.cs.kieler.kexpressions.VectorValue
import de.cau.cs.kieler.kexpressions.IgnoreValue
import de.cau.cs.kieler.kexpressions.RandomCall
import de.cau.cs.kieler.kexpressions.RandomizeCall
import de.cau.cs.kieler.annotations.NamedObject

/**
 * Serialization of KExpressions.
 * 
 * @author ssm
 * 
 * @kieler.design 2014-09-04 proposed ssm
 * @kieler.rating 2014-09-04 proposed yellow
 *
 */
class KExpressionsSerializeExtensions {

    def dispatch CharSequence serialize(ValueType valueType) {
        return valueType.literal;
    }

    def dispatch CharSequence serialize(TextExpression hostCodeString) {
        "`" + hostCodeString.text + "`"
    }
    
    protected def String combineOperators(Iterator<Expression> expressions, String separator) {
        var s = ""
        if (!expressions.hasNext) {
            System.err.println("Serialization: An operator expression without sub-expressions occurred! " + 
                "This should not happen! Check your transformation!")
        }
        while (expressions.hasNext) {
            s = s + expressions.next.serialize
            if(expressions.hasNext) s = s + separator;
        }
        s
    }
    
    protected def CharSequence serializeOperatorExpressionEQ(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " == ")
    }
    
    protected def CharSequence serializeOperatorExpressionLT(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " < ")
    }
    
    protected def CharSequence serializeOperatorExpressionLEQ(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " <= ")
    }

    protected def CharSequence serializeOperatorExpressionGT(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " > ")
    }
    
    protected def CharSequence serializeOperatorExpressionGEQ(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " >= ")
    }
    
    protected def CharSequence serializeOperatorExpressionVAL(OperatorExpression expression) {
    	"val(" + expression.subExpressions.head.serialize + ")"
    }
    
    protected def CharSequence serializeOperatorExpressionPRE(OperatorExpression expression) {
    	"pre(" + expression.subExpressions.head.serialize + ")"
    }   

    protected def CharSequence serializeOperatorExpressionFBY(OperatorExpression expression) {
        combineOperators(expression.subExpressions.iterator, " -> ")
    }
    
    protected def CharSequence serializeOperatorExpressionNot(OperatorExpression expression) {
    	"!" + expression.subExpressions.head.serialize
    }

    protected def CharSequence serializeOperatorExpressionNE(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " != ")
    }
    
    protected def CharSequence serializeOperatorExpressionLogicalAnd(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " && ")
    }
    
    protected def CharSequence serializeOperatorExpressionLogicalOr(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " || ")
    }
    
    protected def CharSequence serializeOperatorExpressionBitwiseNot(OperatorExpression expression) {
        "~" + expression.subExpressions.head.serialize
    }
    
    protected def CharSequence serializeOperatorExpressionBitwiseAnd(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " & ")
    }    
    
    protected def CharSequence serializeOperatorExpressionBitwiseOr(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " | ")
    }
    
    protected def CharSequence serializeOperatorExpressionBitwiseXOr(OperatorExpression expression) {
        combineOperators(expression.subExpressions.iterator, " ^ ")
    }

    protected def CharSequence serializeOperatorExpressionShiftLeft(OperatorExpression expression) {
        combineOperators(expression.subExpressions.iterator, " << ")
    }
    
    protected def CharSequence serializeOperatorExpressionShiftRight(OperatorExpression expression) {
        combineOperators(expression.subExpressions.iterator, " >> ")
    }
    
    protected def CharSequence serializeOperatorExpressionShiftRightUnsigned(OperatorExpression expression) {
        combineOperators(expression.subExpressions.iterator, " >>> ")
    }
    
    protected def CharSequence serializeOperatorExpressionAdd(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " + ")
    }
    
    protected def CharSequence serializeOperatorExpressionSub(OperatorExpression expression) {
        if (expression.subExpressions.size == 1) {
            "-" + expression.subExpressions.head.serialize
        } else {
        	combineOperators(expression.subExpressions.iterator, " - ")
    	}
    }
    
    protected def CharSequence serializeOperatorExpressionMul(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " * ")
    }
    
    protected def CharSequence serializeOperatorExpressionDiv(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " / ")
    }        

    protected def CharSequence serializeOperatorExpressionMod(OperatorExpression expression) {
    	combineOperators(expression.subExpressions.iterator, " % ")
    }
    
    protected def CharSequence serializeOperatorExpressionConditional(OperatorExpression expression) {
        if (expression.subExpressions.size == 3) {
            return expression.subExpressions.head.serialize + " ? " +
                expression.subExpressions.get(1).serialize + " : " + 
                expression.subExpressions.get(2).serialize  
        } else {
            throw new IllegalArgumentException("An OperatorExpression with a ternary conditional has " + 
                expression.subExpressions.size + " arguments.")
        }
    }        
            
        
    // Expand a complex expression.
    protected def CharSequence serializeOperatorExpression(OperatorExpression expression) {
        var CharSequence result = ""
        
        if (expression.operator == OperatorType::EQ) {
            result = expression.serializeOperatorExpressionEQ
        } else if (expression.operator == OperatorType::LT) {
            result = expression.serializeOperatorExpressionLT
        } else if (expression.operator == OperatorType::LEQ) {
            result = expression.serializeOperatorExpressionLEQ
        } else if (expression.operator == OperatorType::GT) {
            result = expression.serializeOperatorExpressionGT
        } else if (expression.operator == OperatorType::GEQ) {
            result = expression.serializeOperatorExpressionGEQ
        } else if (expression.operator == OperatorType::NOT) {
            return expression.serializeOperatorExpressionNot
        } else if (expression.operator == OperatorType::VAL) {
            return expression.serializeOperatorExpressionVAL
        } else if (expression.operator == OperatorType::PRE) {
            return expression.serializeOperatorExpressionPRE
        } else if (expression.operator == OperatorType::FBY) {
            return expression.serializeOperatorExpressionFBY
        } else if (expression.operator == OperatorType::NE) {
            result = expression.serializeOperatorExpressionNE
        } else if (expression.operator == OperatorType::LOGICAL_AND) {
            result = expression.serializeOperatorExpressionLogicalAnd
        } else if (expression.operator == OperatorType::LOGICAL_OR) {
            result = expression.serializeOperatorExpressionLogicalOr
        } else if (expression.operator == OperatorType::BITWISE_NOT) {
            return expression.serializeOperatorExpressionBitwiseNot
        } else if (expression.operator == OperatorType::BITWISE_AND) {
            result = expression.serializeOperatorExpressionBitwiseAnd
        } else if (expression.operator == OperatorType::BITWISE_OR) {
            result = expression.serializeOperatorExpressionBitwiseOr
        } else if (expression.operator == OperatorType::BITWISE_XOR) {
            result = expression.serializeOperatorExpressionBitwiseXOr
        } else if (expression.operator == OperatorType::SHIFT_LEFT) {
            result = expression.serializeOperatorExpressionShiftLeft
        } else if (expression.operator == OperatorType::SHIFT_RIGHT) {
            result = expression.serializeOperatorExpressionShiftRight
        } else if (expression.operator == OperatorType::SHIFT_RIGHT_UNSIGNED) {
            result = expression.serializeOperatorExpressionShiftRightUnsigned
        } else if (expression.operator == OperatorType::ADD) {
            result = expression.serializeOperatorExpressionAdd
        } else if (expression.operator == OperatorType::SUB) {
            result = expression.serializeOperatorExpressionSub
        } else if (expression.operator == OperatorType::MULT) {
            result = expression.serializeOperatorExpressionMul
        } else if (expression.operator == OperatorType::DIV) {
            result = expression.serializeOperatorExpressionDiv
        } else if (expression.operator == OperatorType::MOD) {
            result = expression.serializeOperatorExpressionMod
        } else if (expression.operator == OperatorType::CONDITIONAL) {
            result = expression.serializeOperatorExpressionConditional
        }  
            
        return result
    }
    
    
    def dispatch CharSequence serialize(CombineOperator combineOperator) {
        return switch (combineOperator) {
            case CombineOperator.ADD : "+" 
            case CombineOperator.MULT : "*" 
            case CombineOperator.MIN : "min" 
            case CombineOperator.MAX : "max"
            case CombineOperator.AND : "and"
            case CombineOperator.OR : "or"
            //FIXME discuss what to serialize in the host case
            case CombineOperator.HOST : "host"
            default: ""
        }
    }
    
        
    def dispatch CharSequence serialize(OperatorExpression expression) {
		val result = serializeOperatorExpression(expression)
		
		if ((expression.operator == OperatorType::NOT) ||
		    (expression.operator == OperatorType::BITWISE_NOT) || 
			(expression.operator == OperatorType::VAL) ||
			(expression.operator == OperatorType::PRE)) {
			return result
		}

		return "(" + result + ")"
	}

    // -------------------------------------------------------------------------
    def dispatch CharSequence serialize(ValuedObject valuedObject) {
        var vo = valuedObject.name
        for (index : valuedObject.cardinalities) {
            vo = vo + "[" + index.serialize + "]"
        }
        vo
    }

    def dispatch CharSequence serialize(ValuedObjectReference valuedObjectReference) {
        var vo = valuedObjectReference.valuedObject.name
        for (index : valuedObjectReference.indices) {
            vo = vo + "[" + index.serialize + "]"
        }
        if (valuedObjectReference.subReference !== null && valuedObjectReference.subReference.valuedObject !== null) {
            vo = vo + "." + valuedObjectReference.subReference.serialize
        }        
        vo
    }

    // Expand a int expression value.
    def dispatch CharSequence serialize(IntValue expression) {
        expression.value.toString
    }

    // Expand a float expression value.
    def dispatch CharSequence serialize(FloatValue expression) {
        expression.value.toString
    }

    def dispatch CharSequence serialize(StringValue expression) {
        "\"" + expression.value + "\""
    }
    
    def dispatch CharSequence serialize(VectorValue expression) {
        var s = "{" 
        for (value : expression.values) {
            s = s + value.serialize + ", "
        }
        return s.substring(0, s.length - 2) + "}"
    }
    
    def dispatch CharSequence serialize(IgnoreValue expression) {
        "_"
    }

    // Expand a boolean expression value (true or false).
    def dispatch CharSequence serialize(BoolValue expression) {
        if(expression.value == true) return "true"
        return "false"
    }
    
    def dispatch CharSequence serialize(ReferenceCall referenceCall) {
        return referenceCall.valuedObject.serialize.toString + referenceCall.parameters.serializeParameters
    }

    def dispatch CharSequence serialize(FunctionCall functionCall) {
        return "extern " + functionCall.functionName + functionCall.parameters.serializeParameters
    }
    
    def dispatch CharSequence serialize(RandomCall randomCall) {
        return "random"
    }
    
    def dispatch CharSequence serialize(RandomizeCall randomizeCall) {
        return "randomize"
    }    
    
    def protected CharSequence serializeParameters(List<Parameter> parameters) {
        val sb = new StringBuilder
        sb.append("(")
        var cnt = 0
        for (par : parameters) {
            if (cnt > 0) {
                sb.append(", ")
            }
            if (par.pureOutput) {
                sb.append("!")
            }
            if (par.callByReference) {
                sb.append("&")
            }
            sb.append(par.expression.serialize)
            cnt = cnt + 1
        }
        sb.append(")") 
        return sb.toString      
    }

    def dispatch CharSequence serialize(String s) {
        s
    }

    def dispatch CharSequence serialize(Void x) {
    }


   def Pair<List<String>, List<String>> serializeComponents(VariableDeclaration declaration) {
        val keywords = newLinkedList;
        val content = newLinkedList;

        //Modifiers
        if (declaration.isExtern) {
            keywords += "extern";
        }
        if (declaration.isStatic) {
            keywords += "static ";
        }
        if (declaration.isConst) {
            keywords += "const";
        }
        if (declaration.isInput) {
            keywords += "input";
        }
        if (declaration.isOutput) {
            keywords += "output"
        }
        if (declaration.isSignal) {
            keywords += "signal";
        }

        //Type
        keywords += declaration.type.serialize as String

        //Content
        for (valuedObject : declaration.valuedObjects) {
            content += valuedObject.serialize + ",";
        }
        // Remove last comma
        if (!content.empty) {
            content.removeLast;
            content += declaration.valuedObjects.last.serialize as String;
        }

        return new Pair(keywords, content);
    }
    
    def dispatch CharSequence serialize(NamedObject namedObject) {
        "NamedObject \"" + namedObject.name + "\""
    }
  
  
    val static final CARDINALITY_CHAR = new Character('[')
  
    def CharSequence removeCardinalities(CharSequence cs) {
        for(var i = 0; i < cs.length; i++)  {
            if (CARDINALITY_CHAR.equals(new Character(cs.charAt(i)))) return cs.subSequence(0, i)
        }
        return cs
    }
  
}