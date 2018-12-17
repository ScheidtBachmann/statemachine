/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2011 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.klighd.syntheses;

import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IConfigurationElement;
import org.eclipse.core.runtime.IExecutableExtension;
import org.eclipse.core.runtime.IExecutableExtensionFactory;
import org.eclipse.core.runtime.spi.RegistryContributor;
import org.eclipse.elk.core.util.WrappedException;

import de.cau.cs.kieler.klighd.Klighd;

/**
 * A generic factory for initializing classes that leverage dependency injection by means of Google
 * Guice and that need to be registered via Eclipse's extension mechanism. It is inspired by the
 * ...ExecutableExtensionFactory classes generated by Xtext.
 * 
 * @author chsch
 * 
 * @kieler.design proposed by chsch
 * @kieler.rating proposed yellow by chsch 
 */
public class GuiceBasedSynthesisFactory implements IExecutableExtension,
        IExecutableExtensionFactory {
    
    /** The fully qualified name of this class, to be used in error messages, for example. */
    public static final String CLASS_NAME = GuiceBasedSynthesisFactory.class.getCanonicalName();

    /** This bundleId is a {@link Long} value in shape of a String.
     * It must not be confused with the bundle id determined in the bundles' manifests. */
    private String contributingBundleId;
    
    /** This is an id as determined in the bundles' manifests. */
    private String contributingBundleName;
    
    /** Obvious... */
    private String transformationClassName;

    
    /**
     * {@inheritDoc}
     */
    public void setInitializationData(final IConfigurationElement config,
            final String propertyName, final Object data) throws CoreException {
        // implementation inspired by org.eclipse.core.internal.registry.ConfigurationElement
        if (propertyName.equals("class") && data instanceof String) {
            final String string = (String) data;
            final int index = string.indexOf('/');
            if (index == -1) {
                this.contributingBundleId = ((RegistryContributor) config.getContributor()).getId();
                this.transformationClassName = string;
            } else {
                /* for experimental use I want to allow to register transformations that are
                 * deposited in another plug-in;
                 * in order to use this specify a the class name preceded by a '/' preceded by
                 * the contributing bundles symbolic name (id) */
                this.contributingBundleName = string.substring(0, index).trim();
                this.transformationClassName = string.substring(index + 1).trim();
            }
        }
    }

    
    /**
     * {@inheritDoc}
     */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    public Object create() throws CoreException {
        try {
            Class<?> clazz = null;
            // chsch: noticed bug, need to explore the duality of 'contributingBundleId' and
            //  'contributingBundleName'; should be due to some API shortcomings
            //  is tracked in KIELER-2166
//            if (Strings.isNullOrEmpty(this.contributingBundleName)) {
//                final Bundle contributingBundle = Klighd.getDefault().getBundle()
//                        .getBundleContext().getBundle(Long.parseLong(this.contributingBundleId));
//                clazz = contributingBundle.loadClass(transformationClassName);
//            } else {
                clazz = Klighd.loadClass(contributingBundleName, transformationClassName);
//            }
            
            return new ReinitializingDiagramSynthesisProxy(clazz);
        } catch (final ClassNotFoundException e) {
            throw new WrappedException(
                "KLighD: Registered diagram synthesis class could not be loaded properly via the "
                + GuiceBasedSynthesisFactory.class.getSimpleName()
                + ". Did you miss to provide the related bundle id in the extension (plugin.xml)?", e);
        }
    }
}
