package giuliolunati.rebolserver;

import giuliolunati.rebolserver.ForegroundService;
import giuliolunati.rebolserver.NotificationIdFactory;

import android.app.Notification;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Binder;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.preference.PreferenceManager;
import android.widget.Toast;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.lang.ProcessBuilder;
import java.lang.Thread;

public class Server extends ForegroundService {
  public Context mContext = this;
  private Process mProcess;
  private ListenRebol listener;
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
    mBuilder.setContentIntent(mNotificationPendingIntent);
    Notification mNotification = mBuilder.build();
    mNotification.flags = Notification.FLAG_NO_CLEAR | Notification.FLAG_ONGOING_EVENT;
    return mNotification;
  }
  
  private void toast(String text, int islong) {
    Toast.makeText(mContext, text, islong).show();
  }

  final int ALERT = 1071;
  
  Handler handler = new Handler() {
    @Override
    public void handleMessage(Message msg) {
      //super.handleMessage(msg);
      switch (msg.what) {
        case ALERT:
          toast((String) msg.obj, msg.arg1);
          break;
        default:
          toast("Invalid msg.what =" + msg.what, 1);
          break;
      }
    }
  };

  public class ListenRebol extends Thread {
    public BufferedReader input = null;
    public void run() {
      Message msg;
      try {
        input = new BufferedReader (
          new InputStreamReader (mProcess.getInputStream())
        );
        String line = "";
        while (line != null) {
          line = input.readLine();
          if (line.indexOf("//REQ/") == 0) {
            msg = new Message();
            msg.what = ALERT;
            msg.obj = line;
            msg.arg1 = 0;
            handler.sendMessage(msg);
          }
        }
        input.close();
      } catch (Exception e) {
        msg = new Message();
        msg.what = ALERT;
        msg.obj = e.getMessage();
        msg.arg1 = 0;
        handler.sendMessage(msg);
      }
    }
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
      listener = new ListenRebol();
      listener.start();
    } catch (Exception e) {
      toast(e.getMessage(), 1);
    }
    // Let it continue running until it is stopped.
    return START_NOT_STICKY;
  }
  @Override
  public void onDestroy() {
    listener.interrupt();
    mProcess.destroy();
    super.onDestroy();
  }
}
