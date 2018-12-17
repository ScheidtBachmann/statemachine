/*******************************************************************************
 * Copyright (c) 2011, 2017 Kiel University and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.elk.core.service;

import java.util.LinkedList;
import java.util.List;
import java.util.Set;

import org.eclipse.core.runtime.IStatus;
import org.eclipse.elk.core.LayoutConfigurator;
import org.eclipse.elk.core.LayoutConfigurator.IOptionFilter;
import org.eclipse.elk.core.data.LayoutMetaDataService;
import org.eclipse.elk.core.data.LayoutOptionData;
import org.eclipse.elk.core.options.CoreOptions;
import org.eclipse.elk.core.util.IElkCancelIndicator;
import org.eclipse.elk.core.util.IElkProgressMonitor;
import org.eclipse.elk.graph.ElkEdge;
import org.eclipse.elk.graph.ElkLabel;
import org.eclipse.elk.graph.ElkNode;
import org.eclipse.elk.graph.ElkPort;
import org.eclipse.elk.graph.properties.IProperty;
import org.eclipse.elk.graph.properties.IPropertyHolder;
import org.eclipse.elk.graph.properties.MapPropertyHolder;
import org.eclipse.elk.graph.properties.Property;

import com.google.inject.Singleton;

/**
 * The entry class for automatic layout of graphical diagrams.
 * Use this class to perform automatic layout on the content of a workbench part that contains
 * a graph-based diagram. The mapping between the diagram and the layout graph structure is managed
 * by a {@link IDiagramLayoutConnector} implementation, which has to be registered using the
 * {@code layoutConnectors} extension point.
 * 
 * <p>Subclasses of this class can be bound in an {@link ILayoutSetup} injector for customization.
 * Note that this class is marked as {@link Singleton}, which means that exactly one instance is
 * created for each injector, i.e. for each registered {@link ILayoutSetup}.</p>
 */
@Singleton
public class DiagramLayoutEngine {
    
    /**
     * Configuration class for invoking the {@link DiagramLayoutEngine}.
     * Use a {@link LayoutConfigurator} to configure layout options:
     * <pre>
     * DiagramLayoutEngine.Parameters params = new DiagramLayoutEngine.Parameters();
     * params.addLayoutRun().configure(KNode.class)
     *         .setProperty(LayoutOptions.ALGORITHM, "org.eclipse.elk.algorithm.layered")
     *         .setProperty(LayoutOptions.SPACING, 30.0f)
     *         .setProperty(LayoutOptions.ANIMATE, true);
     * DiagramLayoutEngine.invokeLayout(workbenchPart, diagramPart, params);
     * </pre>
     * If multiple configurators are given, the layout is computed multiple times:
     * once for each configurator. This behavior can be used to apply different layout algorithms
     * one after another, e.g. first a node placer algorithm and then an edge router algorithm.
     * Example:
     * <pre>
     * DiagramLayoutEngine.Parameters params = new DiagramLayoutEngine.Parameters();
     * params.addLayoutRun().configure(KNode.class)
     *         .setProperty(LayoutOptions.ALGORITHM, "org.eclipse.elk.force");
     * params.addLayoutRun().setClearLayout(true).configure(KNode.class)
     *         .setProperty(LayoutOptions.ALGORITHM, "org.eclipse.elk.layered");
     * DiagramLayoutEngine.invokeLayout(workbenchPart, diagramPart, params);
     * </pre>
     * <b>Note:</b> By using the {@link LayoutConfigurator} approach as shown above, the Layout
     * view does not have any access to the configured values and hence will not work correctly.
     * In order to support the Layout view, use the {@link ILayoutConfigurationStore} interface instead.
     */
    public static final class Parameters {
        
        private List<LayoutConfigurator> configurators = new LinkedList<LayoutConfigurator>();
        private MapPropertyHolder globalSettings = new MapPropertyHolder();
        @SuppressWarnings("unused")
		private boolean overrideDiagramConfig = true;
        
        /**
         * Set whether to override the configuration from the {@link ILayoutConfigurationStore}
         * provided by the diagram layout manager with the configuration provided by this setup.
         * The default is {@code true}.
         */
        public Parameters setOverrideDiagramConfig(final boolean override) {
            this.overrideDiagramConfig = override;
            return this;
        }
        
        /**
         * Returns the global settings, i.e. options that are not processed by layout algorithms,
         * but by layout managers or the layout engine itself.
         */
        public IPropertyHolder getGlobalSettings() {
            return globalSettings;
        }
        
        /**
         * Add a layout run with the given configurator. Each invocation of this method corresponds
         * to a separate layout execution on the whole input graph. This can be used to apply
         * multiple layout algorithms one after another, where each algorithm execution can reuse
         * results from previous executions.
         * 
         * @return the given configurator
         */
        public LayoutConfigurator addLayoutRun(final LayoutConfigurator configurator) {
            configurators.add(configurator);
            configurator.addFilter(OPTION_TARGET_FILTER);
            return configurator;
        }
        
        /**
         * Convenience method for {@code addLayout(new LayoutConfigurator())}.
         */
        public LayoutConfigurator addLayoutRun() {
            return addLayoutRun(new LayoutConfigurator());
        }
    }
    
    /** preference identifier for debug graph output. */
    public static final String PREF_DEBUG_OUTPUT = "elk.debug.graph";
    /** preference identifier for execution time measurement. */
    public static final String PREF_EXEC_TIME_MEASUREMENT = "elk.exectime.measure";
    
    /**
     * Filter for {@link LayoutConfigurator} that checks for each option whether its configured targets
     * match the input element.
     */
    public static final IOptionFilter OPTION_TARGET_FILTER =
        (e, property) -> {
            LayoutOptionData optionData = LayoutMetaDataService.getInstance().getOptionData(property.getId());
            if (optionData != null) {
                Set<LayoutOptionData.Target> targets = optionData.getTargets();
                if (e instanceof ElkNode) {
                    if (!((ElkNode) e).isHierarchical()) {
                        return targets.contains(LayoutOptionData.Target.NODES);
                    } else {
                        return targets.contains(LayoutOptionData.Target.NODES)
                                || targets.contains(LayoutOptionData.Target.PARENTS);
                    }
                } else if (e instanceof ElkEdge) {
                    return targets.contains(LayoutOptionData.Target.EDGES);
                } else if (e instanceof ElkPort) {
                    return targets.contains(LayoutOptionData.Target.PORTS);
                } else if (e instanceof ElkLabel) {
                    return targets.contains(LayoutOptionData.Target.LABELS);
                }
            }
            return true;
        };
    
    /**
     * Property for the diagram layout connector used for automatic layout. This property is
     * attached to layout mappings created by the {@code layout} methods.
     */
    public static final IProperty<IDiagramLayoutConnector> MAPPING_CONNECTOR
            = new Property<IDiagramLayoutConnector>("layoutEngine.diagramLayoutConnector");
    /**
     * Property for the status result of automatic layout. This property is attached to layout
     * mappings created by the {@code invokeLayout} methods.
     */
    public static final IProperty<IStatus> MAPPING_STATUS
            = new Property<IStatus>("layoutEngine.status");

    /**
     * Perform layout on the given workbench part with the given global options.
     * 
     * @param workbenchPart
     *            the workbench part for which layout is performed
     * @param diagramPart
     *            the parent diagram part for which layout is performed, or {@code null} if the whole
     *            diagram shall be arranged
     * @param animate
     *            if true, animation is activated (if supported by the diagram connector)
     * @param progressBar
     *            if true, a progress bar is displayed
     * @param layoutAncestors
     *            if true, layout is not only performed for the selected diagram part, but also for
     *            its ancestors
     * @param zoomToFit
     *            if true, automatic zoom-to-fit is activated (if supported by the diagram connector)
     * @return the layout mapping used in this operation
     */
    public static LayoutMapping invokeLayout(final Object workbenchPart, final Object diagramPart,
            final boolean animate, final boolean progressBar, final boolean layoutAncestors,
            final boolean zoomToFit) {
        Parameters params = new Parameters();
        params.getGlobalSettings()
            .setProperty(CoreOptions.ANIMATE, animate)
            .setProperty(CoreOptions.PROGRESS_BAR, progressBar)
            .setProperty(CoreOptions.LAYOUT_ANCESTORS, layoutAncestors)
            .setProperty(CoreOptions.ZOOM_TO_FIT, zoomToFit);
        return invokeLayout(workbenchPart, diagramPart, params);
    }
    
    /**
     * Perform layout on the given workbench part with the given setup.
     * 
     * @param workbenchPart
     *            the workbench part for which layout is performed
     * @param diagramPart
     *            the parent diagram part for which layout is performed, or {@code null} if the whole
     *            diagram shall be layouted
     * @param params
     *            layout parameters, or {@code null} to use default values
     * @return the layout mapping used in this operation
     */
    public static LayoutMapping invokeLayout(final Object workbenchPart, final Object diagramPart,
            final Parameters params) {
        return invokeLayout(workbenchPart, diagramPart, (IElkCancelIndicator) null, params);
    }

    /**
     * Perform layout on the given workbench part and diagram part. This static method creates an instance
     * of {@link DiagramLayoutEngine} using a {@link LayoutConnectorsService} injector and delegates the
     * operation to that instance.
     * 
     * <p>Depending on the {@code cancelIndicator} argument, different methods of the created engine
     * may be used: either the one taking an {@link IElkCancelIndicator} as argument, or the one taking
     * an {@link IElkProgressMonitor} as argument (the latter inherits from the former).</p>
     * 
     * <p>{@code workbenchPart} and {@code diagramPart} must not be {@code null} at the same time.</p>
     * 
     * @param workbenchPart
     *            the workbench part for which layout is performed, or {@code null}
     * @param diagramPart
     *            the parent diagram part for which layout is performed, or {@code null} if the whole
     *            diagram shall be layouted
     * @param cancelIndicator
     *            an {@link IElkCancelIndicator} to be evaluated repeatedly during the layout operation,
     *            or an {@link IElkProgressMonitor} to which progress is reported, or {@code null}
     * @param params
     *            layout parameters, or {@code null} to use default values
     * @return the layout mapping used in this operation, or {@code null} if the workbench part and diagram
     *            part cannot be identified by the {@link LayoutConnectorsService}
     */
    public static LayoutMapping invokeLayout(final Object workbenchPart, final Object diagramPart,
            final IElkCancelIndicator cancelIndicator, final Parameters params) {
        // chsch: removed implementation, as just the API is needed  
        return null;
    }
    
    
    
    //--------------------- NON-STATIC PART (customizable via dependency injection) ---------------------//
    
}
