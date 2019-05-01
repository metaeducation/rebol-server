package giuliolunati.rebolserver;

import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.IBinder;
import android.preference.PreferenceManager;
import android.widget.Toast;
import java.lang.ProcessBuilder;

public class Server extends Service {
	private Process mProcess;
	@Override
	public IBinder onBind(Intent intent) {
		return null;
	}
	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		SharedPreferences mPreferences = PreferenceManager.getDefaultSharedPreferences(getBaseContext());
		String mPort = mPreferences.getString("port", "8888");
		String basepath = this.getFilesDir().getAbsolutePath();
		String[] cmds = {
			basepath + "/system/r3"
			, basepath + "/system/webserver.reb"
			, mPort
			, basepath
			, "-a"
			, "index"
		};
		ProcessBuilder pb = new ProcessBuilder(cmds);
		pb.directory(this.getFilesDir());
		try {
			mProcess = pb.start();
			//mProcess.waitFor();
		}
		catch (Exception e) {
			Toast.makeText(this, e+"!", Toast.LENGTH_LONG).show();
		}
		// Let it continue running until it is stopped.
		return START_NOT_STICKY;
	}
	@Override
	public void onDestroy() {
		super.onDestroy();
		mProcess.destroy();
	}
}
