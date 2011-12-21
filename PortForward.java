import java.io.*;
import java.net.*;

public class PortForward {
    public static void main( String[] args ) throws Exception {
        if (args.length == 0) {
            System.err.println( "Usage: java PortForward <local-port> <listen-port>" );
            return;
        }
        int localPort = Integer.parseInt( args[0] );
        int listenPort = Integer.parseInt( args[1] );
        ServerSocket ss = new ServerSocket( listenPort );
        final Socket in = ss.accept();
        final Socket out = new Socket( "127.0.0.1", localPort );

        Thread in2out = new Thread() {
            public void run() {
                try {
                    InputStream i = in.getInputStream();
                    OutputStream o = out.getOutputStream();
                    int b = i.read();
                    while (b >= 0) {
                        o.write( (byte)b );
                        b = i.read();
                    }
                    o.close();
                    i.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        };
        in2out.start();

        Thread out2in = new Thread() {
            public void run() {
                try {
                    InputStream i = out.getInputStream();
                    OutputStream o = in.getOutputStream();
                    int b = i.read();
                    while (b >= 0) {
                        o.write( (byte)b );
                        b = i.read();
                    }
                    o.close();
                    i.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        };
        out2in.start();

        in2out.join();
        out2in.join();
        in.close();
        out.close();
    }
}
