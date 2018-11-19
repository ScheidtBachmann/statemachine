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

import de.cau.cs.kieler.scg.Entry
import de.cau.cs.kieler.scg.Exit
import de.cau.cs.kieler.scg.Fork
import de.cau.cs.kieler.scg.Node
import java.util.HashMap
import java.util.LinkedList
import java.util.List
import javax.inject.Inject
import de.cau.cs.kieler.scg.extensions.SCCExtensions
import de.cau.cs.kieler.scg.extensions.SCGControlFlowExtensions

/**
 * Calculates the Thread Segment IDs of the nodes in an SCG
 * @author lpe
 *
 */
class ThreadSegmentIDs {

    @Inject extension SCCExtensions
    @Inject extension SCGControlFlowExtensions
    
    /** The thread segment ID for each node */
    private HashMap<Node, Integer> threadSegmentIDs
    /** A HashMap to store whether a node has been visited or not */
    private HashMap<Node, Boolean> visited
    /** The node priorities of a node calculated beforehand */
    private HashMap<Node, Integer> nodePrios
    /** The overall number of thread segment IDs */
    private int nThreadSegmentIDs
    
    private int nextTID
    
    /**
     * Gives the number of thread segment IDs
     */
    public def int getNumberOfThreadSegmentIDs() {
        return nThreadSegmentIDs
    }
    
    /**
     * Calculates the thread segment IDs of the given SCG (given as a list of nodes).
     * 
     * @param nodes
     *              The SCG for which to calculate the thread segment IDs
     * @param nodePrios
     *              The node priorities of the given nodes. This is required to minimize 
     *              context switches 
     * 
     * @return
     *              A HashMap mapping the nodes of the SCG to their thread segment ID
     */
    public def HashMap<Node, Integer> calcThreadSegmentIDs(List<Node> nodes, HashMap<Node, Integer> nodePrios) {
        
        this.nodePrios = nodePrios
        
        threadSegmentIDs = <Node, Integer> newHashMap
        visited          = <Node, Boolean> newHashMap
        nextTID          = 1
        for(node : nodes) {
            visited.put(node, false)
        }
        
        val forkNodes = nodes.filter[it instanceof Fork]
        var LinkedList<Node> entryToThreadNodes = <Node> newLinkedList
        
        for(node : forkNodes) {
            val fork = node as Fork
            for(link : fork.next) {
                entryToThreadNodes.add(link.targetNode)
            }
        }
        nThreadSegmentIDs = entryToThreadNodes.length
        
        assignThreadSegmentIDs(nodes.head, 1)
        
        val unvisitedNodes = nodes.filter[!visited.get(it)]
        
        for(node : unvisitedNodes) {
            node.visitUnvisitedNode            
        }
        
        
        return threadSegmentIDs
    }
    
    /**
     *  Method to calculate the thread segment IDs of the nodes. Executes a depth-first search 
     *  of the nodes. If we reach the end of an execution, the thread is given the ID threadID. 
     * 
     *  Non-reachable nodes are ignored here.
     * 
     * @param node
     *              The current node. Calculates the thread segment ID for all his children and then 
     *              calculate the thread segment ID of this node.
     * @param threadID
     *              The threadID to be given to the thread
     * 
     * @return
     *              The thread segment ID of the node to be used by its parent node
     */
    private def int assignThreadSegmentIDs(Node node, int threadID) {
        var tID = threadID
        val neighbors = node.allNeighbors
        
        if(!visited.get(node)) {
            visited.put(node, true)
            if(node instanceof Fork) {
                // The thread with the highest node Priority always gets the highest thread priority.
                // This assures that when joining, the thread with the highest node priority when forking
                // will not get the lowest thread priority when joining.
                val sortedNeighbors = neighbors.sortBy[neighbor | nodePrios.get((neighbor as Entry).exit)]
                var highestnpr = Integer.MIN_VALUE
                var highesttid = Integer.MIN_VALUE
                
                for(n : sortedNeighbors) {
                    tID = assignThreadSegmentIDs(n, nextTID)
                    if(nodePrios.get(n) >= highestnpr && tID >= highesttid) {
                        highestnpr = nodePrios.get(n)
                        highesttid = tID
                    }
                    nextTID++
                }
                nextTID--
                tID = highesttid
                threadSegmentIDs.put(node, tID)
                
            } else {
                for(n : neighbors) {
                    tID = assignThreadSegmentIDs(n, tID)
                    threadSegmentIDs.put(node, tID)
                }
            }
            
        }
        if(neighbors.empty) {
            threadSegmentIDs.put(node, tID)
        }
        
        return tID
        
    }
    
    
    /**
     *  Method to calculate ThreadSegmentIDs for unreachable nodes.
     * 
     *  @param unvisitedNode
     *      The unvisited node whose ThreadSegmentID to calculate.
     * 
     *  @returns
     *      The ThreadSegmentID of the node
     */
    private def int visitUnvisitedNode(Node unvisitedNode) {

        var tsID = 0
        if(!visited.get(unvisitedNode)) {
            visited.put(unvisitedNode, true)
            if(unvisitedNode instanceof Exit) {
                val entry = (unvisitedNode as Exit).entry
                if(threadSegmentIDs.containsKey(entry)) {
                    tsID = threadSegmentIDs.get(entry)
                       
                }
    
            } else {
                val neighbors = unvisitedNode.allNeighbors
                for(n : neighbors) {
                    if(visited.get(n) && threadSegmentIDs.containsKey(n)) {
                        tsID = threadSegmentIDs.get(n)
                    } else {
                        tsID = visitUnvisitedNode(n)
                    }
                }
            }
            threadSegmentIDs.put(unvisitedNode, tsID)
            return tsID             
        } else {
            if(threadSegmentIDs.containsKey(unvisitedNode)) {
                return threadSegmentIDs.get(unvisitedNode)                
            } else {
                return 1
            }
        }
    }
    
}