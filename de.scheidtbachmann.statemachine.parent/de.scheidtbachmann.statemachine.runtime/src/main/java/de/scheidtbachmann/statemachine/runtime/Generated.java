// ******************************************************************************
//
// Copyright (c) 2023 by
// Scheidt & Bachmann System Technik GmbH, 24109 Melsdorf
//
// This program and the accompanying materials are made available under the terms of the
// Eclipse Public License v2.0 which accompanies this distribution, and is available at
// https://www.eclipse.org/legal/epl-v20.html
//
// ******************************************************************************

package de.scheidtbachmann.statemachine.runtime;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

/**
 * Annotation to mark the generated code as generated.
 * This is used instead of javax.annotation.Generated, to have a {@link RetentionPolicy} that is persisted in the class
 * files.
 */
@Retention(RetentionPolicy.RUNTIME)
public @interface Generated {
    String message();
}
