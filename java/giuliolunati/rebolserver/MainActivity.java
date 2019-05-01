package giuliolunati.rebolserver;

import android.app.*;
import android.content.Context;
import android.content.res.AssetManager;
import android.content.SharedPreferences;
import android.os.*;
import android.preference.PreferenceManager;
import android.view.View;
import android.widget.Toast;

import java.io.File;
import java.io.InputStream;
import java.io.FileOutputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.lang.Process;
import java.lang.ProcessBuilder;

public class MainActivity extends Activity
{
	private SharedPreferences mPreferences;

	private void copyAsset(String name) {
		try {
			AssetManager as = getResources().getAssets();
			InputStream ins = as.open(name);
			byte[] buffer = new byte[ins.available()];
			ins.read(buffer);
			ins.close();
			FileOutputStream fos = this.openFileOutput(name, Context.MODE_PRIVATE);
			fos.write(buffer);
			fos.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	@Override
	protected void onCreate(Bundle savedInstanceState)
	{
		super.onCreate(savedInstanceState);
		mPreferences = PreferenceManager.getDefaultSharedPreferences(this);
		String oldAssetsVersion = mPreferences.getString("assetsVersion", "");
		Toast.makeText(this, "Old system version " + oldAssetsVersion + "!", Toast.LENGTH_SHORT).show();
		if (! newAssetsVersion.equals(oldAssetsVersion)) {
			installSystem(null);
		}
		setContentView(R.layout.main);
  }
	public String newAssetsVersion = "2019-04-30.2";
	public void installSystem(View view) {
		Toast.makeText(this, "Installing system version " + newAssetsVersion + "!", Toast.LENGTH_LONG).show();
		copyAsset("r3");
		copyAsset("install.zip");
		copyAsset("install.sh");
		File path = new File(this.getFilesDir(), "r3");
		path.setExecutable(true);
		String[] cmds = {"/system/bin/sh","install.sh"};
		ProcessBuilder pb = new ProcessBuilder(cmds);
		pb.directory(this.getFilesDir());
		try {
			Process p = pb.start();
			p.waitFor();
		}
		catch (Exception e) {
			Toast.makeText(this, e+"!", Toast.LENGTH_LONG).show();
		}
		SharedPreferences.Editor editor = mPreferences.edit();
		editor.putString("assetsVersion", newAssetsVersion);
		editor.commit();
		Toast.makeText(this, "Done.", Toast.LENGTH_SHORT).show();
	}
}