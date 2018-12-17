package de.cau.cs.kieler.klighd

import org.eclipse.core.runtime.IStatus
import org.eclipse.core.runtime.CoreException

class StatusManager {
	
	static val instance = new StatusManager()
	
	public static val NONE = 0
	public static val LOG = 1
	public static val SHOW = 2
	
	static def getManager() {
		instance
	}
	
	def void handle(IStatus status) {
		handle(status, StatusManager.LOG)
	}
	
	def void handle(IStatus status, int style) {
		println("Problem: " + status.exception?.message?:status.message)
	}
	
	def void handle(CoreException coreException,String pluginId) {
		// TODO do something smart
	}
}