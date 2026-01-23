<?php
// Check external domain (to exclude local /etc/hosts entries)
$domain = "google.com";

echo "--- Configuration /etc/resolv.conf ---\n";
echo file_get_contents('/etc/resolv.conf');
echo "--------------------------------------\n\n";
echo "Testing domain resolution: $domain\n";

for ($i = 1; $i <= 5; $i++) {
// Unique domain for each "cold start" test,
// but here we are testing the CACHE of a single domain.
$start = microtime(true);
$ip = gethostbyname($domain);
$end = microtime(true);
$duration = ($end - $start) * 1000; // convert to milliseconds
$formattedDuration = number_format($duration, 3);
echo "Attempt #$i: IP $ip | Time: {$formattedDuration} ms";
if ($i === 1) {
  echo " (Network request)";
} elseif ($duration < 1) {
  echo " (CACHE - very fast!)";
}
echo "\n";
// Short pause
usleep(50000);
}

