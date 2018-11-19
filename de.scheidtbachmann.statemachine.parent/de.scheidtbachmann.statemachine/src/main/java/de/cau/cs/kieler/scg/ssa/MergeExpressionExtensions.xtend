/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 * 
 * http://rtsys.informatik.uni-kiel.de/kieler
 * 
 * Copyright 2016 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 */
package de.cau.cs.kieler.scg.ssa

import com.google.common.collect.BiMap
import com.google.common.collect.HashMultimap
import com.google.common.collect.Multimap
import com.google.inject.Inject
import de.cau.cs.kieler.kexpressions.Expression
import de.cau.cs.kieler.kexpressions.FunctionCall
import de.cau.cs.kieler.kexpressions.OperatorExpression
import de.cau.cs.kieler.kexpressions.OperatorType
import de.cau.cs.kieler.kexpressions.Parameter
import de.cau.cs.kieler.kexpressions.StringValue
import de.cau.cs.kieler.kexpressions.ValuedObject
import de.cau.cs.kieler.kexpressions.ValuedObjectReference
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsCreateExtensions
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsValuedObjectExtensions
import de.cau.cs.kieler.scg.Assignment
import de.cau.cs.kieler.scg.Conditional
import de.cau.cs.kieler.scg.Entry
import de.cau.cs.kieler.scg.Fork
import de.cau.cs.kieler.scg.Join
import de.cau.cs.kieler.scg.Node
import de.cau.cs.kieler.scg.SCGraph
import de.cau.cs.kieler.scg.ScgFactory
import de.cau.cs.kieler.scg.Surface
import de.cau.cs.kieler.scg.extensions.SCGControlFlowExtensions
import de.cau.cs.kieler.scg.extensions.SCGCoreExtensions
import de.cau.cs.kieler.scg.ssa.domtree.DominatorTree
import java.util.Collection
import java.util.LinkedList
import java.util.List
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.util.EcoreUtil.Copier
import org.eclipse.xtend.lib.annotations.Data

import static de.cau.cs.kieler.scg.ssa.SSAFunction.*

import static extension com.google.common.base.Predicates.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import de.cau.cs.kieler.kexpressions.VariableDeclaration
import de.cau.cs.kieler.kexpressions.keffects.extensions.KEffectsExtensions
import de.cau.cs.kieler.kicool.environments.Environment
import de.cau.cs.kieler.kexpressions.keffects.AssignOperator
import de.cau.cs.kieler.kicool.compilation.Compile
import de.cau.cs.kieler.kicool.kitt.tracing.Tracing
import java.io.StringWriter
import java.io.PrintWriter
import de.cau.cs.kieler.scg.SCGraphs
import de.cau.cs.kieler.scg.extensions.SCGDependencyExtensions

/**
 * @author als
 * @kieler.design proposed
 * @kieler.rating proposed yellow
 */
class MergeExpressionExtension {
    
    @Inject extension SCGCoreExtensions
    @Inject extension SCGControlFlowExtensions
    @Inject extension SCGDependencyExtensions
    @Inject extension KExpressionsValuedObjectExtensions
    @Inject extension IOPreserverExtensions
    @Inject extension KExpressionsCreateExtensions
    @Inject extension SSACoreExtensions
    @Inject extension KEffectsExtensions
    static val sCGFactory = ScgFactory.eINSTANCE
    
    // -------------------------------------------------------------------------

    // CANNOT HANDLE CYCLES
    val static patternCache = <ValuedObject, MergeExpression>newHashMap
    val static schedules = <ValuedObject, List<Assignment>>newHashMap
    
    // -------------------------------------------------------------------------
    
    def isUpdate(Assignment asm) {
        return asm.operator != AssignOperator.ASSIGN
    }
    
    /**
     * Prepares this extension for generation merge expressions for updates.
     * STATEFUL
     */
    def prepareUpdateScheduling(SCGraph scg) {
        schedules.clear
        val updateVOs = scg.nodes.filter(Assignment).filter[isUpdate].map[valuedObject].toSet
        for (vo : updateVOs) {
            val copier = new Copier();
            val SCGraph copy = copier.copy(scg) as SCGraph
            copier.copyReferences();
            
            // Remove current analysis
            copy.annotations.clear
            copy.basicBlocks.clear
            copy.nodes.forEach[dependencies.clear]
            
            // Remove independent nodes
            // TODO this seems to break the scg sometimes
            val voCopy = copier.get(vo)
            val independentNodes = copy.nodes.filter(Assignment).filter[valuedObject != voCopy && !eAllContents.filter(ValuedObjectReference).exists[valuedObject == voCopy]].toList
            for (in : independentNodes) {
                in.incomingLinks.immutableCopy.forEach[ target = in.next.targetNode ]
                in.next.target = null
            }
            copy.nodes.removeAll(independentNodes)
            
            // Compile SCG scheduling       
            val compileSCGs = sCGFactory.createSCGraphs => [scgs += copy]    
            val context = Compile.createCompilationContext("de.cau.cs.kieler.scg.netlist", compileSCGs)
            context.startEnvironment.setProperty(Environment.INPLACE, true)
            context.startEnvironment.setProperty(Tracing.ACTIVE_TRACING, true)
            context.compile
            
            // Check result
            if (!context.processorInstancesSequence.forall[environment.errors.empty]) {
                throw new IllegalArgumentException(
                    "SCG with ValuedObject " + vo.name + " cannot be scheduled" +
                    context.processorInstancesSequence.findFirst[!environment.errors.empty].environment.errors.get(Environment.REPORT_ROOT).map[ err |
                         if (err.exception !== null) {
                             ((new StringWriter) => [err.exception.printStackTrace(new PrintWriter(it))]).toString()
                         } else {
                            err.message
                         }
                    ].join("\n- "))
            }

            // Extract schedule and map to original VOs
//            val schedSCGs = context.processorInstancesSequence.findFirst[id.equals("de.cau.cs.kieler.scg.processors.scheduler")].targetModel as SCGraphs
//            val schedSCG = schedSCGs.scgs.head
            val seqSCGs = context.result.model as SCGraphs
            val seqSCG = seqSCGs.scgs.head
            val tracing = context.result.getProperty(Tracing.TRACING_DATA)
            val mapping = tracing.getMapping(seqSCGs, compileSCGs);
            var ValuedObject findCopyVO = null
            for (d : seqSCG.declarations) {
                for (v : d.valuedObjects) {
                    if (mapping.get(v).filter(ValuedObject).head == voCopy) {
                        findCopyVO = v
                    }
                }
            }
            val schedVO = findCopyVO
            val schedule = <Assignment>newArrayList
            
            // Assumption node are present in schedule order
            for (n : seqSCG.nodes.filter(Assignment)) {
                if (n.valuedObject == schedVO) {
                    val copyAsm = mapping.get(n).filter(Assignment).head
                    val asm = copier.entrySet.findFirst[value == copyAsm].key
                    schedule.add(asm as Assignment)
                }
            }
//            val start = schedSCG.nodes.filter[!incoming.exists[it instanceof ScheduleDependency]].toList //Predicates.or(ScheduleDependency.instanceOf, GuardDependency.instanceOf)
//            var next = start.head
//            while (next !== null) {
//                for(a : next.dependencies.filter(ScheduleDependency).map[target].scheduleOrder.filter(Assignment).filter[valuedObject == schedVO]) {
//                    val copyAsm = mapping.get(a).filter(Assignment).head
//                    val asm = copier.entrySet.findFirst[value == copyAsm].key
//                    schedule.add(asm as Assignment)
//                }
//                next = next.dependencies.findFirst(ScheduleDependency.instanceOf)?.target
//            }
            
            // store schedule
            schedules.put(vo, schedule)
        }
    }
    
    private def List<Node> scheduleOrder(Iterable<Node> nodes) {
        // TODO order
        return nodes.toList
    }

    /**
     * Creates a SC specific merge expressions for the given reading node.
     * For combine expressions a prior preparation is needed.
     */
    def Expression createMergeExpression(Node readingNode, List<Node> concurrentNodes, ValuedObject vo, Multimap<Assignment, Parameter> ssaReferences, BiMap<ValuedObject, VariableDeclaration> ssaDecl, DominatorTree dt, boolean schedule) {
        val scg = readingNode.eContainer as SCGraph
        val hasUpdates = scg.hasUpdates(vo)
        val mexpression = if (hasUpdates && schedule) {
            scg.getScheduledExpression(vo, ssaDecl)
        } else {
            scg.getPatternExpression(vo, ssaDecl, dt)
        }
        
        // Calculate reaching definitions
        val reachinDefinitions = newHashSet
        val addQueue = newLinkedList
        addQueue.addAll(readingNode)
        var Node idom
        while (!addQueue.isEmpty) {
            val next = addQueue.pop
            for (pred : next.allPrevious.map[eContainer as Node]) {
                if (!reachinDefinitions.contains(pred)) {
                    if (pred instanceof Assignment) {
                        if (pred.valuedObject == vo) {
                            val dom = dt.isDominator(pred.basicBlock, readingNode.basicBlock)
                            if (dom && idom === null) {
                                idom = pred
                                reachinDefinitions.add(pred)
                            } else if (!dom) {
                                reachinDefinitions.add(pred)
                            }
                        }
                    }
                    addQueue.push(pred)
                }
            }
        }
        reachinDefinitions.addAll(concurrentNodes)
        
        // Reduce to dominant context
        for (entry : mexpression.refs.entries) {
            if (reachinDefinitions.contains(entry.key)) {
                ssaReferences.put(entry.key as Assignment, entry.value as Parameter)
            } else {
                // remove all references to sequentially following nodes
                entry.value.remove
            }
        }

        // TODO reduce non immediate dominators
//        
//        if (allPreceedingNodes.filter(Assignment).filter[valuedObject == vo && !isSSA].exists[
//            !scg.nodes.head.getInstantaneousControlFlows(it).empty && 
//            // dominates all following exits
//            (dt.isDominator(it.basicBlock, scg.nodes.head))
//        ]) {
//            (pattern.exp as FunctionCall).parameters.remove(0)
//        }
        
        return mexpression.expression
    }
    
    // -------------------------------------------------------------------------
    // Structural merge expressions
    // -------------------------------------------------------------------------
    
    def getPatternExpression(SCGraph scg, ValuedObject vo, BiMap<ValuedObject, VariableDeclaration> ssaDecl, DominatorTree dt) {
        val pattern = scg.getPattern(vo, ssaDecl, dt)
        // Copy pattern
        val copier = new Copier();
        val Expression expCopy = copier.copy(pattern.expression) as Expression
        copier.copyReferences();
        val refs = HashMultimap.<Assignment, Parameter>create
        for (entry : pattern.refs.entries) {
            val param = copier.get(entry.value) as Parameter
            param.expression = vo.reference
            refs.put(entry.key, param)
        }
        return new MergeExpression(expCopy, refs)
    }

    def getPattern(SCGraph scg, ValuedObject vo, BiMap<ValuedObject, VariableDeclaration> ssaDecl, DominatorTree dt) {
        if (!patternCache.containsKey(vo)) {
            val entry = scg.nodes.head as Entry
            val refs = HashMultimap.<Assignment, Parameter>create
            val expParam = entry.createSeqConcExpression(vo, refs, newHashSet, dt)
            val Expression scexp = if (refs.empty) {
                    vo.reference
                } else {
                    expParam.expression
                }
            var exp = scexp
            if (vo.variableDeclaration.input) {
                exp = SEQ.createFunction => [
                    parameters += createParameter => [
                        expression = vo.reference
                    ]
                    parameters += createParameter => [
                        expression = scexp
                    ]
                ]
            } else if (scg.isDelayed) {
                exp = SEQ.createFunction => [
                    parameters += createParameter => [
                        expression = createOperatorExpression(OperatorType.PRE) => [
                            subExpressions += ssaDecl.get(vo).valuedObjects.findFirst[isRegister].reference
                        ]
                    ]
                    parameters += createParameter => [
                        expression = scexp
                    ]
                ]
            }
            val mexpression = new MergeExpression(exp, refs)
            patternCache.put(vo, mexpression)
        }
        return patternCache.get(vo)
    }

    private def Parameter createSeqConcExpression(Node node, ValuedObject vo, Multimap<Assignment, Parameter> refs,
        Collection<Node> marks, DominatorTree dt) {
        if (marks.contains(node)) {
            return null
        }
        marks.add(node)
        switch (node) {
            Assignment: {
                if ((node as Assignment).valuedObject == vo && !(node.isOutputPreserver)) {
                    return createParameter => [
                        expression = SEQ.createFunction => [
                            parameters += createParameter => [
                                refs.put(node, it)
                            ]
                            node.allNext.filter[!marks.contains(it)].head?.targetNode?.createSeqConcExpression(vo, refs, marks, dt).addTo(parameters)
                        ]
                    ]
                } else {
                    return node.allNext.filter[!marks.contains(it)].head?.targetNode?.createSeqConcExpression(vo, refs, marks, dt)
                }
            }
            Fork: {
                return createParameter => [
                    expression = SEQ.createFunction => [
                        parameters += createParameter => [
                            expression = CONC.createFunction => [
                                node.allNext.map[targetNode].map [
                                    createSeqConcExpression(vo, refs, marks, dt)
                                ].addTo(parameters)
                            ]
                        ]
                        (node as Fork).join.next?.targetNode?.createSeqConcExpression(vo, refs, marks, dt).addTo(parameters)
                    ]
                ]
            }
            Conditional: {
                val cond = (node as Conditional)
                val thenBranch = cond.then?.targetNode
                val elseBranch = cond.^else?.targetNode
                if (thenBranch === null || elseBranch === null) {
                    throw new IllegalArgumentException("SCG contains malformed conditional node. No then or else branch present.")
                }
                if (marks.contains(thenBranch) && marks.contains(elseBranch)) {
                    return null
                } else if (marks.contains(thenBranch)) {
                    return createParameter => [
                        expression = SEQ.createFunction => [
                            elseBranch.createSeqConcExpression(vo, refs, marks, dt).addTo(parameters)
                        ]
                    ]
                } else if (marks.contains(elseBranch)) {
                    return createParameter => [
                        expression = SEQ.createFunction => [
                            thenBranch.createSeqConcExpression(vo, refs, marks, dt).addTo(parameters)
                        ]
                    ]
                } else {
                    // find branch join with dominator tree
                    var bb = cond.basicBlock
                    val children = dt.children(bb)
                    switch (children.size) {
                        case 1: {
                            return createParameter => [
                                expression = SEQ.createFunction => [
                                    if (children.head.nodes.contains(thenBranch)) {
                                        thenBranch.createSeqConcExpression(vo, refs, marks, dt).addTo(parameters)
                                    } else {
                                        elseBranch.createSeqConcExpression(vo, refs, marks, dt).addTo(parameters)
                                    }
                                ]
                            ]
                        }
                        case 2: {
                            return createParameter => [
                                expression = SEQ.createFunction => [
                                    thenBranch.createSeqConcExpression(vo, refs, marks, dt).addTo(parameters)
                                    elseBranch.createSeqConcExpression(vo, refs, marks, dt).addTo(parameters)
                                ]
                            ]
                        }
                        case 3: {
                            val join = children.findFirst[
                                val nodes = it.nodes
                                return !(nodes.contains(thenBranch) || nodes.contains(elseBranch))
                            ]
                            // Assumes that first node in first sb is first node in bb
                            val next = join.schedulingBlocks.head.nodes.head.createSeqConcExpression(vo, refs, marks, dt)
                            return createParameter => [
                                expression = SEQ.createFunction => [
                                    parameters += createParameter => [
                                        expression = SEQ.createFunction => [
                                           thenBranch.createSeqConcExpression(vo, refs, marks, dt).addTo(parameters)
                                           elseBranch.createSeqConcExpression(vo, refs, marks, dt).addTo(parameters)
                                        ]
                                    ]
                                    next.addTo(parameters)
                                ]
                            ]
                        }
                        default: return null
                    }
                }
            }
            Join:
                return null
            Surface:
                return node.depth.allNext.head?.targetNode?.createSeqConcExpression(vo, refs, marks, dt)
            default:
                return node.allNext.filter[!marks.contains(it)].head?.targetNode?.createSeqConcExpression(vo, refs, marks, dt)
        }
    }
    
    // -------------------------------------------------------------------------
    // Scheduling merge expressions
    // -------------------------------------------------------------------------
    
    def getScheduledExpression(SCGraph scg, ValuedObject vo, BiMap<ValuedObject, VariableDeclaration> ssaDecl) {
        if (!schedules.containsKey(vo)) {
            throw new IllegalArgumentException("Missing schedule for variable "+vo.name)
        }
        val ssaReferences = HashMultimap.<Assignment, Parameter>create
        val schedule = newLinkedList
        schedule.addAll(schedules.get(vo).reverseView)
        // Prepend inputs and register reads
        if (vo.variableDeclaration.input) {
            schedule.add(sCGFactory.createAssignment => [
                expression = vo.reference
            ])
        } else if (scg.isDelayed) {
            schedule.add(sCGFactory.createAssignment => [
                expression = createOperatorExpression(OperatorType.PRE) => [
                    subExpressions += ssaDecl.get(vo).valuedObjects.findFirst[isRegister].reference
                ]
            ])
        }
        val exp = createScheduledExpression(schedule, ssaReferences)
        
        return new MergeExpression(exp, ssaReferences)
    }
    
    def Expression createScheduledExpression(LinkedList<Assignment> assignments, HashMultimap<Assignment, Parameter> ssaReferences) {
        val head = assignments.pop
        if (assignments.empty) {
            if (head.valuedObject === null) {
                return SEQ.createFunction => [
                    parameters += createParameter => [
                        expression = head.expression
                    ]
                ]                
            } else {
                return SEQ.createFunction => [
                    parameters += createParameter => [
                        ssaReferences.put(head, it)
                        expression = head.valuedObject.reference
                    ]
                ]
            }
        } else if (head.isUpdate){
             return COMBINE.createFunction => [
                parameters += createParameter => [
//                    var op = (head.expression as OperatorExpression).operator.getName
//                    if (op.contains("_")) {
//                        op = op.substring(op.indexOf('_')+1)
//                    }
                    val op = switch(head.operator) {
                        case ASSIGNADD: OperatorType.ADD.literal
                        case ASSIGNAND: OperatorType.LOGICAL_AND.literal
                        case ASSIGNDIV: OperatorType.DIV.literal
                        case ASSIGNMAX: "max"
                        case ASSIGNMIN: "min"
                        case ASSIGNMOD: OperatorType.MOD.literal
                        case ASSIGNMUL: OperatorType.MULT.literal
                        case ASSIGNOR: OperatorType.LOGICAL_OR.literal
                        case ASSIGNSHIFTLEFT: OperatorType.SHIFT_LEFT.literal
                        case ASSIGNSHIFTRIGHT: OperatorType.SHIFT_RIGHT.literal
                        case ASSIGNSHIFTRIGHTUNSIGNED: OperatorType.SHIFT_RIGHT_UNSIGNED.literal
                        case ASSIGNSUB: OperatorType.SUB.literal
                        case ASSIGNXOR: OperatorType.BITWISE_XOR.literal
                        case POSTFIXADD: "++"
                        case POSTFIXSUB: "--"
                        default: throw new IllegalArgumentException("Wrong update operator")
                    }
                    expression = createStringValue(op)
                ]
                parameters += createParameter => [
                    expression = assignments.createScheduledExpression(ssaReferences)
                ]
                parameters += createParameter => [
                    ssaReferences.put(head, it)
                    expression = head.valuedObject.reference
                ]
            ]
        } else {
            return SEQ.createFunction => [
                parameters += createParameter => [
                    expression = assignments.createScheduledExpression(ssaReferences)
                ]
                parameters += createParameter => [
                    ssaReferences.put(head, it)
                    expression = head.valuedObject.reference
                ]
            ]
        }
    }
    
    // -------------------------------------------------------------------------
    // Processing of merge expressions
    // -------------------------------------------------------------------------

    def Expression reduce(Expression ssaFunction) {
        if (ssaFunction instanceof FunctionCall) {
            var changed = true
            var fcalls = ssaFunction.eAllContents.filter(FunctionCall).toList
            fcalls.add(ssaFunction)
            fcalls = fcalls.reverseView
            // reduce function
            while (changed) {
                changed = false
                for (fc : fcalls) {
                    if (fc.functionName == COMBINE.symbol) {
                        if (fc.parameters.size == 1 && fc.eContainer instanceof Parameter) {
                            fc.eContainer.remove
                        } else if (fc.parameters.size == 2) {
                            val container = fc.eContainer
                            if (container instanceof Parameter) {
                                container.expression = fc.parameters.get(1).expression
                            }
                        }
                    } else {
                        if (fc.parameters.size == 0 && fc.eContainer instanceof Parameter) {
                            fc.eContainer.remove
                        } else if (fc.parameters.size == 1) {
                            val container = fc.eContainer
                            if (container instanceof Parameter) {
                                container.expression = fc.parameters.head.expression
                            }
                        }
                    }
                }
                changed = fcalls.removeIf[eContainer === null]
            }
            // reduce nesting
            for (fc : fcalls) {
                if (fc.functionName == COMBINE.symbol) {
                    val read = fc.parameters.get(1).expression
                    if (read instanceof FunctionCall) {
                        if (read.functionName == COMBINE.symbol && fc.parameters.get(0).expression.equals(read.parameters.get(0).expression)) {
                            fc.parameters.remove(1)
                            fc.parameters.add(1, read.parameters.get(1))
                            fc.parameters.addAll(read.parameters.drop(1))
                        }
                    }
                } else {
                    var index = 0;
                    while (index < fc.parameters.size) {
                        val paramExp = fc.parameters.get(index).expression
                        if (paramExp instanceof FunctionCall) {
                            if (paramExp.functionName == fc.functionName) {
                                fc.parameters.remove(index)
                                fc.parameters.addAll(index, paramExp.parameters)
                                paramExp.parameters.clear
                                index-- // do not increment to analyze first inserted parameter next
                            }
                        }
                        index++
                    }
                }
            }
            if (ssaFunction.functionName == COMBINE.symbol && ssaFunction.parameters.size == 2) {
                return ssaFunction.parameters.get(1).expression
            } else if (ssaFunction.parameters.size == 1) {
                return ssaFunction.parameters.head.expression
            }
        }
        return ssaFunction
    }
    
    def Expression normalize(Expression ssaFunction) {
        val reduced = ssaFunction.reduce
        if (reduced instanceof FunctionCall) {
            var fcalls = reduced.eAllContents.filter(FunctionCall).toList
            fcalls.add(reduced)
            fcalls = fcalls.reverseView
            for (fc : fcalls) {
                if (fc.functionName == COMBINE.symbol) {
                    val combineFunctionName = (fc.parameters.head.expression as StringValue).value
                    if (fc.parameters.size > 3) {
                        for (i : 0..(fc.parameters.size - 4)) {
                            fc.parameters.add(1, createParameter => [
                                expression = createFunctionCall => [
                                    functionName = fc.functionName
                                    parameters += createParameter => [
                                        expression = createStringValue(combineFunctionName)
                                    ]
                                    parameters += fc.parameters.get(1)
                                    parameters += fc.parameters.get(1)
                                ]
                            ])
                        }
                    }    
                } else {
                    if (fc.parameters.size > 2 ) {
                        val paramsIter = fc.parameters.immutableCopy.iterator
                        var prev = paramsIter.next
                        while (paramsIter.hasNext) {
                            val next = paramsIter.next
                            if (paramsIter.hasNext) {
                                val param0 = prev.copy
                                val param1 = next
                                val func = createFunctionCall => [
                                    functionName = fc.functionName
                                ]
                                (next.eContainer as FunctionCall).parameters.remove(next)
                                func.parameters.addAll(param0, param1)
                                prev.expression = func
                            }
                        }
                    }
                }
            }
        }
        return reduced
    }
    
    // -------------------------------------------------------------------------
    // Utilities
    // -------------------------------------------------------------------------
    
    private def void addTo(Iterable<Parameter> parameters, EList<Parameter> list) {
        parameters.filterNull.forEach[list.add(it)]
    }

    private def void addTo(Parameter parameter, EList<Parameter> list) {
        if (parameter !== null) {
            list.add(parameter)
        }
    }
 
    private def hasUpdates(SCGraph scg, ValuedObject vo) {
        return scg.nodes.filter(Assignment).filter[valuedObject == vo && !isOutputPreserver].exists[isUpdate]        
    }
 
    def getMergeExpressions(SCGraph scg) {
        val map = HashMultimap.create
        for (node : scg.nodes.filter(instanceOf(Assignment).or(instanceOf(Conditional)))) {
            val expr = if (node instanceof Assignment) node.expression else (node as Conditional).condition
            if (expr instanceof FunctionCall) {
                map.put(node, expr)
            } else if (expr instanceof OperatorExpression) {
                for (fc : expr.eAllContents.filter(FunctionCall).toIterable) {
                    if (!(fc.eContainer instanceof Parameter)) {
                        map.put(node, fc)
                    }
                }
            }
        }
        return map
    }
    
}

@Data
class MergeExpression {
    Expression expression
    Multimap<Assignment, Parameter> refs
}
