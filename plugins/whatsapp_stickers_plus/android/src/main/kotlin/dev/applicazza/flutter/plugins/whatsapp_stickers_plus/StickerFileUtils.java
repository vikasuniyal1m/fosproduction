package dev.applicazza.flutter.plugins.whatsapp_stickers_plus;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

class StickerFileUtils {

    private static final String TAG = "StickerFileUtils";

    static File getPackStorageDir(@NonNull Context context, @NonNull String identifier) {
        return new File(context.getFilesDir(), "sticker_assets" + File.separator + identifier);
    }

    @NonNull
    static File resolveStickerFile(@NonNull Context context, @NonNull String fileName,
            @NonNull String identifier) {
        if (fileName.contains("_MZN_FD_")) {
            return new File(fileName.replace("_MZN_FD_", File.separator));
        }
        return new File(getPackStorageDir(context, identifier), fileName);
    }

    static String decodeSourcePath(String path) {
        if (path == null || path.isEmpty()) {
            return "";
        }
        if (path.startsWith("file://")) {
            return path.replace("file://", "");
        }
        if (path.contains("_MZN_FD_")) {
            return path.replace("_MZN_FD_", File.separator);
        }
        return path;
    }

    static void deleteRecursive(File file) {
        if (file == null || !file.exists()) {
            return;
        }
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    deleteRecursive(child);
                }
            }
        }
        if (!file.delete()) {
            Log.w(TAG, "Failed to delete: " + file.getAbsolutePath());
        }
    }

    static void copyFile(File source, File dest) throws IOException {
        if (!source.exists()) {
            throw new IOException("Source missing: " + source.getAbsolutePath());
        }
        File parent = dest.getParentFile();
        if (parent != null && !parent.exists() && !parent.mkdirs()) {
            throw new IOException("Cannot create dir: " + parent.getAbsolutePath());
        }
        try (InputStream in = new FileInputStream(source);
                OutputStream out = new FileOutputStream(dest)) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
        }
        Log.d(TAG, "Copied " + source.getName() + " -> " + dest.getAbsolutePath()
                + " (" + dest.length() + " bytes)");
    }
}
