package giuliolunati.rebolserver;

import giuliolunati.rebolserver.ForegroundService;
import giuliolunati.rebolserver.NotificationIdFactory;

import android.app.Notification;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Binder;
import android.os.IBinder;
import android.preference.PreferenceManager;
import android.widget.Toast;
import java.lang.ProcessBuilder;

public class Server extends ForegroundService {
	private Process mProcess;
  private static final int NOTIFICATION_ID = NotificationIdFactory.create();
  private final IBinder mBinder;
  private Notification.Builder mBuilder;
  private PendingIntent mNotificationPendingIntent;

  public class LocalBinder extends Binder {
    public Server getService() {
      return Server.this;
    }
  }

	@Override
	public IBinder onBind(Intent intent) {
		return mBinder;
	}

  public Server() {
    super(NOTIFICATION_ID);
    mBinder = new LocalBinder();
  }

  @SuppressWarnings("deprecation")
  private Notification.Builder notificationBuilder(Context ctx) {
    return new Notification.Builder(ctx);
  }

  @Override
  protected Notification createNotification() {
    Intent notificationIntent = new Intent(this, Server.class);
    mNotificationPendingIntent = PendingIntent.getService(this, 0, notificationIntent, 0);
    mBuilder = notificationBuilder(this);
    mBuilder.setSmallIcon(R.drawable.r3_icon);
    mBuilder.setContentTitle("Rebol Server");
    mBuilder.setTicker(null);
    //mBuilder.setContentText("");
    mBuilder.setContentIntent(mNotificationPendingIntent);
    Notification mNotification = mBuilder.build();
    mNotification.flags = Notification.FLAG_NO_CLEAR | Notification.FLAG_ONGOING_EVENT;
    return mNotification;
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
