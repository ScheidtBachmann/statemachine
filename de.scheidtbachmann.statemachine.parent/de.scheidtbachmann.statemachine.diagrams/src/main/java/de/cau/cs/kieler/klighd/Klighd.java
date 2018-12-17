package de.cau.cs.kieler.klighd;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;

import org.eclipse.core.runtime.IConfigurationElement;
import org.eclipse.core.runtime.Platform;
import org.osgi.framework.Bundle;

import de.cau.cs.kieler.klighd.internal.preferences.PreferenceInitializer;

public class Klighd {

    /** the plug-in ID. */
    public static final String PLUGIN_ID = "de.cau.cs.kieler.klighd";

    /** A definition place of the platform-specific line separator. */
    public static final String LINE_SEPARATOR = System.getProperty("line.separator");

    /** A Boolean flag indicating that the tool is running on a linux system. */
    public static final boolean IS_LINUX;

    /** A Boolean flag indicating that the tool is running on a MacOSX system. */
    public static final boolean IS_MACOSX;

    /** A Boolean flag indicating that the tool is running on a Windows system. */
    public static final boolean IS_WINDOWS;
    
    /** A Boolean flag indicating that the tool is running in an equinox setup. */
    public static final boolean IS_PLATFORM_RUNNING;
    
    static {
        boolean isLinux = false;
        boolean isOSX = false;
        boolean isWindows = false;
        boolean isPlatformRunning = false;
        
        try {
            
            isLinux = Platform.getOS().equals(Platform.OS_LINUX);
            isOSX = Platform.getOS().equals(Platform.OS_MACOSX);
            isWindows = Platform.getOS().equals(Platform.OS_WIN32);
            isPlatformRunning = Platform.isRunning();
        } catch (Throwable t) {
            String os = System.getProperties().get("os.name").toString().toLowerCase();
            isLinux = os.startsWith("unix");
            isOSX = os.startsWith("osx");
            isWindows = os.startsWith("win");
            
            new PreferenceInitializer().initializeDefaultPreferences();
        }
        
        IS_LINUX = isLinux;
        IS_MACOSX = isOSX;
        IS_WINDOWS = isWindows;
        IS_PLATFORM_RUNNING = isPlatformRunning;
    }
    
    public static boolean isBundleUnavailable(String bundleName) {
        if (IS_PLATFORM_RUNNING) {
            // determine the containing bundle
            return getBundle(bundleName) == null;
        } else {
            return false;
        }
    }
    
    public static Class<?> loadClass(String bundleName, String className) throws ClassNotFoundException {
        if (IS_PLATFORM_RUNNING) {
            final Bundle bundle = getBundle(bundleName);
            if (bundle == null) {
                return Klighd.class.getClassLoader().loadClass(className);
            } else {
                return bundle.loadClass(className);
            }
        } else {
            return Klighd.class.getClassLoader().loadClass(className);
        }
    }
    
    public static boolean isResourceUnavailable(String bundleName, String path) {
        if (IS_PLATFORM_RUNNING) {
            // determine the containing bundle
            final Bundle bundle = getBundle(bundleName);
            if (bundle == null) {
                return Klighd.class.getClassLoader().getResource(path) == null;
            } else {
                return bundle.getEntry(path) == null;
            }
        } else {
            return false;
        }
    }
    
    public static InputStream getResourceAsStream(String bundleName, String path) throws IOException {
        if (IS_PLATFORM_RUNNING) {
            // determine the containing bundle
            final Bundle bundle = getBundle(bundleName);
            final URL entry = bundle == null ? null : bundle.getEntry(path);
            return entry == null ? null : entry.openStream();
            
        } else {
            return Klighd.class.getClassLoader().getResourceAsStream(path);
        }
    }
    
    private static Bundle getBundle(String name) {
        return Platform.getBundle(name);
    }
    
    public static IConfigurationElement[] getExtensions(String extensionPointName) {
        if (IS_PLATFORM_RUNNING) {
            return Platform.getExtensionRegistry().getConfigurationElementsFor(extensionPointName);
        } else {
            return KlighdStandalone.getStandaloneExtensions(extensionPointName);
        }
    }
    
    static IPreferenceStore getPreferenceStore() {
        if (IS_PLATFORM_RUNNING) {
            // TODO return something useful here 
            return null;
        } else {
        	    return new IPreferenceStore.NullPreferenceStore();
        }
    }
}
