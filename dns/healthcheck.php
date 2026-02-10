<?php
// Healthcheck endpoint for Kubernetes liveness and readiness probes
// This endpoint checks if dnsmasq is properly configured and running

$upstreamFile = "/etc/resolv.dnsmasq";
$systemResolv = "/etc/resolv.conf";
$errors = [];

// Check 1: Upstream DNS file exists
if (!file_exists($upstreamFile)) {
  $errors[] = "Upstream DNS file missing: $upstreamFile";
}

// Check 2: Upstream DNS file has valid content
if (file_exists($upstreamFile)) {
  $content = file_get_contents($upstreamFile);
  if (!str_contains($content, 'nameserver')) {
    $errors[] = "No nameserver in $upstreamFile";
  }
}

// Check 3: System resolv.conf points to 127.0.0.1
if (file_exists($systemResolv)) {
  $content = file_get_contents($systemResolv);
  if (!str_contains($content, '127.0.0.1')) {
    $errors[] = "System DNS not configured to use local proxy";
  }
}

// Check 4: DNS resolution works
$testDomain = "google.com";
$start = microtime(true);
$ip = @gethostbyname($testDomain);
$duration = (microtime(true) - $start) * 1000;

if ($ip === $testDomain) {
  $errors[] = "DNS resolution failed for $testDomain";
}

// Return status
header('Content-Type: application/json');
if (count($errors) > 0) {
  http_response_code(503); // Service Unavailable
  echo json_encode([
    'status' => 'unhealthy',
    'errors' => $errors,
    'timestamp' => date('Y-m-d H:i:s')
  ]);
} else {
  http_response_code(200); // OK
  echo json_encode([
    'status' => 'healthy',
    'dns_resolution_time_ms' => number_format($duration, 3),
    'test_domain' => $testDomain,
    'resolved_ip' => $ip,
    'timestamp' => date('Y-m-d H:i:s')
  ]);
}
?>
