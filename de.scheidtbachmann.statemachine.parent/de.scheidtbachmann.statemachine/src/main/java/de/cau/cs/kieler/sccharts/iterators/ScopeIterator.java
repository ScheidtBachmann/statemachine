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
package de.cau.cs.kieler.sccharts.iterators;

import java.util.Collections;
import java.util.Iterator;

import org.eclipse.emf.common.util.AbstractTreeIterator;

import de.cau.cs.kieler.sccharts.ControlflowRegion;
import de.cau.cs.kieler.sccharts.Region;
import de.cau.cs.kieler.sccharts.Scope;
import de.cau.cs.kieler.sccharts.State;

/**
 * @author ssm
 * @kieler.design 2015-09-03 proposed 
 * @kieler.rating 2015-09-03 proposed yellow
 */
public final class ScopeIterator {

  
    public static Iterator<Scope> sccAllScopes(Scope s) {
        return new AbstractTreeIterator<Scope>(s, true) {

            private static final long serialVersionUID = -4364507280963568558L;

            @Override
            protected Iterator<? extends Scope> getChildren(Object object) {
                if (object instanceof State) {
                    final Iterator<Region> regions = ((State) object).getRegions().iterator();
                    return regions;
                } else if (object instanceof ControlflowRegion) {
                    final Iterator<State> states = ((ControlflowRegion) object).getStates().iterator();
                    return states;
                } else {
                    return Collections.emptyIterator();
                }
            }

        };
    }
}
