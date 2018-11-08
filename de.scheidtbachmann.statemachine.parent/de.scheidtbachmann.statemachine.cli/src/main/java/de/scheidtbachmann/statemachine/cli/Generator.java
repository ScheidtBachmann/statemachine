package de.scheidtbachmann.statemachine.cli;

import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;

import com.google.inject.Injector;

import de.scheidtbachmann.statemachine.StateMachineStandaloneSetup;

public class Generator {

	public static void main(String[] args) {
		// initial code just for making sure the required infrastructure can be loaded properly 
		final Injector i = new StateMachineStandaloneSetup().createInjectorAndDoEMFRegistration();
		ResourceSet set = i.getInstance(ResourceSet.class);
		Resource res = set.createResource(URI.createFileURI("foo.sm"));
		System.out.println(res.getURI().toString());
	}
}
