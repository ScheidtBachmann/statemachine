/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2015 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.sccharts.ui.synthesis;

import java.lang.reflect.ParameterizedType;
import java.util.Collections;
import java.util.List;

import org.eclipse.emf.ecore.EObject;

import com.google.inject.Inject;

import de.cau.cs.kieler.klighd.SynthesisOption;
import de.cau.cs.kieler.klighd.ViewContext;
import de.cau.cs.kieler.klighd.kgraph.KGraphElement;
import de.cau.cs.kieler.klighd.kgraph.KNode;
import de.cau.cs.kieler.klighd.krendering.ViewSynthesisShared;
import de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis;
import de.cau.cs.kieler.sccharts.ui.synthesis.hooks.ISynthesisHooks;
import de.cau.cs.kieler.sccharts.ui.synthesis.hooks.SynthesisHooks;
import de.cau.cs.kieler.sccharts.ui.synthesis.hooks.SynthesisHooks.Type;

/**
 * Abstract class for partial syntheses, delegating helper methods.
 * 
 * @author als ssm
 * @kieler.design 2015-08-13 proposed
 * @kieler.rating 2015-08-13 proposed yellow
 * 
 */
@ViewSynthesisShared
@SuppressWarnings("unchecked")
public abstract class AbstractSubSynthesis<I extends EObject, O extends KGraphElement> {

    @Inject
    protected SCChartsSynthesis parent;
    
    /** The input type this synthesis handles */
    protected final Type hookType;
    /** Prefix for the resource location when loading KGTs from the bundle **/
    protected static String SKIN_FOLDER = "resources/skins/";
    protected static String skinPrefix = "default/";
    
    @Inject
    public AbstractSubSynthesis() {
        java.lang.reflect.Type[] generics =
                ((ParameterizedType) getClass().getGenericSuperclass()).getActualTypeArguments();
        
        // Get hook type from input generic type
        this.hookType = SynthesisHooks.getType((Class<? extends EObject>) generics[0]);
    }
    
    abstract protected ISynthesisHooks getHooks();

    /**
     * Transforms the given element into a diagram element and invokes hooks correctly.
     * 
     * @param element
     *            the model element to transform.
     * @return the transformed diagram element.
     */
    public final List<O> transform(I element) {
        List<O> result = performTranformation(element);
        ISynthesisHooks hooks = getHooks();
        if (hooks != null) {
            for(O ele : result) {
                hooks.invokeHooks(hookType, element, ele);
            }
        }
        return result;
    }

    /**
     * Performs the actual transformation on the given element.
     * 
     * @param element
     *            the model element to transform.
     * @return the transformed diagram element.
     */
    abstract public List<O> performTranformation(I element);

    /**
     * The {@link SynthesisOption} this hook contributes to the synthesis.
     * 
     * @see de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis#getDisplayedSynthesisOptions()
     */
    public List<SynthesisOption> getDisplayedSynthesisOptions() {
        return Collections.emptyList();
    }

    // -------------------------------------------------------------------------
    // Delegate from AbstractDiagramSynthesis

    /**
     * @param derived
     * @param source
     * @return
     * @see de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis#associateWith(org.eclipse.emf.ecore.EObject,
     *      java.lang.Object)
     */
    public <T extends EObject> T associateWith(T derived, Object source) {
        return parent.associateWith(derived, source);
    }

    /**
     * @param option
     * @return
     * @see de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis#getObjectValue(de.cau.cs.kieler.klighd.SynthesisOption)
     */
    public Object getObjectValue(SynthesisOption option) {
        return parent.getObjectValue(option);
    }

    /**
     * @param option
     * @return
     * @see de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis#getBooleanValue(de.cau.cs.kieler.klighd.SynthesisOption)
     */
    public boolean getBooleanValue(SynthesisOption option) {
        return parent.getBooleanValue(option);
    }

    /**
     * @param option
     * @return
     * @see de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis#getIntValue(de.cau.cs.kieler.klighd.SynthesisOption)
     */
    public int getIntValue(SynthesisOption option) {
        return parent.getIntValue(option);
    }

    /**
     * @param option
     * @return
     * @see de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis#getFloatValue(de.cau.cs.kieler.klighd.SynthesisOption)
     */
    public float getFloatValue(SynthesisOption option) {
        return parent.getFloatValue(option);
    }
    
    public ViewContext getUsedContext() {
        return parent.getUsedContext();
    }
    
    /**
     * Loads a KGT from the bundle.
     * 
     * @param resourceLocation
     * @return the KNode from the KGT
     */
    public static KNode getKGTFromBundle(String resourceLocation) {
        return null; //KiCoolSynthesis.getKGTFromBundle(SCChartsUiModule.PLUGIN_ID, resourceLocation, SKIN_FOLDER + skinPrefix);
    }

}
