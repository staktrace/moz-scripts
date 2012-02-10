import java.io.*;

public class logtag {
    public static void main( String[] args ) throws Exception {
        String[] old = {
            "LOGTAG",
            "LOG_FILE_NAME",
            "LOG_NAME"
        };
        for (String file : args) {
            BufferedReader br = new BufferedReader( new FileReader( file ) );
            PrintStream ps = new PrintStream( new FileOutputStream( "tmp" ) );
            boolean inserted = false;
            boolean isEmpty = false;
            boolean skipIfEmpty = false;
            for (String s = br.readLine(); s != null; s = br.readLine()) {
                boolean hasOldTag = false;
                for (String oldtag : old) {
                    if (s.indexOf( oldtag + " = " ) >= 0) {
                        hasOldTag = true;
                        break;
                    }
                }
                if (hasOldTag) {
                    if (isEmpty) {
                        skipIfEmpty = true;
                    }
                    continue;
                }

                isEmpty = (s.trim().length() == 0);
                if (isEmpty && skipIfEmpty) {
                    skipIfEmpty = false;
                    continue;
                }
                skipIfEmpty = false;

                int logIx = s.indexOf( "Log." );
                if (logIx >= 0) {
                    int startIx = s.indexOf( "(", logIx + 1 );
                    int endIx = s.indexOf( ",", logIx + 1 );
                    s = s.substring( 0, startIx + 1 ) + "LOGTAG" + s.substring( endIx );
                }
                ps.println( s );

                if (!inserted && (s.indexOf( "{" ) >= 0)) {
                    String tag = (file.startsWith( "Gecko" ) ? file : "Gecko" + file);
                    tag = tag.substring( 0, tag.indexOf( "." ) );
                    ps.println( "    private static final String LOGTAG = \"" + tag + "\";" );
                    ps.println();
                    inserted = true;
                    skipIfEmpty = true;
                }
            }
            new File( "tmp" ).renameTo( new File( file ) );
        }
    }
}

