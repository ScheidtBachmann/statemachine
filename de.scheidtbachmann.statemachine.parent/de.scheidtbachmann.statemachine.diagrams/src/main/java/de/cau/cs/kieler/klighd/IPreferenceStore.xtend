package de.cau.cs.kieler.klighd

interface IPreferenceStore {
	
	def boolean getBoolean(String preferenceId)
	
	def double getDouble(String preferenceId)
	
	def float getFloat(String preferenceId)
	
	def int getInt(String preferenceId)
	
	def String getString(String preferenceId)
	
	def void setDefault(String preferenceId, boolean value)
	
	def void setDefault(String preferenceId, double value)
	
	def void setDefault(String preferenceId, float value)
	
	def void setDefault(String preferenceId, int value)
	
	def void setDefault(String preferenceId, String value)
	
	def void addPropertyChangeListener(IPropertyChangeListener listener)
	
	def void removePropertyChangeListener(IPropertyChangeListener listener)
	
	static class NullPreferenceStore implements IPreferenceStore {
		
		val defaults = newHashMap
		
		override getBoolean(String preferenceId) {
			switch value: defaults.get(preferenceId) {
				Boolean: value.booleanValue
				default: false
			}
		}
		
		override getDouble(String preferenceId) {
			switch value: defaults.get(preferenceId) {
				Double: value.doubleValue
				default: 0
			}
		}
		
		override getFloat(String preferenceId) {
			switch value: defaults.get(preferenceId) {
				Float: value.floatValue
				default: 0
			}
		}
		
		override getInt(String preferenceId) {
			switch value: defaults.get(preferenceId) {
				Integer: value.intValue
				default: 0
			}
		}
		
		override getString(String preferenceId) {
			switch value: defaults.get(preferenceId) {
				String: value
				default: null
			}
		}
		
		override setDefault(String preferenceId, boolean value) {
			defaults.put(preferenceId, Boolean.valueOf(value))
		}
		
		override setDefault(String preferenceId, double value) {
			defaults.put(preferenceId, Double.valueOf(value))
		}
		
		override setDefault(String preferenceId, float value) {
			defaults.put(preferenceId, Float.valueOf(value))
		}
		
		override setDefault(String preferenceId, int value) {
			defaults.put(preferenceId, Integer.valueOf(value))
		}
		
		override setDefault(String preferenceId, String value) {
			defaults.put(preferenceId, value)
		}
		
		override addPropertyChangeListener(IPropertyChangeListener listener) {
			// TODO do something smart
		}
		
		override removePropertyChangeListener(IPropertyChangeListener listener) {
			// TODO do something smart
		}
	}
}