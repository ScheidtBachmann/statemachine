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
package de.cau.cs.kieler.annotations.converter

import com.google.inject.Inject
import org.eclipse.xtext.conversion.impl.AbstractValueConverter
import org.eclipse.xtext.conversion.impl.IDValueConverter
import org.eclipse.xtext.nodemodel.INode

/**
 * @author ssm, als
 * @kieler.design 2017-06-15 proposed
 * @kieler.rating 2017-06-15 proposed yellow 
 */
class ExtendedIDValueConverter extends AbstractValueConverter<String> {
    
    @Inject extension IDValueConverter delegate
    
    override String toValue(String string, INode node) {
        if (string === null) return null;
        
        return string.split("\\.").map[delegate.toValue(it, node)].join(".").split("-").map[delegate.toValue(it, node)].join("-")
    }
            
    override String toString(String value) {
        // Escape each ID with the converter for identifiers
        return value.split("\\.").map[delegate.toString(it)].join(".").split("-").map[delegate.toString(it)].join("-")
    }
}