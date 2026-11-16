package com.sqa.app;

import io.flutter.embedding.android.FlutterActivity;
import android.content.pm.ApplicationInfo;
import android.os.Bundle;
import android.view.WindowManager;

public class MainActivity extends FlutterActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        if ((getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) == 0) {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE);
        }
        super.onCreate(savedInstanceState);
    }
}
