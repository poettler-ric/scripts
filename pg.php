<?php
// Connecting, selecting database
error_reporting(E_ALL);

$dbconn = pg_connect("host=127.0.0.1 dbname=dbname user=user password=password")
    or die('Could not connect: ' . pg_last_error());

// Performing SQL query
$query = 'show server_version';
$result = pg_query($query) or die('Query failed: ' . pg_last_error());

// Printing results in HTML
echo "<table>\n";
while ($line = pg_fetch_array($result, null, PGSQL_ASSOC)) {
    echo "\t<tr>\n";
    foreach ($line as $col_value) {
        echo "\t\t<td>$col_value</td>\n";
    }
    echo "\t</tr>\n";
}
echo "</table>\n";

// Free resultset
pg_free_result($result);

// Closing connection
pg_close($dbconn);
?>
