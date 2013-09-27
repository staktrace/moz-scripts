import java.io.*;
import java.util.*;
import java.util.zip.*;

public class CrashAnalyzer {
    private interface CrashFilter {
        boolean matchCrash( Map<String, String> tokens );
        boolean matchBucket( Map<String, String> tokens );
    }

    private class Fraction {
        int numerator;
        int denominator;
    }

    private final CrashFilter _filter;
    private final Map<String, Map<String, Fraction>> _data;

    public CrashAnalyzer( CrashFilter filter ) {
        _filter = filter;
        _data = new TreeMap<String, Map<String, Fraction>>();
    }

    public void loadFile( Reader in ) throws Exception {
        BufferedReader br = new BufferedReader( in );
        String[] columns = br.readLine().split( "\\t" );
        Map<String, String> dataset = new HashMap<String, String>();
        int dataLine = 0;
        for (String s = br.readLine(); s != null; s = br.readLine()) {
            dataLine++;
            String[] tokens = s.split( "\\t" );
            if (tokens.length != columns.length) {
                System.err.println( "Column length mismatch on data line number " + dataLine );
                continue;
            }
            for (int i = 0; i < columns.length; i++) {
                dataset.put( columns[i], tokens[i] );
            }
            String version = dataset.get( "version" );
            if (version.length() < 3) {
                System.err.println( "Skipping unknown version string [" + version + "] on data line number " + dataLine );
                continue;
            }
            dataset.put( "_codeline", version.substring( 0, 2 ) );

            if (! _filter.matchBucket( dataset )) {
                continue;
            }
            String build = dataset.get( "build" );
            Map<String, Fraction> versionData = _data.get( version );
            if (versionData == null) {
                versionData = new TreeMap<String, Fraction>();
                _data.put( version, versionData );
            }
            Fraction datapoint = versionData.get( build );
            if (datapoint == null) {
                datapoint = new Fraction();
                versionData.put( build, datapoint );
            }
            datapoint.denominator++;
            if (_filter.matchCrash( dataset )) {
                datapoint.numerator++;
            }
        }
    }

    public List<String> report() throws Exception {
        List<String> commands = new ArrayList<String>();
        for (String version : _data.keySet()) {
            boolean interesting = false;

            String fn = "crashes-" + version + ".dat";
            PrintWriter pw = new PrintWriter( new FileWriter( fn ) );

            Map<String, Fraction> versionData = _data.get( version );
            for (String build : versionData.keySet()) {
                Fraction point = versionData.get( build );
                pw.println( build + " " + point.numerator + " " + point.denominator );
                interesting |= (point.numerator > 0);
            }
            pw.close();

            interesting = interesting && (versionData.size() > 1);

            if (interesting) {
                commands.add( "plot \"" + fn + "\" using ($1):($2/$3) title '" + version + "' with linespoints" );
            }
        }
        return commands;
    }

    public static void main( String[] args ) throws Exception {
        CrashAnalyzer ca = new CrashAnalyzer(new CrashFilter() {
            public boolean matchCrash( Map<String, String> tokens ) {
                return tokens.get( "signature" ).toLowerCase().indexOf( "libegl_vivante" ) >= 0;
            }

            public boolean matchBucket( Map<String, String> tokens ) {
                return tokens.get( "product" ).equals( "FennecAndroid" )
                    && Integer.parseInt( tokens.get( "_codeline" ) ) >= 14;
            }
        });

        for (String arg : args) {
            System.err.println( "Processing file [" + arg + "]" );
            Reader reader;
            if (arg.endsWith( ".gz" )) {
                reader = new InputStreamReader( new GZIPInputStream( new FileInputStream( arg ) ) );
            } else {
                reader = new FileReader( arg );
            }
            ca.loadFile( reader );
            reader.close();
        }
        List<String> commands = ca.report();
        System.out.println( "Run in gnuplot:" );
        for (String command : commands) {
            System.out.println( command );
        }
    }
}
