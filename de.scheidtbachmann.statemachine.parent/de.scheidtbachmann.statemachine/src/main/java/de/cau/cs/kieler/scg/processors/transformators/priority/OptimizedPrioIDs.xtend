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
package de.cau.cs.kieler.scg.processors.transformators.priority

import de.cau.cs.kieler.scg.Node
import java.util.HashMap
import java.util.LinkedList
import java.util.List

/**
 * Class for the optimization of prio IDs of an SCG. 
 * @author lpe
 *
 */
class OptimizedPrioIDs {
    
    /**
     * The maximum priority ID that exists.
     * 
     */
    private static int maxPID;
    
    
    public def getMaxPID() {
        return maxPID
    }
    
    /**
     * Calculates the optimized priority IDs of every node of the SCG using the prioIDs. This is done to remove 
     * 'empty' priority IDs as in, priority IDs which are not used by any node. 
     * 
     * @param prioIDs
     *                  The priority IDs of all nodes
     * @param nodes
     *                  A list of all nodes of the SCG
     * 
     * @return
     *                  A HashMap mapping the nodes to their optimized priority IDs
     */
    public def HashMap<Node, Integer> calcOptimizedPrioIDs(HashMap<Node, Integer> prioIDs, List<Node> nodes) {
        
        var LinkedList<Integer> ids = <Integer> newLinkedList
        var List<Integer> sortedIds
        
        maxPID = 0
        
        for(node : nodes) {
            val id = prioIDs.get(node)
            if(id != null && !ids.contains(id)) {
                ids.add(id)
            }
        }
        sortedIds = ids.sort
        
        
        var HashMap<Node, Integer> optPrioIDs = <Node, Integer> newHashMap
        for(node : nodes) {
            val pID = prioIDs.get(node)
            if(pID != null) {
                optPrioIDs.put(node, 1 + sortedIds.indexOf(pID))
            }
        }
        
        maxPID = sortedIds.size
        
        return optPrioIDs
        
    }
    
}