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
package de.cau.cs.kieler.scg.processors.optimizer

import com.google.inject.Inject
import de.cau.cs.kieler.kexpressions.ValuedObjectReference
import de.cau.cs.kieler.scg.Assignment
import de.cau.cs.kieler.scg.ControlFlow
import de.cau.cs.kieler.scg.SCGraph

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import com.google.common.collect.ImmutableList
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsValuedObjectExtensions
import de.cau.cs.kieler.kexpressions.keffects.extensions.KEffectsExtensions
import de.cau.cs.kieler.scg.extensions.SCGControlFlowExtensions

/**
 * @author ssm
 *
 */
 
class UnreferencedGuardElimination extends AbstractOptimizer {
    
    @Inject extension KExpressionsValuedObjectExtensions
    @Inject extension KEffectsExtensions
    @Inject extension SCGControlFlowExtensions
    
    private static val GUARDNAME = "guard" 
    
    private val unreferencedAssignments = <Assignment> newArrayList
    
    override optimize(SCGraph scg) {
    	val allContents = scg.eAllContents
        scg.nodes.filter(typeof(Assignment)).forEach[ ass |
            if (ass.valuedObject.name.contains(GUARDNAME)) {
            	if (allContents.filter(typeof(ValuedObjectReference)).filter[ valuedObject == ass.valuedObject].size == 0) {
	                unreferencedAssignments += ass
                }
            }    
        ]  
        
        val ic = ImmutableList::copyOf(unreferencedAssignments)  
        
        ic.forEach[ ra |
            val incoming = ImmutableList::copyOf(ra.incomingLinks.filter(typeof(ControlFlow)))
            incoming.forEach[ target = ra.next.targetNode ]
            
            ra.valuedObject.removeFromContainmentAndCleanup
            ra.next.target.incomingLinks -= ra.next
            ra.remove
        ]
        
        scg
    }
    
}