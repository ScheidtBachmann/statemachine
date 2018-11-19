/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2013 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.scg.transformations.basicblocks

import com.google.inject.Inject
import de.cau.cs.kieler.annotations.extensions.AnnotationsExtensions
import de.cau.cs.kieler.kexpressions.KExpressionsFactory
import de.cau.cs.kieler.kexpressions.ValuedObject
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsDeclarationExtensions
import de.cau.cs.kieler.kicool.compilation.InplaceProcessor
import de.cau.cs.kieler.kicool.kitt.tracing.Traceable
import de.cau.cs.kieler.scg.BasicBlock
import de.cau.cs.kieler.scg.BranchType
import de.cau.cs.kieler.scg.Conditional
import de.cau.cs.kieler.scg.ControlFlow
import de.cau.cs.kieler.scg.Depth
import de.cau.cs.kieler.scg.Entry
import de.cau.cs.kieler.scg.Exit
import de.cau.cs.kieler.scg.Fork
import de.cau.cs.kieler.scg.Guard
import de.cau.cs.kieler.scg.Join
import de.cau.cs.kieler.scg.Node
import de.cau.cs.kieler.scg.Predecessor
import de.cau.cs.kieler.scg.SCGPlugin
import de.cau.cs.kieler.scg.SCGraph
import de.cau.cs.kieler.scg.SCGraphs
import de.cau.cs.kieler.scg.ScgFactory
import de.cau.cs.kieler.scg.SchedulingBlock
import de.cau.cs.kieler.scg.Surface
import de.cau.cs.kieler.scg.extensions.SCGControlFlowExtensions
import de.cau.cs.kieler.scg.extensions.SCGCoreExtensions
import de.cau.cs.kieler.scg.extensions.UnsupportedSCGException
import de.cau.cs.kieler.scg.features.SCGFeatures
import java.util.HashMap
import java.util.List
import java.util.logging.Level

import static extension de.cau.cs.kieler.kicool.kitt.tracing.TransformationTracing.*
import de.cau.cs.kieler.kexpressions.keffects.extensions.KEffectsExtensions
import de.cau.cs.kieler.kexpressions.keffects.Dependency
import de.cau.cs.kieler.kexpressions.keffects.DataDependency

/** 
 * This class is part of the SCG transformation chain. The chain is used to gather information 
 * about the schedulability of a given SCG. This is done in several key steps. Contrary to the first 
 * version of SCGs, there is only one SCG meta-model. In each step the gathered data will be added to 
 * the model. 
 * You can either call the transformation manually or use KiCo to perform a series of transformations.
 * <pre>
 * SCG 
 *   |-- Dependency Analysis 	 					
 *   |-- Basic Block Analysis					<== YOU ARE HERE
 *   |-- Scheduler
 *   |-- Sequentialization (new SCG)
 * </pre>
 * 
 * @author ssm
 * @kieler.design 2013-10-24 proposed 
 * @kieler.rating 2013-10-24 proposed yellow
 */

class BasicBlockTransformation extends InplaceProcessor<SCGraphs> implements Traceable {

    @Inject extension KExpressionsDeclarationExtensions
    @Inject extension KEffectsExtensions
    @Inject extension SCGCoreExtensions
    @Inject extension SCGControlFlowExtensions
    @Inject extension AnnotationsExtensions
    
    public static val String GUARDPREFIX = "_g"
	protected val SPLITSCHEDULINGBLOCKSATENTRY = false

    protected val processedNodes = <Node> newHashSet
    protected val basicBlockNodeMapping = new HashMap<Node, BasicBlock>
    protected val basicBlockGuardCache = new HashMap<ValuedObject, BasicBlock>
    protected val guardCache = <Guard> newArrayList
    
    override getId() {
        "de.cau.cs.kieler.scg.processors.basicBlocks"
    }
    
    override getName() {
        "Basic Blocks"
    }
    
    override process() {
        for (scg : model.scgs) {
            scg.transform
        }
    }

    /**
     * transformSCGDEPToSCGBB executes the transformation of an SCG with dependency information to an
     * SCG enriched with basic block information.
     * 
     * @param scgdep
     * 			the source SCG
     * @return Returns the enriched SCG.
     * @throws UnsupportedSCGException
     * 			if the first node of the SCG is not an entry node.
     */
    public def SCGraph transform(SCGraph scg) {
        // Since KiCo may use the transformation instance several times, we must clear the caches manually. 
        processedNodes.clear     
        basicBlockNodeMapping.clear
        basicBlockGuardCache.clear
        guardCache.clear
        
        // Timestamp for performance information. Should be moved to the KiCo interface globally.
//        SCGPlugin.log("Nodes: " + scg.nodes.size)  
        val timestamp = System.currentTimeMillis  

        // Create the basic blocks beginning with the first node in the node list.
        // It is expected that this node is an entry node.
        if (!(scg.nodes.head instanceof Entry)) throw new UnsupportedSCGException("The basic block analysis expects an entry node as first node!")
        
        val basicBlockCache = <BasicBlock> newArrayList
        var index = 0
        for(node : scg.nodes) {
            if (!processedNodes.contains(node)) {
                index = scg.createBasicBlocks(node, index, basicBlockCache)
            }
        }
        
        /** 
         * Remove the dead block flag if the block is a go block or if it has at least one predecessor
         *  that is not dead. In the case of join blocks, all predecessors have to be active.
         */
        val timestamp2 = System.currentTimeMillis  
        for(bb : basicBlockCache) {
            if (bb.goBlock) {
                bb.deadBlock = false
            } else {
                if (bb.synchronizerBlock) {
                    bb.deadBlock = bb.predecessors.map[basicBlock].filter[deadBlock&&!finalBlock].size > 0
                } else if (bb.depthBlock) {
                    bb.deadBlock = basicBlockGuardCache.get(bb.preGuard).deadBlock
                } else {
                    bb.deadBlock = bb.predecessors.map[basicBlock].filter[!deadBlock].size == 0
                }
            }
        }
        scg.basicBlocks += basicBlockCache
        // Add all cached guards to the SCG and create a boolean declaration for their VOs.
        scg.guards += guardCache
        scg.declarations += createBoolDeclaration => [ declaration | 
        	guardCache.forEach[ guard | declaration.valuedObjects += guard.valuedObject ]
        ]
        val time2 = (System.currentTimeMillis - timestamp2) as float
        SCGPlugin.log("Dead block processing finished (time elapsed: "+(time2 / 1000)+"s).", Level.FINE)            
        
        //KITT
        if (isTracingActive()) {
            for (BasicBlock bb : scg.basicBlocks) {
                for (SchedulingBlock sb : bb.schedulingBlocks) {
                    val nodes = sb.nodes;
                    sb.trace(nodes);
                    sb.guards.head?.trace(nodes);
                    sb.guards.head?.valuedObject?.trace(nodes);
                    bb.trace(nodes);
                    bb.predecessors.trace(nodes);
                }
            }
        }

        scg.createStringAnnotation(SCGFeatures.BASICBLOCK_ID, SCGFeatures.BASICBLOCK_NAME)
        
        val time = (System.currentTimeMillis - timestamp) as float
        SCGPlugin.log("Basic Block transformation finished (time elapsed: "+(time / 1000)+"s).", Level.FINE)    
        
        // Return the SCG with basic block data.
        scg
    }   
    

    // -------------------------------------------------------------------------
    // -- Basic Block methods
    // -------------------------------------------------------------------------
    
    /**
     * This is the entry point for the basic block creation. Since no list of predecessors is present at this time,
     * an empty list will be created and used. This function calls the main method for the basic block processing
     * which travels iteratively through all nodes and creates the blocks. Therefore, the actual index is passed 
     * between the recursive calls to uniquely identify all basic blocks. 
     * 
     * @param scg
     * 			the scg in question
     * @param rootNode
     * 			the node to start the basic block detection
     * @param guardIndex
     * 			the index of the next guard
     * @return Returns the index of the next guard after processing.<br>
     * 		Effectively, this is the count of guards when returning to the main transformation method.
     */
     protected def int createBasicBlocks(SCGraph scg, Node rootNode, int guardIndex, List<BasicBlock> basicBlockCache) {
        val predecessorBlocks = <BasicBlock> newLinkedList
        createBasicBlocks(scg, rootNode, guardIndex, basicBlockCache, predecessorBlocks, null)        
    }   
        
    /**
     * This is the main function of the basic block creation.<br>
     * It travels iteratively through all nodes and creates the blocks. Therefore, the actual index is passed 
     * between the recursive calls to uniquely identify all basic blocks.<br>
     * Rules for basic blocks are... (ssm-dt)
     * <ul>
     *   <li>A BB begins with the statement at the beginning of a thread or if the SCG 
     *       representation of that statement has two or more incoming edges.</li>
     *   <li>A BB ends with a statements that forks the SCG control flow and hence has
     *       two or more outgoing control flow edges.</li>
     *   <li>BBs are split at pause statements.</li>
     *   <li>SCG fork nodes close a BB, whereas join nodes start a new one.</li>
     *   <li>Any statement of a given program can only be included in one BB at any time.</li>
     * </ul>
     * In accordance to the metamodel the method gathers the nodes in scheduling blocks and calls
     * {@link #insertBasicBlock(SCGraphBB, ValuedObject, SchedulingBlock, List)} to actually add the
     * block to the SCG.
     * 
     * @param scg
     * 			the scg in question
     * @param rootNode
     * 			the node to start the basic block detection
     * @param guardIndex
     * 			the index of the next guard
     * @param predecessorBlocks
     * 			list of predecessor basic blocks
     * @return Returns the index of the next guard after processing.
     */       
    protected def int createBasicBlocks(SCGraph scg, Node rootNode, int guardIndex, List<BasicBlock> basicBlockCache,  
    	List<BasicBlock> predecessorBlocks, Entry threadEntry
    ) {
    	// The index must not be final. Copy it to newIndex. 
        var newIndex = guardIndex
        // Do the same with the rootNode.
        var node = rootNode
        
        // First of all we have to check if this block has already been checked.
        // Therefore, gather all nodes of all already created basic blocks 
        // and check whether or not the requested node is present.
        if (processedNodes.contains(rootNode)) {
        	// If the node has already been processed, add the predecessorList passed by the caller to the basic block
        	// of the node in question. Return afterwards with unmodified index since no new block was created.
        	if (predecessorBlocks !== null && predecessorBlocks.size > 0) {
                val rootBasicBlock = basicBlockNodeMapping.get(rootNode)
                rootBasicBlock.predecessors.addAll(predecessorBlocks.createPredecessors(rootBasicBlock))
            }
            return newIndex;
        }

        if (basicBlockCache.size % 10000 == 0) {
            SCGPlugin.log("Basic Blocks: " + basicBlockCache.size + " with " + processedNodes.size + " nodes", Level.FINE)
        }
        
        // Create a new ValuedObject for the guards of the upcoming basic block.
        // Each guard is identified by its unique name and is of boolean type.
        val guardValuedObject = KExpressionsFactory::eINSTANCE.createValuedObject
        guardValuedObject.name = GUARDPREFIX + newIndex.toString
//        guard.type = ValueType::BOOL;
        
        // Increase the index for successive iterative calls.
        newIndex = newIndex + 1
        
        // Since the nodes are stored in the scheduling blocks of a basic block, we create a new SchedulingBlock to accumulate the nodes.
        // The corresponding basic block will be created when all nodes of a block are determined.
        val nodeList = <Node> newArrayList
        
        // Repeat the node gathering until the node is empty.
        while(node !== null) {
        	// This first node is always part of the new block. Add it.
            nodeList += node
            
            // Now, check the type of the node and react appropriately.
            if (node instanceof Conditional) {
            	/** 
            	 * If the node is a conditional node, the end of the new block is reached 
            	 * and the control flow proceeds in two different paths.<br>
            	 * Therefore, create the new block with insertBasicBlock and recursively call the 
            	 * createBasicBlock function for each control flow.<br>
            	 * Afterwards, set the node to null which will ensure the exiting of this function instance.
            	 */
                val block = scg.insertBasicBlock(guardValuedObject, nodeList, basicBlockCache, predecessorBlocks, threadEntry)
                if (node.asConditional.then !== null)
                    newIndex = scg.createBasicBlocks((node as Conditional).then.targetNode, newIndex, basicBlockCache, newLinkedList(block), threadEntry)
                if (node.asConditional.^else !== null)                    
                    newIndex = scg.createBasicBlocks((node as Conditional).^else.targetNode, newIndex, basicBlockCache, newLinkedList(block), threadEntry)
                node = null
            } else 
            if (node instanceof Surface) {
            	/**
            	 * If the node is a surface node, the end of the new block is also reached.<br>
            	 * The next block will start at the corresponding depth node.<br>
            	 * Create the block and proceed recursively with the depth. Then ensure the exiting of this instance.
            	 */
                val block = scg.insertBasicBlock(guardValuedObject, nodeList, basicBlockCache, predecessorBlocks, threadEntry)
                newIndex = scg.createBasicBlocks((node as Surface).depth, newIndex, basicBlockCache, newLinkedList(block), threadEntry)
                node = null
            }  else
            if (node instanceof Fork) {
            	/**
            	 * If the node is a fork node, the end of the block is reached, too.<br>
            	 * The control flow may proceed on several ways.<br>
            	 * Hence, create a block and call this function recursively for each control flow.<br>
            	 * The called threads will not proceed with their control flow beyond their exit node    
            	 * so proceed with the corresponding join node of the fork and leave this instance.<br>
            	 */
            	// Insert the actual block. 
                val block = scg.insertBasicBlock(guardValuedObject, nodeList, basicBlockCache, predecessorBlocks, threadEntry)
                // Call the createBasicBlock method for each control flow.
                for(flow : node.eAllContents.filter(ControlFlow).toList) {
                    val entry = flow.target as Entry
                    newIndex = scg.createBasicBlocks(flow.targetNode, newIndex, basicBlockCache, newLinkedList(block), entry)
                    
                    // Make sure the exit node was processed.
                    newIndex = scg.createBasicBlocks((flow.target as Entry).exit, newIndex, basicBlockCache, <BasicBlock> newLinkedList, entry)
                }
				// Subsequently, retrieve all exit nodes that link to the join node and proceed
				// with the basic block analysis at the corresponding join node.
                val joinPredecessors = <BasicBlock> newLinkedList
                node.getAllNext.forEach[ 
                	joinPredecessors += basicBlockNodeMapping.get((it.target as Entry).exit) 
                ]
                newIndex = scg.createBasicBlocks((node as Fork).join, newIndex, basicBlockCache, joinPredecessors, threadEntry)
                node = null                
            } else {
            	/**
            	 * Otherwise, the node is not a conditional, surface or fork. 
            	 * Since all other blocks only have at most one outgoing control flow, 
            	 * we may perhaps include it to the actual block.
            	 * Nevertheless, we do not want to add blocks beyond exit node borders or 
            	 * blocks with more than one incoming control flow. 
            	 * Therefore, check the next block for these properties.
            	 */
            	// Retrieve the target of the next control flow.
                var next = node.eContents.filter(ControlFlow)?.head?.targetNode
                // if the node has already been processed, skip it.
                if (processedNodes.contains(next) && next.incomingLinks.filter(ControlFlow).size < 2) {
                    next = null
                }
                if (next instanceof Join || next === null) {
                	/**
                	 * If the next node would be a join node, we would exit the thread border. 
                	 * Insert the actual block and do not proceed. The calling fork tree will handle 
                	 * the other threads and the subsequent join analysis.
                	 */
                    scg.insertBasicBlock(guardValuedObject, nodeList, basicBlockCache, predecessorBlocks, threadEntry)
                    node = null
                } else
                if (next !== null && next.incomingLinks.filter(ControlFlow).size > 1) {
                	/**
                	 * If the next block has more than one incoming control flow, it starts a new block.
                	 * Hence, add the actual block and proceed with the next one but exit this instance. 
                	 */
                    val block = scg.insertBasicBlock(guardValuedObject, nodeList, basicBlockCache, predecessorBlocks, threadEntry)
                    newIndex = scg.createBasicBlocks(next, newIndex, basicBlockCache, newLinkedList(block), threadEntry) 
                    node = null;
                } else {
                	/** None of the basic block criteria fits. Simply proceed with the next node. */
                    node = next
                }
            }
        }
                
        // Return the new guard index for further processing. 
        newIndex
    }
 
    
    /**
     * This function takes the scheduling block generated by the 
     * {@link #createBasicBlocks(SCGraphBB, Node, int, List)}
     * method and inserts a new basic block into the scg.<br>
     * Therefore it may be necessary to split the scheduling block in different blocks depending on incoming dependencies.
     * To do this a list of scheduling blocks is created by {@link #splitSchedulingBlock(SchedulingBlock, BasicBlock)} and
     * added to the basic block.
     * 
     * @param scg
     * 			the SCG in question
     * @param guard
     * 			the ValuedObject of the guard that should be used for this block
     * @param schedulingBlock
     * 			the not yet separated scheduling block generated before
     * @param predecessorBlocks
     * 			a list of basic blocks that serve as predecessors for this block
     * @return Returns the actual newly generated basic block.
     */     
    protected def BasicBlock insertBasicBlock(SCGraph scg, ValuedObject guard, List<Node> nodeList,
        List<BasicBlock> basicBlockCache, List<BasicBlock> predecessorBlocks, Entry threadEntry
    ) {
    	// Create a new basic block with the Scgbb factory.
        val basicBlock = ScgFactory::eINSTANCE.createBasicBlock
        
        /** Assume that the basic block depends on the GO-Signal of a circuit if it has no predecessors. */ 
        if (predecessorBlocks !== null && predecessorBlocks.size == 0 && nodeList.head instanceof Entry) {
        	basicBlock.goBlock = true
        }
        /** Initially, mark all blocks as dead. */
        basicBlock.deadBlock = true
        
        
        basicBlock.finalBlock = false
        basicBlock.threadEntry = threadEntry
        
        /**  
         *If the basic block starts with a depth node, there should only be one predecessor.
         * Use this predecessor to determine the pre guards of the depth block and clear the predecessor list.
         * This is done to remove all dependencies to previous blocks for the scheduler because the block 
         * does not rely on them in the actual tick instance.
         */ 
        if (nodeList.head instanceof Depth) { 
        	basicBlock.depthBlock = true
        	basicBlock.preGuard = predecessorBlocks.head.schedulingBlocks.head.guards.head.valuedObject
        	predecessorBlocks.clear
            if (basicBlock.threadEntry !== null) {
                if (basicBlock.threadEntry.exit.final) basicBlock.finalBlock = true    
            }
        }
        /** If the block begins with a join node, mark the block as synchronizer block. */
        if (nodeList.head instanceof Join) { 
            basicBlock.synchronizerBlock = true
        }
        if (nodeList.head instanceof Entry) { 
            basicBlock.entryBlock = true
        }
        if (nodeList.last instanceof Exit) {
            val finalNode = nodeList.last as Exit
            if (finalNode.next === null) basicBlock.termBlock = true
            basicBlock.finalBlock = finalNode.final
        }
 
 		// Add the guard object.
//        basicBlock.guard = guard
        // Add all scheduling blocks as described in the introduction of this function.
        basicBlock.schedulingBlocks += scg.createSchedulingBlocks(nodeList, basicBlock, guard)
        for (sb : basicBlock.schedulingBlocks) {
            basicBlockGuardCache.put(sb.guards.head.valuedObject, basicBlock)
        }
        // Add all predecessors. To do this createPredecessors creates a list with predecessor objects.
        basicBlock.predecessors.addAll(predecessorBlocks.createPredecessors(basicBlock))
        // Add the newly created basic block to the SCG...
        basicBlockCache.add(basicBlock)
        
        basicBlock.schedulingBlocks.forEach[ nodes.forEach[ basicBlockNodeMapping.put(it, basicBlock) ]]
                
        // ... and return the block.
        basicBlock
    }
    
    /**
     * splitSchedulingBlock takes a scheduling block and splits it in different blocks 
     * depending on incoming dependency edges. 
     * 
     * @param schedulingBlock
     * 			the scheduling block in question
     * @param basicBlock
     * 			the basic block the scheduling block will belong to
     * @return Returns a list of scheduling blocks which will at least contain one block.
     */
    protected def List<SchedulingBlock> createSchedulingBlocks(SCGraph scg, List<Node> nodeList, BasicBlock basicBlock, 
        ValuedObject guard
    ) {
    	// Create a new list of scheduling blocks.
        val schedulingBlocks = <SchedulingBlock> newArrayList
        
        // Set the variables of the actual block to null to mark the first iteration.
        var SchedulingBlock block = null
        var ValuedObject sbGuard = null
        var Node lastNode = null
        
        // Examine each node of the original scheduling block.
        for (node : nodeList) {
        	// In the first iteration or if we have to split the block...
            if (block === null || 
                node.schedulingBlockSplitter(lastNode)
            ) {
            	// ... add the block if it is not the first.
                if (block !== null) schedulingBlocks.add(block)
                if (sbGuard === null) {
                	// If it is the first block, re-use the guard of the basic block.
                	sbGuard = guard
                } else {
                	// Otherwise, create a new guard and add it to the list of guards in the basic block. 
                	// It must be present in the list of the basic block because this list is the containment 
                	// of the guards in the metamodel. The information is later used to serialize the guard names. 
			        sbGuard = KExpressionsFactory::eINSTANCE.createValuedObject
			        if (schedulingBlocks.size>25) {
        				sbGuard.name = guard.name + "z" + (schedulingBlocks.size - 25) 
			        } else {
        				sbGuard.name = guard.name + (96 + schedulingBlocks.size + 1) as char
       				}
                }
                // Create a new scheduling block, add all incoming dependencies of the node to the block for caching purposes
                // and store a reference of the guard.
                val newGuard = ScgFactory::eINSTANCE.createGuard
                newGuard.valuedObject = sbGuard;
                guardCache += newGuard
                
                block = ScgFactory::eINSTANCE.createSchedulingBlock()
                block.guards += newGuard
                block.label = newGuard.valuedObject.name
                block.dependencies.addAll(node.incomingLinks.filter(Dependency))
            }
            // Add the node to the scheduling block.
            block.nodes.add(node)
            processedNodes.add(node)
            lastNode = node
        }
        // Finally, add the block to the list, if it is not empty and return the list of blocks.
        if (block !== null) schedulingBlocks.add(block)
        
        schedulingBlocks
    }
    
    protected def boolean schedulingBlockSplitter(Node node, Node lastNode) {
        (!node.incomingLinks.filter(DataDependency).filter[ concurrent && !confluent].empty) ||
        (SPLITSCHEDULINGBLOCKSATENTRY && (lastNode instanceof Entry))
    } 
    
    /**
     * Since predecessor blocks may have additional attributes, a predecessors is identified by its own object.
     * The object stores the actual basic block and, e.g., information about preceding conditional nodes.  
     * 
     * @param basicBlocks
     * 			the actual list of predecessor blocks
     * @param target
     * 			the basic block the predecessors belong to
     * @return Returns a processed list of predecessor objects.
     */
    protected def List<Predecessor> createPredecessors(List<BasicBlock> basicBlocks, BasicBlock target) {
    	// Create a list for the predecessor objects.
    	val predecessors = <Predecessor> newArrayList
    	
    	// Process each predecessor basic block.
    	for(bb : basicBlocks) {
    		// Create a new predecessor object and set its basic block.
    		if (bb !== null) {
    		    val predecessor = ScgFactory::eINSTANCE.createPredecessor => [ basicBlock = bb ]
    		
        		// Additionally, check the last node of the predecessor block.
        		val lastNode = bb.schedulingBlocks.last.nodes.last
                if (lastNode !== null)
                if (lastNode instanceof Conditional) {
       		   	   /**
               	    * If it is a conditional, we want to mark this block appropriately and store a reference
          		    * to the condition of the conditional. The scheduler can use this information without extra 
       			    * examination of the basic blocks to generate the guard expressions.
       			    * Therefore, check whether first node of the target block is the target of the then or else 
       			    * branch of the conditional and add this information to the predecessor object. 
       			    */
       			    if (lastNode.then !== null && 
       			      target.schedulingBlocks.head.nodes.head == lastNode.then.target) {
						predecessor.branchType = BranchType::TRUEBRANCH
       			    } else {
       			    	predecessor.branchType = BranchType::ELSEBRANCH
       			    }
                    predecessor.conditional = lastNode
                }
    		
                // Add the predecessor to the predecessors list.
                predecessors.add(predecessor)
            }
    	}
    	
    	// Return the list.
    	predecessors
    }
  
}