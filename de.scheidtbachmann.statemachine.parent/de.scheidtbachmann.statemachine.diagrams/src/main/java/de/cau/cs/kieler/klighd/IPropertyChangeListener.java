package de.cau.cs.kieler.klighd;

public interface IPropertyChangeListener {
	/**
	 * Notification that a property has changed.
	 * <p>
	 * This method gets called when the observed object fires a property
	 * change event.
	 * </p>
	 *
	 * @param event the property change event object describing which property
	 * changed and how
	 */
	public void propertyChange(PropertyChangeEvent event);
	
	interface PropertyChangeEvent {
		/**
		 * Returns the new value of the property.
		 *
		 * @return the new value, or <code>null</code> if not known
		 *  or not relevant (for instance if the property was removed).
		 */
		Object getNewValue();
		
		/**
		 * Returns the old value of the property.
		 *
		 * @return the old value, or <code>null</code> if not known
		 *  or not relevant (for instance if the property was just
		 *  added and there was no old value).
		 */
		Object getOldValue();
		
		/**
		 * Returns the name of the property that changed.
		 * <p>
		 * Warning: there is no guarantee that the property name returned
		 * is a constant string.  Callers must compare property names using
		 * equals, not ==.
		 * </p>
		 *
		 * @return the name of the property that changed
		 */
		String getProperty();
	}
}
