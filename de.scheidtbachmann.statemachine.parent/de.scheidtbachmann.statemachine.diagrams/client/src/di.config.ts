/********************************************************************************
 * Copyright (c) 2017-2018 TypeFox and others.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * This Source Code may also be made available under the following Secondary
 * Licenses when the conditions for such availability set forth in the Eclipse
 * Public License v. 2.0 are satisfied: GNU General Public License, version 2
 * with the GNU Classpath Exception which is available at
 * https://www.gnu.org/software/classpath/license.html.
 *
 * SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0
 ********************************************************************************/

import { Container, ContainerModule } from "inversify";
import {
    defaultModule, TYPES, configureViewerOptions, SGraphView, SLabelView, SCompartmentView, PolylineEdgeView,
    ConsoleLogger, LogLevel, /*WebSocketDiagramServer,*/ boundsModule, moveModule, selectModule, undoRedoModule,
    viewportModule, hoverModule, LocalModelSource, HtmlRootView, PreRenderedView, exportModule, expandModule,
    fadeModule, ExpandButtonView, buttonModule, /*edgeEditModule,*/ SRoutingHandleView, SGraphFactory,
    PreRenderedElement, HtmlRoot, SGraph, configureModelElement, SLabel, SCompartment, SEdge, SButton, SRoutingHandle
} from "sprotty/lib";
import { IconView, StateNodeView, StateLabelView, TransitionEdgeView} from "./views";
import { PopupModelProvider } from "./popup";
import { ModelProvider } from './model-provider';
import { Icon, StateNode } from "./model";
import { elkLayoutModule, ElkFactory, ElkLayoutEngine } from "sprotty-elk/lib";
import ElkConstructor from 'elkjs/lib/elk.bundled';

const elkFactory: ElkFactory = () => new ElkConstructor({
    // workerUrl: 'elk/elk-worker.min.js',
    algorithms: ['layered']
});

export default (/* useWebsocket: boolean, */ containerId: string) => {
    const stateMachineDiagramModule = new ContainerModule((bind, unbind, isBound, rebind) => {
        /* if (useWebsocket)
            bind(TYPES.ModelSource).to(WebSocketDiagramServer).inSingletonScope();
        else */
            bind(TYPES.ModelSource).to(LocalModelSource).inSingletonScope();
        rebind(TYPES.ILogger).to(ConsoleLogger).inSingletonScope();
        rebind(TYPES.LogLevel).toConstantValue(LogLevel.log);
        rebind(TYPES.IModelFactory).to(SGraphFactory).inSingletonScope();
        bind(TYPES.IPopupModelProvider).to(PopupModelProvider);
        bind(TYPES.StateAwareModelProvider).to(ModelProvider);
        bind(TYPES.IModelLayoutEngine).to(ElkLayoutEngine);
        bind(ElkFactory).toConstantValue(elkFactory);

        const context = { bind, unbind, isBound, rebind };
        configureModelElement(context, 'graph', SGraph, SGraphView);
        configureModelElement(context, 'label:heading', SLabel, SLabelView);
        configureModelElement(context, 'node:state', StateNode, StateNodeView);
        configureModelElement(context, 'label:stateLabel', SLabel, StateLabelView);
        configureModelElement(context, 'edge:transition', SEdge, TransitionEdgeView);
        configureModelElement(context, 'label:text', SLabel, SLabelView);
        configureModelElement(context, 'comp:comp', SCompartment, SCompartmentView);
        configureModelElement(context, 'comp:header', SCompartment, SCompartmentView);
        configureModelElement(context, 'icon', Icon, IconView);
        configureModelElement(context, 'label:icon', SLabel, SLabelView);
        configureModelElement(context, 'edge:straight', SEdge, PolylineEdgeView);
        configureModelElement(context, 'html', HtmlRoot, HtmlRootView);
        configureModelElement(context, 'pre-rendered', PreRenderedElement, PreRenderedView);
        configureModelElement(context, 'button:expand', SButton, ExpandButtonView);
        configureModelElement(context, 'routing-point', SRoutingHandle, SRoutingHandleView);
        configureModelElement(context, 'volatile-routing-point', SRoutingHandle, SRoutingHandleView);
        configureViewerOptions(context, {
            // the default settings are currently sufficient
            // needsClientLayout: true,
            // baseDiv: containerId
        });
    });

    const container = new Container();
    container.load(defaultModule, selectModule, moveModule, boundsModule, undoRedoModule,
        viewportModule, fadeModule, hoverModule, exportModule, expandModule, buttonModule,
        /* edgeEditModule, */ stateMachineDiagramModule, elkLayoutModule);
    return container;
};
