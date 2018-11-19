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
package de.cau.cs.kieler.scg.extensions

import de.cau.cs.kieler.scg.Assignment
import de.cau.cs.kieler.scg.Conditional
import de.cau.cs.kieler.scg.ControlFlow
import de.cau.cs.kieler.scg.Depth
import de.cau.cs.kieler.scg.Entry
import de.cau.cs.kieler.scg.Exit
import de.cau.cs.kieler.scg.Fork
import de.cau.cs.kieler.scg.Join
import de.cau.cs.kieler.scg.Node
import de.cau.cs.kieler.scg.Surface
import java.util.HashMap
import java.util.LinkedList
import com.google.inject.Inject
import de.cau.cs.kieler.kexpressions.keffects.DataDependency

/**
 * A class with extensions for the calculation of Strongly Connected Components
 * @author lpe
 *
 */
class SCCExtensions {
    
    @Inject extension SCGControlFlowExtensions
    @Inject extension SCGDependencyExtensions
    
    /**
     * Creates a HashMap to find the SCC a node belongs to
     * 
     * @param sccs
     *              The provided list of SCCs
     * 
     * @return
     *              A HashMap containing all nodes and the index of the SCC in sccs they belong to
     */
    public def HashMap<Node,Integer> createNodeToSCCMap (LinkedList<LinkedList<Node>> sccs){
        var i = 0;
        var map = <Node,Integer> newHashMap
        for (scc : sccs){
            for (s : scc){
                map.put(s,i)
            }
            i++;
        }
        return map
    }
    
    //-----------------------------------------------------------------------------------------------
    //----------------------------NEIGHBORS & DEPENDENCIES-------------------------------------------
    //-----------------------------------------------------------------------------------------------
    
    /**
     * Finds the following neighbor(s) of the node with the 
     * exception of Surface --> Depth connections
     * 
     * @param n
     *          The node for which the neighbors are to be found
     * 
     * @return 
     *          The following neighbor(s) of the node
     */
    public def LinkedList<Node> getNeighbors(Node n) {
        var neighbors = <Node> newLinkedList
        
        if(n instanceof Entry) {
            if(n.next !== null) {
                neighbors.add(n.next.targetNode)                
            }
        }
        
        if(n instanceof Exit) {
            if(n.next !== null) {
                neighbors.add(n.next.targetNode)
            }
        }
        
        if(n instanceof Assignment) {
            if (n.next !== null) neighbors.add(n.next.targetNode)
        }
        
        if(n instanceof Conditional) {
            if (n.then !== null) neighbors.add(n.then.targetNode)
            if (n.^else !== null) neighbors.add(n.^else.targetNode)
        }
        
        if(n instanceof Fork) {
            for(next : n.next) {
                neighbors.add(next.targetNode)
            }
        }
        
        if(n instanceof Join) {
            if (n.next !== null) neighbors.add(n.next.targetNode)
        }
        
        if(n instanceof Depth) {
            if (n.next !== null) neighbors.add(n.next.targetNode)
        }
        
        if(n instanceof Surface) {
            // Do nothing
        }
        
        neighbors
    }
    
    /**
     * Finds the predecessors of the node n.
     * 
     * @param n
     *          The node for which to find the predecessors
     * 
     * @return
     *          A list of nodes whose neighbors contain the node n
     */
    public def LinkedList<Node> getPredecessors(Node n) {
        var pred = <Node> newLinkedList
        if(!(n instanceof Depth)) {
            for(inc : n.incomingLinks) {
                if(inc instanceof ControlFlow) {
                    pred.add(inc.eContainer as Node)
                }
            }            
        }
        pred
    }
    
    
    
    /**
     * Finds the following neighbor(s) of the node, even 
     * Surface --> Depth connections
     * 
     * @param n
     *          The node for which the neighbors are to be found
     * 
     * @return 
     *          The following neighbor(s) of the node
     */
    public def LinkedList<Node> getAllNeighbors(Node n) {
        
        var neighbors = <Node> newLinkedList
        if(n instanceof Surface) {
            neighbors.add(n.depth)
            neighbors
        } else {
            return n.neighbors
        }
    }
    
    /**
     * Finds the outgoing concurrent dependencies of a Node 
     * 
     * @param n
     *          The node for which the dependencies are to be found
     * 
     * @return 
     *          The outgoing dependencies of the node
     */
    public def LinkedList<Node> getConcurrentDependencies(Node n) {
        var deps = <Node> newLinkedList
        // Get only concurrent dependencies!!
        for(dep : n.dependencies) {
            if(dep instanceof DataDependency) {
                if(dep.concurrent && !dep.confluent) {
                    if(dep.target !== null) {
                        deps.add(dep.target as Node)                        
                    }
                }
                
            }
            
        }
        deps
    }
    
    /**
     * Finds the incoming concurrent dependencies of a node
     * 
     * @param n
     *          The node for which the incoming dependencies are to be found
     * 
     * @return
     *          The nodes that are the origins for the incoming dependencies of n
     */
    public def LinkedList<Node> getIncomingDependencies(Node n) {
        var deps = <Node> newLinkedList
        for(inc : n.incomingLinks) {
            if(inc instanceof DataDependency) {
                if(inc.concurrent && ! inc.confluent) {
                    deps.add(inc.eContainer as Node)
                }
            }
        }
        deps
    }
    
    
    /**
     * Finds the following neighbor(s) of the node with the 
     * exception of Surface --> Depth connections as well as 
     * their dependencies 
     * 
     * @param n
     *          The node for which the neighbors are to be found
     * 
     * @return 
     *          The following neighbor(s) of the node
     */
    public def LinkedList<Node> getNeighborsAndDependencies(Node n) {
        System.out.flush
        var neighbors = <Node> newLinkedList
        neighbors.addAll(n.neighbors)
        neighbors.addAll(n.concurrentDependencies)
        neighbors
    }
    
    
    /**
     * Finds all (non-delayed) neighboring nodes of the given SCC
     * 
     * @param scc
     *          The SCC for whom to find the neighbors
     * 
     * @return
     *          The neighboring nodes of scc
     */
    public def LinkedList<Node> findNeighborsOfSCC(LinkedList<Node> scc) {
        var neighbors = <Node> newLinkedList
        for(node : scc) {
            for(neighbor : node.neighbors) {
                if(!scc.contains(neighbor) && !neighbors.contains(neighbor)) {
                    neighbors.add(neighbor)
                }
            }
        }
        neighbors
    }
    
    
    /**
     * Finds all (non-delayed) nodes whose neighbors are in the given SCC
     * 
     * @param scc
     *          The SCC for whom to find the predecessors
     * 
     * @return
     *          The predecessors of scc
     */
    public def LinkedList<Node> findPredecessorsOfSCC(LinkedList<Node> scc) {
        var pred = <Node> newLinkedList
        for(node : scc) {
            for(predecessor : node.predecessors) {
                if(!scc.contains(predecessor) && !pred.contains(predecessor)) {
                    pred.add(predecessor)
                }
            }
        }
        pred
    }
    
    /**
     * Finds all nodes that are dependent from the given SCC
     * 
     * @param scc
     *          The SCC for whom to find the dependent nodes
     * 
     * @return
     *          The dependent nodes
     */
    public def LinkedList<Node> findAllDependenciesOfScc(LinkedList<Node> scc) {
        var dependencies = <Node> newLinkedList
        for(node : scc) {
            for(dep : node.concurrentDependencies) {
                if(!scc.contains(dep) && !dependencies.contains(dep)) {
                    dependencies.add(dep)
                }
            }
        }
        dependencies
        
    }
    
    private HashMap<LinkedList<Node>, LinkedList<Node>> externalDependencies = newHashMap
    
    public def LinkedList<Node> findAllExternalDependenciesOfScc(LinkedList<Node> scc, HashMap<Node, Integer> sccMap) {
        var dependencies = <Node> newLinkedList
        var originalScc = -1
        if(externalDependencies.containsKey(scc)) {
            return externalDependencies.get(scc)
        } else {
            if(sccMap.containsKey(scc.head)) {
                originalScc = sccMap.get(scc.head)
                for(node : scc) {
                    for(dep : node.concurrentDependencies) {
                        if(!sccMap.containsKey(dep) || sccMap.get(dep) != originalScc) {
                            dependencies.add(dep)
                        }
                    }
                }
            }
            externalDependencies.put(scc, dependencies)
        }
        return dependencies
    }
    
    /**
     * Finds all incoming dependencies of the given SCC
     * 
     * @param scc
     *          The SCC for whom to find the incoming dependent nodes
     * 
     * @return
     *          The nodes that have outgoing dependencies on the nodes in the given SCC
     */
    public def LinkedList<Node> findAllIncomingDependenciesOfScc(LinkedList<Node> scc) {
        var incDep = <Node> newLinkedList
        for(node : scc) {
            for(inc : node.incomingDependencies) {
                if(!scc.contains(inc) && !incDep.contains(inc)) {
                    incDep.add(inc)
                }
            }
        }
        incDep
    }
}