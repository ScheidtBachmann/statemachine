package de.cau.cs.kieler.sccharts.text.scoping

import com.google.inject.Inject
import de.cau.cs.kieler.kexpressions.KExpressionsPackage
import de.cau.cs.kieler.kexpressions.Parameter
import de.cau.cs.kieler.kexpressions.ReferenceDeclaration
import de.cau.cs.kieler.kexpressions.ValuedObject
import de.cau.cs.kieler.kexpressions.extensions.KExpressionsDeclarationExtensions
import de.cau.cs.kieler.kexpressions.kext.scoping.KExtScopeProvider
import de.cau.cs.kieler.sccharts.ControlflowRegion
import de.cau.cs.kieler.sccharts.Region
import de.cau.cs.kieler.sccharts.SCCharts
import de.cau.cs.kieler.sccharts.ScopeCall
import de.cau.cs.kieler.sccharts.State
import de.cau.cs.kieler.sccharts.Transition
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 *
 */
class SCTXScopeProvider extends KExtScopeProvider {
    
//    @Inject extension SCChartsCoreExtensions
//    @Inject extension AnnotationsExtensions
    @Inject extension KExpressionsDeclarationExtensions
    
//    @Inject SCTXQualifiedNameProvider nameProvider

    override getScope(EObject context, EReference reference) {
//        println(context + "\n  " + reference)
        
        switch(context) {
            Transition: return getScopeForTransition(context, reference)
            State: return getScopeForState(context, reference)
            ScopeCall: return getScopeForScopeCall(context, reference)  
        }
        
        return super.getScope(context, reference);
    }
    
    protected def IScope getScopeForTransition(Transition transition, EReference reference) {
        val states = <State> newArrayList
        val parentState = transition.eContainer as State
        val parentRegion = parentState.eContainer as ControlflowRegion
        
        parentRegion.states.forEach[ 
            states += it 
        ]
        
        return Scopes.scopeFor(states)
    }
    
    protected def IScope getScopeForState(State state, EReference reference) {
        if (reference.name.equals("scope")) {
            val eResource = state.eResource
            if (eResource !== null) {
                val scchartsInScope = newHashSet(eResource.contents.head as SCCharts)
                val eResourceSet = eResource.resourceSet
                if (eResourceSet !== null) {
                    eResourceSet.resources.filter[!contents.empty].map[contents.head].filter(SCCharts).forEach[ 
                        scchartsInScope += it
                    ]
                }
                return Scopes.scopeFor(scchartsInScope.map[rootStates].flatten)
            }
            
            return IScope.NULLSCOPE
        }
        
        return super.getScope(state, reference)
    }
    
    protected def IScope getScopeForScopeCall(ScopeCall scopeCall, EReference reference) {
        if (reference.name.equals("scope")) {
            val eResource = scopeCall.eResource
            if (eResource !== null) {
                val scchartsInScope = newHashSet(eResource.contents.head as SCCharts)
                val eResourceSet = eResource.resourceSet
                if (eResourceSet !== null) {
                    eResourceSet.resources.filter[!contents.empty].map[contents.head].filter(SCCharts).forEach[ 
                        scchartsInScope += it
                    ]
                }
                return Scopes.scopeFor(scchartsInScope.map[rootStates].flatten)
            }
            
            return IScope.NULLSCOPE
        }
        
        return super.getScope(scopeCall as EObject, reference)
    }
        
    override def IScope getScopeForParameter(Parameter parameter, EReference reference) {        
        if (reference.name.equals("explicitBinding")) {
            val voCandidates = <ValuedObject> newArrayList
            
            val scopeCall = parameter.eContainer as ScopeCall
            if (scopeCall !== null && scopeCall.scope !== null) {
                for (declaration : scopeCall.scope.variableDeclarations.filter[ input || output ]) {
                    voCandidates += declaration.valuedObjects
                }
            }
            
            return Scopes.scopeFor(voCandidates)
        }
        
        return super.getScopeForParameter(parameter, reference)
    }
    
    override def IScope getScopeForReferenceDeclaration(EObject context, EReference reference) {
        if (reference == KExpressionsPackage.Literals.REFERENCE_DECLARATION__REFERENCE) {
            
            val declaration = context
            if (declaration instanceof ReferenceDeclaration) {
                val eResource = declaration.eResource
                if (eResource !== null) {
                    val scchartsInScope = newHashSet(eResource.contents.head as SCCharts)
                    val eResourceSet = eResource.resourceSet
                    if (eResourceSet !== null) {
                        eResourceSet.resources.filter[!contents.empty].map[contents.head].filter(SCCharts).forEach[ 
                            scchartsInScope += it
                        ]
                    }
                    return Scopes.scopeFor(scchartsInScope.map[rootStates].flatten)
                }   
                
                return IScope.NULLSCOPE
            }
        } 
        return context.getScopeHierarchical(reference)
    }       

    override def IScope getScopeHierarchical(EObject context, EReference reference) {
        val candidates = <ValuedObject> newArrayList
        var declarationScope = context.nextDeclarationScope
        while (declarationScope !== null) {
            for(declaration : declarationScope.declarations) {
                for(VO : declaration.valuedObjects) {
                    candidates += VO
                }
            }   
            
            // Add for regions counter variable            
            if (declarationScope instanceof Region) {
                if (declarationScope.counterVariable !== null) {
                    candidates += declarationScope.counterVariable
                }
            }
            
            declarationScope = declarationScope.nextDeclarationScope
        }
        return Scopes.scopeFor(candidates)
    }

}