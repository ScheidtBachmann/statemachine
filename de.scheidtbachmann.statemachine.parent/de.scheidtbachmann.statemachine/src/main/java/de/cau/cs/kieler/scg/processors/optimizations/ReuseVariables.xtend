/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2016 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */

/**
 * Optimizer Reuse Variables.
 * 
 * @author jbus
 * @kieler.design 
 * @kieler.rating 
 */

package de.cau.cs.kieler.scg.processors.optimizations

import de.cau.cs.kieler.scg.processors.optimizations.features.OptimizerFeatures
import de.cau.cs.kieler.scg.SCGraph
import de.cau.cs.kieler.scg.features.SCGFeatureGroups
import de.cau.cs.kieler.scg.features.SCGFeatures
import de.cau.cs.kieler.scg.Assignment
import java.util.ArrayList
import de.cau.cs.kieler.kexpressions.ValuedObjectReference
import java.util.TreeMap
import de.cau.cs.kieler.kexpressions.OperatorExpression
import de.cau.cs.kieler.scg.Node
import de.cau.cs.kieler.scg.Conditional
import de.cau.cs.kieler.kexpressions.ValuedObject
import de.cau.cs.kieler.kexpressions.Declaration
import java.util.Map.Entry
import com.google.inject.Inject
import de.cau.cs.kieler.kexpressions.keffects.extensions.KEffectsExtensions
import de.cau.cs.kieler.scg.extensions.SCGControlFlowExtensions

class ReuseVariables {
    
    @Inject extension KEffectsExtensions    
    @Inject extension SCGControlFlowExtensions
    
    ArrayList<Node> visited = new ArrayList() 
    Iterable<Assignment> assignments;
    private static final val MAX_SEARCH_DEPTH = 100 // maximum search depth for next pointer search
    def getProducedFeatureId() {
        return OptimizerFeatures::RV_ID
    }
    def getRequiredFeatureIds() {
        return newHashSet(SCGFeatures::SEQUENTIALIZE_ID, SCGFeatureGroups::SCG_ID)
    }
    def getId() {
        return OptimizerFeatures::RV_ID
    }
    def getName() {
        return OptimizerFeatures::RV_NAME
    }
    def SCGraph transform(SCGraph scg) {
        /* SET FILTER */
        val nodes = scg.nodes
        val declarations = scg.declarations
        assignments = nodes.filter(typeof(Assignment)).filter [
            it.operator.getName().equals("ASSIGN")
        ].filter [
            if (it.valuedObject === null) {
                return false
            }
            it.valuedObject.getName().startsWith("g")
        ]
        val lastUse = new TreeMap<String, Pair<Node, Node>>()
        /* GET LAST USE */
        val uses = new ArrayList<Pair<ValuedObjectReference, Node>>() // use and node
        val preUses = new ArrayList<ValuedObjectReference>()

        nodes.forEach [
            val node = it
            val objects = it.eAllContents().filter(typeof(ValuedObjectReference)).filter [
                it.valuedObject.name.startsWith("g")
            ]
            objects.forEach [
                if (it.eContainer instanceof OperatorExpression) {
                    val op = it.eContainer as OperatorExpression
                    if (op.operator.getName().equals("PRE")) {
                        preUses.add(it)
                    }
                }
                uses.add(new Pair(it, node))
            ]
        ]
        /* clean PRE reads */
        preUses.forEach [
            val pre = it
            val rm = new ArrayList<Pair<ValuedObjectReference, Node>>()
            uses.filter [
                it.key.valuedObject.name.equals(pre.valuedObject.name)
            ].forEach [
                rm.add(it)
            ]
            rm.forEach [
                uses.remove(it)
            ]
        ]
        uses.forEach [
            val name = it.key.valuedObject.name
            if (lastUse.containsKey(name)) {
                val tmp = lastUse.get(name)
                lastUse.replace(name, new Pair(tmp.key, it.value))
            } else {
                val assigment = assignments.findFirst[
                    it.valuedObject.name.equals(name)
                ]
                lastUse.put(name, new Pair(assigment, it.value))
            }
        ]
        do {
            // get first element of last use
            val firstElem = lastUse.pollFirstEntry
            // get second element which is not a pre-node from firstElem
            val secondElem = GetSecondElem(lastUse, firstElem)
            if (secondElem !== null) {
                lastUse.remove(secondElem.key)
                // get all occures / assigments of secondElem
                val valuedObjRep = new ArrayList<ValuedObjectReference>()
                nodes.forEach[
                    // find all occures of the element that we want to replace
                    if (it instanceof Assignment) {
                        val assNode = it as Assignment
                        val objects = assNode.eAllContents.filter(typeof(ValuedObjectReference)).filter[
                            it.valuedObject.name.equals(secondElem.key)
                        ]
                        objects.forEach[
                            valuedObjRep.add(it)
                        ]
                    } else if (it instanceof Conditional) {
                        val condNode = it as Conditional
                        val objects = condNode.eAllContents.filter(typeof(ValuedObjectReference)).filter[
                            it.valuedObject.name.equals(secondElem.key)
                        ]
                        objects.forEach[
                            valuedObjRep.add(it)
                        ]
                    }
                ]
                valuedObjRep.forEach[
                    val firstAss = assignments.findFirst[
                        it.valuedObject.name.equals(firstElem.key)
                    ]
                    it.valuedObject = firstAss.valuedObject
                    // replace second assignment with first one
                    val secondAss = assignments.findFirst[
                        it.valuedObject.name.equals(secondElem.key)
                    ]
                    if(secondAss !== null) {
                        secondAss.valuedObject = firstAss.valuedObject   
                    }
                ]
                // cleanup the removed variable
                val declChanges = new ArrayList<Pair<Declaration, ValuedObject>>()
                declarations.forEach[
                    val decl = it
                    it.valuedObjects.forEach[
                        val itN = it as ValuedObject
                        if(itN.getName().equals(secondElem.key)) {
                            declChanges.add(new Pair(decl, itN))
                        }
                    ]
                ]
                declChanges.forEach[
                    it.key.valuedObjects.remove(it.value)
                ]
            }
        } while (lastUse.size > 0) // loop until there is no replacement for a variable left

        return scg
    }
    // check if needle is in the next pointer chain of nextP. if hard is set, also needle == nextP returns true
    def boolean InNextPointerChain(Node needle, Node nextP, boolean hard) {
        visited.clear()
        return InNextPointerChain(needle, nextP, false, 0)
    }
    def boolean InNextPointerChain(Node needle, Node nextP, boolean hard, int hops) {
        if(visited.contains(nextP)) { // terminates if we searched the node already
            return false
        }
        visited.add(nextP) // add node to the searched ones
        if(MAX_SEARCH_DEPTH != 0 && hops > MAX_SEARCH_DEPTH) { // terminate if the maximum of depth is reached //this is a tradeoff between speed and possible next pointer after max depth
            return false
        }
        if (hard && nextP.equals(needle)) {
            return true
        }
        // search in the node types for the needle
        if (nextP instanceof Conditional) {
            val condNode = nextP as Conditional
            var one = false
            var two = false
            if (!condNode.^else.target.equals(needle)) {
                one = InNextPointerChain(needle, condNode.^else.targetNode, hard, hops + 1)
            } else {
                one = true
            }
            if (one || !condNode.then.target.equals(needle)) {
                two = InNextPointerChain(needle, condNode.then.targetNode, hard, hops + 1)
            } else {
                two = true
            }
            return one || two
        } else if (nextP instanceof Assignment) {
            val assNode = nextP as Assignment
            if (!assNode.next.target.equals(needle)) {
                return InNextPointerChain(needle, assNode.next.targetNode, hard, hops + 1)
            } else {
                return true
            }
        }
        return false
    }
    // search a suitable variable to be replaced by an element
    def Entry<String, Pair<Node,Node>> GetSecondElem(TreeMap<String, Pair<Node,Node>> map, Entry<String, Pair<Node,Node>> firstEntry) {
        val tmp = new ArrayList<String>()
        map.forEach [ K, V |
            tmp.add(K)
        ]
        for (var i = 0; i < tmp.size; i++) {
            val elem = map.get(tmp.get(i))
            if(InNextPointerChain(elem.key, firstEntry.value.value, true)) {
                return map.ceilingEntry(tmp.get(i))
            }
        }
        return null
    }
}
