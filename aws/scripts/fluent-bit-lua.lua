-- ====================================================================
--      Helper Functions: Enriches Log Records
-- ====================================================================

function get_pod_ip(tag, timestamp, record)
  -- Convert timestamp to ISO format for readability
  record.timestamp_iso = os.date("!%Y-%m-%dT%H:%M:%SZ", timestamp)

  -- If it's not an ipamd log, return immediately (only iso timestamp added)
  if not string.find(tag, "ipamd.log") then
    return 1, timestamp, record -- Return 1, as the record is modified
  end

  -- Extract pod name and IP from the AWS CNI log message
  local pod_name, pod_ip = string.match(record.log, "Annotates pod (%S+) with vpc.amazonaws.com/pod%-ips: (.-)\"")

  if pod_name and pod_ip ~= nil then
    record.event_type = "ip_assignment"
    record.pod_name = pod_name
    if pod_ip == "" then
      record.assigned_ip = "IpDel"
    else
      record.assigned_ip = pod_ip
    end
    -- Remove the raw log message to save space
    record.log = nil
  end
  return 1, timestamp, record
end

function create_field(tag, timestamp, record)
  local event_type = "unknown"
  if record["type"] and (record["type"] == "Normal" or record["type"] == "Warning" or record["type"] == "Error") then
    event_type = string.lower(record["type"])
  end

  local ns = "unclassified"
  local name = "unclassified"

  if type(record["involvedObject"]) == "table" then
    ns = record["involvedObject"]["namespace"] or ns
    name = record["involvedObject"]["name"] or name
  end

  record["new_built_tag"] = "application.event." .. event_type .. "." .. name .. "_" .. ns
  return 1, timestamp, record
end

function create_field_o(tag, timestamp, record)
  local new_tag_value
  -- Filter only Warnings or Errors for specific processing
  if record["type"] and (record["type"] == "Warning" or record["type"] == "Error") then
    local event_type = string.lower(record["type"])
    local ns = (record["involvedObject"] and record["involvedObject"]["namespace"]) or "unclassified"
    local name = (record["involvedObject"] and record["involvedObject"]["name"]) or "unclassified"
    new_tag_value = "application.event." .. event_type .. "." .. name .. "_" .. ns
  else
    -- Mark everything else to be dropped
    new_tag_value = "events-to-drop"
  end
  record["new_tag"] = new_tag_value
  return 1, timestamp, record
end

function filter_stdout1(tag, timestamp, record)
  if record["stream1"] and record["stream1"] == "stdout" then
    record["retag_to_drop"] = "true"
  end
  return 1, timestamp, record
end

-- ====================================================================
--      CONFIGURATION: Denylist & Allowlist
-- ====================================================================

-- 1. DENYLIST: Containers to completely ignore (both stdout and stderr).
--    Structure: ["namespace"] = { ["container_name"] = true }
local denylist = {
  ["thoth-production"] = {
    ["thoth-downpage-production"] = true,
		["thoth-drive-production"] = true,
    ["thoth-monolith-au-async"] = true,
    ["thoth-monolith-au-debug"] = true,
    ["thoth-monolith-au-static"] = true,
    ["thoth-monolith-au-task"] = true,
    ["thoth-monolith-au-web"] = true,
  },
	["backup"] = {
    ["thoth-drive-backup"] = true,
  }
}

-- 2. ALLOWLIST: Namespaces/Containers to keep based on patterns.
--    If set to true, keeps all logs. If table, keeps matching regex.
local allowlist = {
  ["ingress-nginx"] = {
    ["controller"] = {
      "STATUS=5%d%d" -- Keep 5xx errors
    }
  },
  ["internal-nginx"] = {
    ["controller"] = {
      "STATUS=5%d%d" -- Keep 5xx errors
    }
  }
}

-- ====================================================================
--      Main Filter Function
-- ====================================================================

function filter_stdout(tag, timestamp, record)

  local kube_meta = record.kubernetes

  -- STEP 1: Check the Denylist first.
  -- If the container is in the denylist, drop it regardless of stream type (stdout/stderr).
  if kube_meta and kube_meta.namespace_name and kube_meta.container_name then
    local namespace = kube_meta.namespace_name
    local container = kube_meta.container_name

    if denylist[namespace] and denylist[namespace][container] then
      record["retag_to_drop"] = "true"
      return 1, timestamp, record
    end
  end

  -- STEP 2: Filter by Stream.
  -- If it is NOT stdout (e.g., stderr), we keep it (unless it was denylisted above).
  -- This ensures critical application errors are preserved.
  if not record["stream"] or record["stream"] ~= "stdout" then
    return 1, timestamp, record
  end

  -- STEP 3: Check the Allowlist.
  -- Logic only applies to STDOUT logs here.
  if kube_meta and kube_meta.namespace_name and kube_meta.container_name then
    local namespace = kube_meta.namespace_name
    local container = kube_meta.container_name

    if allowlist[namespace] and allowlist[namespace][container] then
      local rule = allowlist[namespace][container]

      -- Rule is boolean true: Keep everything
      if type(rule) == "boolean" and rule == true then
        return 1, timestamp, record

      -- Rule is a table: Check patterns/regex
      elseif type(rule) == "table" then
        if record["log"] and type(record["log"]) == "string" then
          for _, pattern_to_find in ipairs(rule) do
            if string.find(record["log"], pattern_to_find) then
              return 1, timestamp, record -- Pattern matched, keep log
            end
          end
        end
      end
    end
  end

  -- STEP 4: FINAL DECISION
  -- If the log is stdout, was not denylisted, but also not explicitly allowlisted,
  -- we treat it as "noise" and drop it.
  record["retag_to_drop"] = "true"
  return 1, timestamp, record
end
