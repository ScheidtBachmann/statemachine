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

import {
    SShapeElement, Expandable, boundsFeature, expandFeature, fadeFeature, layoutContainerFeature, layoutableChildFeature, RectangularNode
} from "sprotty/lib";

export class StateNode extends RectangularNode implements Expandable {
    expanded: boolean = false;

    hasFeature(feature: symbol) {
        return feature === expandFeature || super.hasFeature(feature);
    }
}

export class ClassNode extends RectangularNode implements Expandable {
    expanded: boolean = false;

    hasFeature(feature: symbol) {
        return feature === expandFeature || super.hasFeature(feature);
    }
}

export class Icon extends SShapeElement {
    size = {
        width: 32,
        height: 32
    };

    hasFeature(feature: symbol): boolean {
        return feature === boundsFeature || feature === layoutContainerFeature || feature === layoutableChildFeature || feature === fadeFeature;
    }
}