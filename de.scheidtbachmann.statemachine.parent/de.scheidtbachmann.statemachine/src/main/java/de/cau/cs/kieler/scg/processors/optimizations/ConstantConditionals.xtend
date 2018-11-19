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

import de.cau.cs.kieler.kexpressions.BoolValue
import de.cau.cs.kieler.kicool.kitt.tracing.Traceable
import de.cau.cs.kieler.scg.Assignment
import de.cau.cs.kieler.scg.Conditional
import de.cau.cs.kieler.scg.ControlFlow
import de.cau.cs.kieler.scg.Depth
import de.cau.cs.kieler.scg.Entry
import de.cau.cs.kieler.scg.Exit
import de.cau.cs.kieler.scg.Fork
import de.cau.cs.kieler.scg.Join
import de.cau.cs.kieler.scg.Node
import de.cau.cs.kieler.scg.SCGraph
import de.cau.cs.kieler.scg.Surface
import org.eclipse.emf.ecore.EObject
import com.google.inject.Inject
import de.cau.cs.kieler.scg.extensions.SCGControlFlowExtensions

/**
 * Removes conditional nodes holding a constant (true/false)
 * 
 * @author krat ssm 
 * @kieler.design 2015-05-25 proposed 
 * @kieler.rating 2015-05-25 proposed yellow
 *
 */
class ConstantConditionals implements Traceable {
    
    @Inject extension SCGControlFlowExtensions

    private val processedNodes = <Node>newLinkedList
    private val deleteNodes = <Conditional>newLinkedList

    def getId() {
        throw new UnsupportedOperationException("TODO: auto-generated method stub")
    }
    
    def process(EObject eObject) {
        System.out.println("Removing constant conditionals")
        val scg = (eObject as SCGraph).nodes.head.transformCond(eObject as SCGraph)

        // Remove crossreferences        
        for (node : scg.nodes) {
            deleteNodes.forEach[ node.incomingLinks.remove(it.then); node.incomingLinks.remove(it.^else) ]
        }
        // Remove nodes
        scg.nodes.removeAll(deleteNodes)
        
        scg
    }

    def dispatch SCGraph transformCond(Entry entry, SCGraph scg) {
        if (entry.marked)
            return scg
        transformCond(entry.next.targetNode.removeCond(entry.next), scg)
    }

    def dispatch SCGraph transformCond(Exit exit, SCGraph scg) {
        if (exit.marked || exit.next === null)
            return scg
        transformCond(exit.next.targetNode.removeCond(exit.next), scg)
    }

    def dispatch SCGraph transformCond(Surface surface, SCGraph scg) {
        if(surface.marked) return scg
        transformCond(surface.depth, scg)
    }

    def dispatch SCGraph transformCond(Depth depth, SCGraph scg) {
        if(depth.marked) return scg
        transformCond(depth.next.targetNode.removeCond(depth.next), scg)
    }

    def dispatch SCGraph transformCond(Assignment assignment, SCGraph scg) {
        if(assignment.marked) return scg
        transformCond(assignment.next.targetNode.removeCond(assignment.next), scg)
    }

    def dispatch SCGraph transformCond(Fork fork, SCGraph scg) {
        if(fork.marked) return scg
        fork.next.forEach[transformCond(it.targetNode.removeCond(it), scg)]
        transformCond(fork.join, scg)
    }

    def dispatch SCGraph transformCond(Join join, SCGraph scg) {
        if(join.marked) return scg
        transformCond(join.next.targetNode.removeCond(join.next), scg)
    }

    def dispatch SCGraph transformCond(Conditional cond, SCGraph scg) {
        if(cond.marked) return scg

        transformCond(cond.then.targetNode.removeCond(cond.then), scg)
        transformCond(cond.^else.targetNode.removeCond(cond.^else), scg)
    }

    /*
     * Removes the conditional if it holds a constant as guard. Incoming edges are re-routed.
     * @param node The node which might be deleted
     * @param cf Sources control flow
     */
    def Node removeCond(Node node, ControlFlow cf) {
        if (node instanceof Conditional) {
            val cond = node as Conditional
            if (cond.condition instanceof BoolValue) {
                deleteNodes.add(cond)
                if ((cond.condition as BoolValue).value == true) {
                    val thenTarget = cond.then.targetNode
                    cf.target = thenTarget
                    return thenTarget
                } else {
                    val elseTarget = cond.^else.targetNode
                    cf.target = elseTarget
                    return elseTarget
                }

            }
        }
        return node
    }

    def boolean marked(Node node) {
        if(processedNodes.contains(node)) return true
        processedNodes.add(node);
        false
    }

}
