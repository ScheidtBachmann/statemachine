/********************************************************************************
 * Copyright (c) 2018 Scheidt&Bachmann ST GmbH and others.
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

/** @jsx svg */
import { svg } from 'snabbdom-jsx';

import { RenderingContext, RectangularNodeView, IView, SLabel } from "sprotty/lib";
import { VNode } from "snabbdom/vnode";
import { Icon, ClassNode, StateNode } from './model';

export class StateNodeView extends RectangularNodeView {
    render(node: StateNode, context: RenderingContext): VNode {
        return <g class-stateNode={true}>
            <rect class-stateFigure={true}
                  x={0} y={0} rx = {17} ry = {17}
                  width={node.bounds.width} height={node.bounds.height} />
            {context.renderChildren(node)}
        </g>;
    }
}

export class StateLabelView implements IView {
    render(label: Readonly<SLabel>, context: RenderingContext): VNode {
        return <text>{label.text}</text>;
        // const subType = getSubType(label);
        // if (subType)
        //     setAttr(vnode, 'class', subType);
        // return vnode;
    }
}


export class ClassNodeView extends RectangularNodeView {
    render(node: ClassNode, context: RenderingContext): VNode {
        return <g class-node={true}>
            <rect class-sprotty-node={true} class-selected={node.selected} class-mouseover={node.hoverFeedback}
                  x={0} y={0}
                  width={Math.max(0, node.bounds.width)} height={Math.max(0, node.bounds.height)} />
            {context.renderChildren(node)}
        </g>;
    }
}

export class IconView implements IView {

    render(element: Icon, context: RenderingContext): VNode {
        const radius = this.getRadius();
        return <g>
            <circle class-sprotty-icon={true} r={radius} cx={radius} cy={radius}></circle>
            {context.renderChildren(element)}
        </g>;
    }

    getRadius() {
        return 16;
    }
}
